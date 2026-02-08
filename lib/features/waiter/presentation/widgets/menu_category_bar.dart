import 'package:flutter/material.dart';

class MenuCategoryBar extends StatelessWidget {
  final List categories;
  final String activeCategory;
  final Function(String) onSelect;
  final Color cyan;

  const MenuCategoryBar({super.key, required this.categories, required this.activeCategory, required this.onSelect, required this.cyan});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          String name = index == 0 ? "All" : categories[index - 1]['name'];
          bool isSelected = activeCategory == name;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(name, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onSelect(name),
              selectedColor: cyan,
              backgroundColor: Colors.white10,
            ),
          );
        },
      ),
    );
  }
}