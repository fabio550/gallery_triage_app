import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/thumbnail_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';

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

  /// 6.2.17 — só troca o ícone de play/pause; é o card do próximo item
  /// (`behind`) que nunca deve receber `true`, já que ele não é o item
  /// ativo.
  final bool isPlaying;

  const MediaCard({
    required this.item,
    this.isPlaying = false,
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
            if (item.isVideo)
              Center(
                child: Icon(
                  isPlaying
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
