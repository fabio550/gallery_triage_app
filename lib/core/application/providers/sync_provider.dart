import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/albums_provider.dart';
import 'package:gallery_triage_app/core/application/providers/categories_provider.dart';
import 'package:gallery_triage_app/core/application/providers/preferences_repository_provider.dart';
import 'package:gallery_triage_app/core/application/providers/sync_service_provider.dart';
import 'package:gallery_triage_app/core/application/providers/triage_repository_provider.dart';
import 'package:gallery_triage_app/core/application/services/sync_status.dart';
import 'package:gallery_triage_app/features/triage/application/triage_session_notifier.dart';

final syncProvider = NotifierProvider<SyncNotifier, SyncStatus>(
  SyncNotifier.new,
);

/// Decide, ao ser observado pela primeira vez — ou seja, quando o
/// `PermissionGate` já confirmou a permissão (4.2) —, entre primeiro
/// scan (5.2, bloqueante) e sincronização incremental (5.3, não
/// bloqueante), e expõe o progresso pra `SyncGate` escolher a tela.
class SyncNotifier extends Notifier<SyncStatus> {
  late final _service = ref.read(syncServiceProvider);
  late final _prefs = ref.read(preferencesRepositoryProvider);
  late final _triage = ref.read(triageRepositoryProvider);

  @override
  SyncStatus build() {
    _start();
    return const SyncStatus(phase: SyncPhase.checking);
  }

  Future<void> _start() async {
    // 5.4 — limpeza de inicialização: restaura qualquer item que
    // ficou na fila de exclusão de uma sessão anterior (3.5.4, o app
    // pode ter sido encerrado sem passar pelo diálogo de saída).
    // Roda antes de qualquer coisa, "antes do dashboard abrir" (5.4.2).
    await _triage.restorePendingQueueItems();
    if (!ref.mounted) return;

    // 5.3.6/2.6 — nunca sincronizou ainda é o sinal de "primeiro scan
    // necessário", não "tabela vazia": um dispositivo com galeria
    // vazia mas já sincronizado não deve reabrir a tela de progresso
    // a cada abertura do app.
    final lastSync = await _prefs.lastSyncAt();
    if (!ref.mounted) return;

    if (lastSync == null) {
      await _runFirstScan();
    } else {
      state = const SyncStatus(phase: SyncPhase.ready);
      // 5.3.5 — "o dashboard abre com os dados já persistidos e é
      // atualizado ao término". Não aguardado de propósito.
      unawaited(_runIncrementalSync());
    }
  }

  Future<void> _runFirstScan() async {
    state = const SyncStatus(phase: SyncPhase.firstScanning);
    try {
      await _service.runFirstScan(
        onProgress: (count) {
          if (!ref.mounted) return;
          state = SyncStatus(phase: SyncPhase.firstScanning, processed: count);
        },
      );
      if (ref.mounted) state = const SyncStatus(phase: SyncPhase.ready);
    } catch (error) {
      if (ref.mounted) {
        state = SyncStatus(phase: SyncPhase.failed, error: error);
      }
    }
  }

  Future<void> _runIncrementalSync() async {
    // Sinaliza pra UI que a sincronização está rodando por trás — ela
    // pode demorar bem mais agora que espelha álbuns do sistema
    // inteiro (`SyncService._mirrorSystemAlbums`), não só verificar
    // itens novos; sem isso, uma categoria vazia esperando esse
    // espelhamento terminar parecia travada, sem nenhum sinal de que
    // ainda estava carregando.
    if (ref.mounted) state = state.copyWith(isSyncing: true);
    try {
      final newCount = await _service.runIncrementalSync();
      if (!ref.mounted) return;
      if (newCount == 0) return;

      // Mídia nova entrou no índice, e/ou álbuns do sistema foram
      // espelhados/ganharam item novo (`SyncService._mirrorSystemAlbums`)
      // — contagens do Dashboard, a lista de álbuns e sessões de
      // triagem já abertas (que sobrevivem entre visitas, 6.2.4) ficaram
      // desatualizadas. Invalida tudo pra recarregar do Drift. O
      // recarregamento em si é quem decide pular o cursor pra mídia
      // mais nova (`TriageSessionNotifier._resolveInitialIndex`).
      ref.invalidate(categoriesProvider);
      ref.invalidate(albumItemCountsProvider);
      ref.invalidate(triageSessionProvider);
      ref.invalidate(albumsProvider);
    } catch (_) {
      // 5.3.5 — não bloqueante; uma falha aqui não pode tirar o
      // usuário do que já está indexado. Sem tela de erro dedicada
      // pra isso ainda (P-XX a definir se vira recorrente).
    } finally {
      if (ref.mounted) state = state.copyWith(isSyncing: false);
    }
  }

  /// Tenta de novo depois de [SyncPhase.failed] — botão explícito na
  /// tela de erro, não repetição automática.
  Future<void> retryFirstScan() => _runFirstScan();

  /// 5.3.1 — "toda abertura do app e retomada do primeiro plano" é
  /// gatilho de sincronização. Chamado pelo observer de lifecycle em
  /// `main.dart`; no-op se o primeiro scan ainda não terminou (nesse
  /// caso [_start] já está cuidando disso) ou já falhou (o usuário
  /// decide via [retryFirstScan], não uma retomada silenciosa).
  void resyncOnResume() {
    if (state.phase != SyncPhase.ready) return;
    unawaited(_runIncrementalSync());
  }
}
