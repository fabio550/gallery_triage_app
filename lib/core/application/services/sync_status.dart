/// Estado do `SyncService` exposto à UI — cobre tanto o primeiro scan
/// (5.2, bloqueante — §7 "dashboard indisponível") quanto a
/// sincronização incremental (5.3, não bloqueante).
enum SyncPhase {
  /// Decidindo, ao abrir o app, se é a primeira vez (5.2) ou se já há
  /// índice e cabe só sincronizar em segundo plano (5.3.5).
  checking,

  /// Primeiro scan em andamento — §7: "Tela de progresso com
  /// contagem; dashboard indisponível."
  firstScanning,

  /// Índice pronto pra uso — seja porque o primeiro scan terminou,
  /// seja porque já havia dados de uma sessão anterior (a
  /// sincronização incremental, se estiver rodando, roda por trás sem
  /// bloquear esta fase).
  ready,

  /// Primeiro scan falhou. Sincronização incremental nunca chega
  /// aqui — falha dela é silenciosa (5.3.5), o índice já existente
  /// continua utilizável.
  failed,
}

class SyncStatus {
  const SyncStatus({
    required this.phase,
    this.processed = 0,
    this.error,
    this.isSyncing = false,
  });

  final SyncPhase phase;

  /// Itens novos já persistidos nesta rodada — só tem sentido durante
  /// [SyncPhase.firstScanning] (5.2.1 — "progresso com contagem de
  /// itens indexados").
  final int processed;

  final Object? error;

  /// A sincronização incremental (5.3.5) está rodando por trás agora —
  /// independente de [phase] continuar `ready` durante ela. Só existe
  /// pra UI que precisa saber "ainda não chegou dado nenhum, mas já
  /// está buscando" (ex.: categoria vazia esperando o espelhamento de
  /// álbuns terminar) — não bloqueia nada, ao contrário de
  /// [SyncPhase.firstScanning].
  final bool isSyncing;

  SyncStatus copyWith({SyncPhase? phase, int? processed, bool? isSyncing}) =>
      SyncStatus(
        phase: phase ?? this.phase,
        processed: processed ?? this.processed,
        error: error,
        isSyncing: isSyncing ?? this.isSyncing,
      );
}
