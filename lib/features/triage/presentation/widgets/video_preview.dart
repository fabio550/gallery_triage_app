import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_triage_app/core/application/providers/video_file_provider.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:video_player/video_player.dart';

/// Reprodução real de vídeo na Tela de Triagem (6.2.17) — antes o
/// botão de play/pause só trocava o ícone, sem decodificar nada.
/// `isPlaying` continua controlado de fora (mesmo bool que a barra de
/// ação e o card já usam pro ícone): uma única fonte de verdade, este
/// widget só espelha esse estado no controller de vídeo de verdade.
class VideoPreview extends ConsumerStatefulWidget {
  const VideoPreview({
    required this.item,
    required this.isPlaying,
    this.onPlaybackEnded,
    super.key,
  });

  final MediaItemEntity item;
  final bool isPlaying;

  /// Vídeo chegou ao fim sozinho — quem chama decide se isso deve
  /// voltar o ícone de play/pause pra "pausado" (sem loop definido em
  /// 6.2.17).
  final VoidCallback? onPlaybackEnded;

  @override
  ConsumerState<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends ConsumerState<VideoPreview> {
  VideoPlayerController? _controller;
  String? _loadedPath;
  bool _endedNotified = false;

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPlayback();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerValue);
    _controller?.dispose();
    super.dispose();
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (widget.isPlaying && !controller.value.isPlaying) {
      controller.play();
    } else if (!widget.isPlaying && controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _onControllerValue() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration &&
        !_endedNotified) {
      _endedNotified = true;
      widget.onPlaybackEnded?.call();
    }
    if (mounted) setState(() {});
  }

  Future<void> _initialize(String path) async {
    final controller = VideoPlayerController.file(File(path));
    _controller = controller;
    _endedNotified = false;
    controller.addListener(_onControllerValue);
    try {
      await controller.initialize();
    } catch (_) {
      // §7 — falha de decodificação não sobe pra UI; sem controller
      // pronto, o build cai no pôster estático (miniatura) do
      // MediaCard, que continua embaixo enquanto isto retorna vazio.
      return;
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() {});
    _syncPlayback();
  }

  @override
  Widget build(BuildContext context) {
    final pathAsync =
        ref.watch(videoFilePathProvider(widget.item.mediaStoreId));

    return pathAsync.when(
      data: (path) {
        if (path == null) return const SizedBox.shrink();
        if (_loadedPath != path) {
          _loadedPath = path;
          unawaited(_initialize(path));
        }

        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          return const SizedBox.shrink();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            // Barra de progresso discreta, colada no topo do vídeo —
            // só a posição atual, sem timestamps nem controles extras.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _ProgressBar(controller: controller),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration;
    final progress = duration == Duration.zero
        ? 0.0
        : (value.position.inMilliseconds / duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return Container(
      height: 3,
      color: Colors.white.withValues(alpha: 0.25),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress,
        child: Container(color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}
