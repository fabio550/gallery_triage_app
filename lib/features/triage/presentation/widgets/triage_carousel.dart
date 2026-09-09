import 'package:flutter/material.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';

import 'carousel_thumb.dart';

/// StatefulWidget só para o `ScrollController` — o cursor em si continua
/// vivendo no notifier (2.1.2), este widget apenas reage a ele.
class TriageCarousel extends StatefulWidget {
  final List<MediaItemEntity> items;
  final int currentIndex;
  final ValueChanged<int> onThumbTap;

  const TriageCarousel({
    required this.items,
    required this.currentIndex,
    required this.onThumbTap,
    super.key,
  });

  @override
  State<TriageCarousel> createState() => _TriageCarouselState();
}

class _TriageCarouselState extends State<TriageCarousel> {
  final _scrollController = ScrollController();

  // Precisa espelhar exatamente o footprint de CarouselThumb: largura
  // 90 + margem horizontal 4 de cada lado.
  static const _thumbFootprint = 98.0;
  static const _listPadding = 16.0;

  @override
  void initState() {
    super.initState();
    // Sem isso, abrir a categoria numa posição inicial != 0 (6.2.4,
    // ex.: primeiro item não decidido) mostra o carrossel do começo da
    // lista em vez de centralizado no item ativo.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _centerActive(animate: false));
  }

  @override
  void didUpdateWidget(covariant TriageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _centerActive(animate: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Foto ativa destacada no centro (6.2.5).
  void _centerActive({required bool animate}) {
    if (!_scrollController.hasClients || widget.items.isEmpty) return;

    final viewport = _scrollController.position.viewportDimension;
    final centerOfActive = _listPadding +
        widget.currentIndex * _thumbFootprint +
        _thumbFootprint / 2;
    final target = (centerOfActive - viewport / 2).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        padding: const EdgeInsets.symmetric(horizontal: _listPadding),
        itemBuilder: (context, index) {
          return CarouselThumb(
            item: widget.items[index],
            isActive: index == widget.currentIndex,
            onTap: () => widget.onThumbTap(index),
          );
        },
      ),
    );
  }
}
