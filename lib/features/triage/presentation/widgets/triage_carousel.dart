class TriageCarousel extends StatefulWidget {
  final List<Color> items;
    
  const TriageCarousel({
    required this.items,
    super.key
  });

  @override
  State<TriageCarousel> createState() => _TriageCarouselState();
}

class _TriageCarouselState extends State<TriageCarousel> {
  int selectedIndex = 1; // Índice selecionado por padrão

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return CarouselThumb(
                index: index,
                isSelected: selectedIndex == index,
                color: widget.items[index],
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              );
            },
          ),
        ),
        Expanded(
          child: TriageCard(
            color: widget.items[selectedIndex],
          ),
        ),
      ]
    );
  }
}
