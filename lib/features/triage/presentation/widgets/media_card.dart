import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/thumbnail_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/video_preview.dart';

/// 6.2.8 — "carregado na resolução da tela, nunca em resolução
/// original" (8.6). Com o card ocupando quase a tela inteira, um valor
/// fixo baixo (720) ficava borrado esticado em telas de maior
/// densidade — acompanha a altura física real do aparelho, com teto
/// que ainda evita decodificar perto da resolução original (uma foto
/// de 12MP chega a ~48MB, 8.6).
int _cardThumbnailSize(BuildContext context) {
  final view = MediaQuery.of(context);
  final physicalHeight = view.size.height * view.devicePixelRatio;
  return physicalHeight.round().clamp(720, 1600);
}

class MediaCard extends ConsumerWidget {
  final MediaItemEntity item;

  /// 6.2.17 — controla a reprodução real do vídeo (`VideoPreview`) e o
  /// ícone central quando pausado.
  final bool isPlaying;

  /// Vídeo chegou ao fim sozinho — repassado direto do `VideoPreview`
  /// pra quem possui o estado de `isPlaying` (a Tela de Triagem).
  final VoidCallback? onPlaybackEnded;

  const MediaCard({
    required this.item,
    this.isPlaying = false,
    this.onPlaybackEnded,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = ref.watch(
      thumbnailProvider((item.mediaStoreId, _cardThumbnailSize(context))),
    );

    // Preenche todo o espaço disponível (o pai já é quem limita isso —
    // sem largura/altura fixa aqui, ao contrário do card quadrado
    // anterior). `BoxFit.contain` em vez de `cover`: a triagem depende
    // de ver a foto inteira, não uma versão cortada dela — sobra
    // transparência nas proporções que não batem com a tela, em vez de
    // perder conteúdo nas bordas. Sem borda nem fundo colorido: a foto
    // ocupa o espaço a descoberto, sem moldura.
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pôster: sempre desenhado, vídeo incluso — cobre o tempo
            // de carregamento do `VideoPreview` (resolver o arquivo +
            // inicializar o controller) e continua servindo de
            // fallback se a decodificação falhar (§7).
            thumbnail.when(
              data: (bytes) => bytes == null
                  ? const SizedBox.shrink()
                  : Image.memory(bytes, fit: BoxFit.contain),
              loading: () => const SizedBox.shrink(),
              // §7 — falha de leitura de miniatura: fica só o fundo
              // transparente, o item continua triável normalmente.
              error: (Object error, StackTrace stackTrace) =>
                  const SizedBox.shrink(),
            ),
            if (item.isVideo) ...[
              VideoPreview(
                item: item,
                isPlaying: isPlaying,
                onPlaybackEnded: onPlaybackEnded,
              ),
              // Afordância de "toque pra reproduzir" — só enquanto
              // pausado; escondida durante a reprodução pra não tapar
              // o vídeo com um ícone gigante o tempo todo.
              if (!isPlaying)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
