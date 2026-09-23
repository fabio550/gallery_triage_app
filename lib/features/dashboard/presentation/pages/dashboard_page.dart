import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/categories_provider.dart';
import 'package:gallery_triage_app/core/application/providers/sync_provider.dart';
import 'package:gallery_triage_app/core/domain/enums/category_granularity.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/category_list.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/granularity_selector.dart';
import 'package:gallery_triage_app/features/dashboard/presentation/widgets/info_stats_card.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  CategoryGranularity _granularity = CategoryGranularity.all;

  @override
  Widget build(BuildContext context) {
    // O card geral é a categoria "Todos os itens" — mesma fonte que
    // categoriesProvider(álbum/mês/ano/tipo), nunca um número à parte.
    final overallAsync =
        ref.watch(categoriesProvider(CategoryGranularity.all));
    final categoriesAsync = ref.watch(categoriesProvider(_granularity));
    // A sincronização em segundo plano pode demorar bem mais agora que
    // também espelha os álbuns do sistema inteiro -- sem isso, uma
    // categoria (ex.: "Álbuns" logo depois de instalar a atualização)
    // aparecia vazia em silêncio até a sincronização terminar e só
    // então preencher, sem nenhum sinal de que ainda estava carregando.
    final isSyncing = ref.watch(syncProvider).isSyncing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Triagem'),
        actions: [
          // 6.5.2/P-08 — ponto de entrada da tela de gestão de álbuns.
          IconButton(
            tooltip: 'Álbuns',
            icon: const Icon(Icons.photo_album_outlined),
            onPressed: () => context.push('/albums'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                // Riverpod 3.x: `.value` já é nullable (equivalente ao
                // antigo `valueOrNull`) — durante o primeiro carregamento
                // ou numa falha, o card mostra zeros em vez de travar.
                final overallList = overallAsync.value;
                final overall =
                    (overallList != null && overallList.isNotEmpty)
                        ? overallList.first
                        : null;
                return InfoStatsCard(
                  totalItems: overall?.totalItems ?? 0,
                  totalSizeGb:
                      (overall?.sizeBytes ?? 0) / (1024 * 1024 * 1024),
                  classifiedItems: overall?.classifiedItems ?? 0,
                  keptItems: overall?.keptItems ?? 0,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GranularitySelector(
              selected: _granularity,
              onChanged: (value) => setState(() => _granularity = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // `skipLoadingOnRefresh: false` -- por padrão o Riverpod
              // esconde o estado de carregamento numa recarga disparada
              // por `ref.invalidate` (ex.: depois que a sincronização em
              // segundo plano espelha os álbuns do sistema) e continua
              // mostrando os dados antigos até os novos chegarem. Sem
              // isso, a lista ficava parada (ou vazia) em silêncio
              // enquanto a sincronização ainda rodava, dando a impressão
              // de que nada tinha acontecido.
              child: categoriesAsync.when(
                skipLoadingOnRefresh: false,
                data: (categories) => categories.isEmpty && isSyncing
                    // Vazio "de verdade" (sem sincronização em curso) é
                    // um estado legítimo (6.1.11) e continua sem
                    // spinner -- só mostra enquanto ainda pode vir dado
                    // novo, senão o círculo giraria pra sempre numa
                    // categoria que é vazia mesmo.
                    ? const Center(child: CircularProgressIndicator())
                    : CategoryList(
                        categories: categories,
                        granularity: _granularity,
                        onCategoryTap: (summary) =>
                            context.push('/triage-page', extra: summary),
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stackTrace) => Center(
                  child: Text(
                    'Não foi possível carregar as categorias.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
