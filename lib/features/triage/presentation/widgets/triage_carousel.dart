import 'package:flutter/material.dart';

import 'carousel_thumb.dart';

class TriageCarousel extends StatelessWidget {
  final List<Color> items;
  final int currentIndex;
  final ValueChanged<int> onThumbTap;

  const TriageCarousel({
    required this.items,
    required this.currentIndex,
    required this.onThumbTap,
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return CarouselThumb(
            color: items[index],
            index: currentIndex,
            isActive: index == currentIndex,
            onTap: () => onThumbTap(index),
          );
        },
      ),
    );
  }
}