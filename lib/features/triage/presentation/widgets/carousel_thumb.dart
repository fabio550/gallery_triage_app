import 'package:flutter/material.dart';

class CarouselThumb extends StatelessWidget {
  final int index;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  
  const CarouselThumb({
    required this.index,
    required this.isActive,
    required this.color,
    required this.onTap,
    super.key,
  });
  

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 90,
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
        ),
      ),
    );
  }
}
