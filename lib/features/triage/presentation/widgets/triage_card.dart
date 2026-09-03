class TriageCard extends StatefulWidget {
  final Color color;

  /// Card de baixo da pilha. Opcional: sem ele o efeito continua, só
  /// perde a sensação de profundidade.
  final Widget? behind;

  const TriageCard({
    required this.color,
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

  final double _maxRotationDegrees = 15;

  /// Deslocamento em que a rotação satura. Não limita a translação: o
  /// card segue o dedo sem parede, só o ângulo é normalizado.
  double get _rotationSpan => MediaQuery.sizeOf(context).width * 0.5;

  /// Fração do delta vertical que o card acompanha. Y com o mesmo peso
  /// do X deixa o card escorregadio e tira a tendência horizontal, que é
  /// onde estão as duas decisões.
  static const double _verticalDamping = 0.25;
  
  static const double _commitFraction = 0.30;   // 30% da largura
  static const double _commitVelocity = 700.0;  // px/s 
  
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
  
  Future<void> _exit(bool toRight) async {
    _runSpringAnimation(Velocity.zero);
  }
  
  double get _progress =>
      (_position.dx / _rotationSpan).clamp(-1.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Center(
      child: GestureDetector(
        onPanStart: (_) => _controller.stop(),
        onPanUpdate: (details) {
          setState(() {
            _position += Offset(
              details.delta.dx,
              details.delta.dy * _verticalDamping,
            );
          });
        },
        onPanEnd: (details) {
          final width = MediaQuery.sizeOf(context).width;
          final vx = details.velocity.pixelsPerSecond.dx;

          final passedDistance = _position.dx.abs() > width * _commitFraction;
          final passedVelocity = vx.abs() > _commitVelocity;

          if (passedDistance || passedVelocity) {
            // A velocidade tem prioridade: num flick rápido o dedo sai antes de
            // percorrer a distância, e o sinal dela é a intenção real.
            final toRight = passedVelocity ? vx > 0 : _position.dx > 0;
            debugPrint(toRight ? 'MANTER' : 'EXCLUIR');
            _exit(toRight);
          } else {
            _runSpringAnimation(details.velocity);
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          // Fora do builder: a árvore da mídia não reconstrói a cada
          // frame de mola nem de arrasto, só o Transform.
          child: MediaCard(color: widget.color),
          builder: (context, child) {
            final progress = _progress;

            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.behind != null)
                  Transform.scale(
                    // Cresce conforme o card de cima se afasta: é o que
                    // vende a sensação de pilha.
                    scale: 0.92 + 0.08 * progress.abs(),
                    child: Opacity(opacity: 0.6, child: widget.behind),
                  ),
                Transform(
                  // Matrix4 único, translate antes de rotateZ. Aninhar
                  // Transform.rotate por fora de Transform.translate
                  // girava o eixo do arrasto: quanto maior o ângulo, mais
                  // o movimento horizontal virava diagonal.
                  transform: Matrix4.identity()
                    ..translateByDouble(_position.dx, _position.dy, 0, 1)
                    ..rotateZ(progress * _maxRotationDegrees * math.pi / 180),
                  // Pivô bem abaixo da tela. Girar na base do próprio
                  // card produz tombo; o eixo distante produz pêndulo.
                  origin: Offset(0, height * 0.6),
                  alignment: Alignment.center,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      child!,
                      SwipeOverlay(progress: progress),
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
