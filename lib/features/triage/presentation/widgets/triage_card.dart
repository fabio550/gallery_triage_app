
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:gallery_triage_app/core/domain/entities/media_item_entity.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/media_card.dart';
import 'package:gallery_triage_app/features/triage/presentation/widgets/swipe_overlay.dart';

enum _DragAxis { none, horizontal, vertical }

class TriageCard extends StatefulWidget {
  final MediaItemEntity item;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  /// Swipe para cima (6.2.9): classifica em `lastUsedAlbumId`. Inerte
  /// enquanto [lastUsedAlbumLabel] for nulo — o card volta à origem sem
  /// chamar isto.
  final VoidCallback onSwipeUp;

  /// Swipe para baixo (6.2.9): abre o painel de álbuns. Sem limiar de
  /// confirmação (6.2.18) — qualquer soltura no eixo vertical-baixo
  /// chama isto.
  final VoidCallback onSwipeDown;

  /// Nome do álbum armado em `lastUsedAlbumId`, para o feedback do
  /// swipe para cima. Nulo = pílula não renderizada e gesto inerte.
  final String? lastUsedAlbumLabel;

  /// Card de baixo da pilha. Opcional: sem ele o efeito continua, só
  /// perde a sensação de profundidade.
  final Widget? behind;

  const TriageCard({
    required this.item,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.lastUsedAlbumLabel,
    this.behind,
    super.key,
  });

  @override
  State<TriageCard> createState() => _TriageCardState();
}

class _TriageCardState extends State<TriageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Offset _dragEndPosition = Offset.zero;
  Offset _position = Offset.zero;

  /// Acumulado desde o `onPanStart`, sem amortecimento — só serve para
  /// decidir o eixo contra `kTouchSlop` (6.2.18). Depois que o eixo
  /// trava, quem move o card é `_position`.
  Offset _rawAccumulated = Offset.zero;
  _DragAxis _axis = _DragAxis.none;

  final double _maxRotationDegrees = 15;

  /// Deslocamento em que a rotação satura. Só se aplica ao eixo
  /// horizontal — rotação em drag vertical não faz sentido físico.
  double get _rotationSpan => MediaQuery.sizeOf(context).width * 0.5;

  double get _verticalSpan => MediaQuery.sizeOf(context).height * 0.5;

  static const double _horizontalCommitFraction = 0.30; // 30% da largura
  static const double _verticalCommitFraction = 0.25; // 25% da altura
  static const double _commitVelocity = 700.0; // px/s, os dois eixos

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    // Sem setState: o AnimatedBuilder do build já escuta o controller e
    // reconstrói só o Transform.
    _controller.addListener(() {
      _position = Offset.lerp(_dragEndPosition, Offset.zero, _controller.value)!;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSpringAnimation(Velocity velocity) {
    _dragEndPosition = _position;

    const spring = SpringDescription(mass: 1, stiffness: 80, damping: 10);

    // `distance` é sempre positivo e perdia o sentido do lançamento: um
    // flick para fora dava o mesmo overshoot de um flick para dentro.
    // Projeta a velocidade no eixo do retorno (do ponto solto até o
    // centro) e normaliza pela distância a percorrer.
    final travel = _dragEndPosition.distance;
    final unit = travel == 0
        ? Offset.zero
        : Offset(-_dragEndPosition.dx / travel, -_dragEndPosition.dy / travel);
    final projected = velocity.pixelsPerSecond.dx * unit.dx +
        velocity.pixelsPerSecond.dy * unit.dy;

    _controller.animateWith(
      SpringSimulation(spring, 0, 1, travel == 0 ? 0 : projected / travel),
    );
  }

  void _exit(VoidCallback callback) {
    _runSpringAnimation(Velocity.zero);
    callback();
  }

  /// -1 (esquerda) .. 1 (direita). Zero fora do eixo horizontal.
  double get _horizontalProgress => _axis == _DragAxis.horizontal
      ? (_position.dx / _rotationSpan).clamp(-1.0, 1.0)
      : 0.0;

  /// -1 (cima) .. 1 (baixo). Zero fora do eixo vertical.
  double get _verticalProgress => _axis == _DragAxis.vertical
      ? (_position.dy / _verticalSpan).clamp(-1.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Center(
      child: GestureDetector(
        onPanStart: (_) {
          _controller.stop();
          _axis = _DragAxis.none;
          _rawAccumulated = Offset.zero;
        },
        onPanUpdate: (details) {
          // Eixo ainda não decidido: só acumula, não move o card. Área
          // de reconhecimento (carrossel, AppBar etc.) fica de fora
          // porque o GestureDetector cobre só o card (6.2.18).
          if (_axis == _DragAxis.none) {
            _rawAccumulated += details.delta;
            if (_rawAccumulated.distance <= kTouchSlop) return;

            _axis = _rawAccumulated.dx.abs() >= _rawAccumulated.dy.abs()
                ? _DragAxis.horizontal
                : _DragAxis.vertical;
            // Decidido, trava até o pointerUp — não há caminho de volta
            // para _DragAxis.none dentro do mesmo gesto.
          }

          setState(() {
            _position += _axis == _DragAxis.horizontal
                ? Offset(details.delta.dx, 0)
                : Offset(0, details.delta.dy);
          });
        },
        onPanEnd: (details) {
          final size = MediaQuery.sizeOf(context);
          final velocity = details.velocity.pixelsPerSecond;

          if (_axis == _DragAxis.horizontal) {
            final passedDistance =
                _position.dx.abs() > size.width * _horizontalCommitFraction;
            final passedVelocity = velocity.dx.abs() > _commitVelocity;

            if (passedDistance || passedVelocity) {
              // A velocidade tem prioridade: num flick rápido o dedo sai
              // antes de percorrer a distância, e o sinal dela é a
              // intenção real.
              final toRight = passedVelocity ? velocity.dx > 0 : _position.dx > 0;
              _exit(toRight ? widget.onSwipeRight : widget.onSwipeLeft);
              return;
            }
          } else if (_axis == _DragAxis.vertical) {
            final movingUp = _position.dy < 0;

            if (movingUp) {
              // Inerte sem álbum armado (6.2.18) — cai no spring-back
              // abaixo em vez de tentar confirmar.
              if (widget.lastUsedAlbumLabel != null) {
                final passedDistance = _position.dy.abs() >
                    size.height * _verticalCommitFraction;
                final passedVelocity =
                    velocity.dy < 0 && velocity.dy.abs() > _commitVelocity;

                if (passedDistance || passedVelocity) {
                  _exit(widget.onSwipeUp);
                  return;
                }
              }
            } else {
              // Baixo: sem limiar de confirmação (6.2.18) — o gesto não
              // altera decisão nem classificação, então qualquer soltura
              // no eixo abre o painel.
              _exit(widget.onSwipeDown);
              return;
            }
          }

          _runSpringAnimation(details.velocity);
        },
        child: AnimatedBuilder(
          animation: _controller,
          // Fora do builder: a árvore da mídia não reconstrói a cada
          // frame de mola nem de arrasto, só o Transform.
          child: MediaCard(item: widget.item),
          builder: (context, child) {
            final horizontalProgress = _horizontalProgress;
            final verticalProgress = _verticalProgress;
            final combinedProgress = _axis == _DragAxis.horizontal
                ? horizontalProgress.abs()
                : verticalProgress.abs();

            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.behind != null)
                  Transform.scale(
                    // Cresce conforme o card de cima se afasta: é o que
                    // vende a sensação de pilha.
                    scale: 0.92 + 0.08 * combinedProgress,
                    child: Opacity(opacity: 0.6, child: widget.behind),
                  ),
                Transform(
                  // Matrix4 único, translate antes de rotateZ. Aninhar
                  // Transform.rotate por fora de Transform.translate
                  // girava o eixo do arrasto: quanto maior o ângulo, mais
                  // o movimento horizontal virava diagonal.
                  transform: Matrix4.identity()
                    ..translateByDouble(_position.dx, _position.dy, 0, 1)
                    ..rotateZ(
                      // Só o eixo horizontal gira — rotação num drag
                      // vertical não tem correspondência física aqui.
                      horizontalProgress * _maxRotationDegrees * math.pi / 180,
                    ),
                  // Pivô bem abaixo da tela. Girar na base do próprio
                  // card produz tombo; o eixo distante produz pêndulo.
                  origin: Offset(0, height * 0.6),
                  alignment: Alignment.center,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      child!,
                      SwipeOverlay(
                        horizontalProgress: horizontalProgress,
                        verticalProgress: verticalProgress,
                        lastUsedAlbumLabel: widget.lastUsedAlbumLabel,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}