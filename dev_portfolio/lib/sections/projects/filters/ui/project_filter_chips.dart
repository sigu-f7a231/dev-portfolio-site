// lib/sections/projects/filter_chips_section.dart
import 'package:flutter/material.dart';

class FilterChipsSection extends StatelessWidget {
  final String? title;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<String> onSelected;
  final bool isDark;

  const FilterChipsSection({
    super.key,
    this.title,
    required this.items,
    required this.selectedItems,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(title!, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return ChoiceChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
              selectedColor: isDark ? Colors.tealAccent : Colors.blueAccent,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
              labelStyle: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}