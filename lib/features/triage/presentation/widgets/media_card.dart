import 'package:flutter/material.dart';

class MediaCard extends StatelessWidget {
  final Color color;
  
  const MediaCard({
    required this.color,
    super.key
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )],
      ),
    );
  }
}
