import 'package:flutter/material.dart';
import '../../../config/skills_chart_config.dart';
import '../../../../utils/graph_utils.dart'; // ← 追加

class PieLegend extends StatelessWidget {
  final Map<String, double> data;
  final bool isDark;
  final int? hoveredIndex;
  final int? selectedIndex;
  final Function(int) onHover;
  final Function(int) onSelect;

  const PieLegend({
    super.key,
    required this.data,
    required this.isDark,
    this.hoveredIndex,
    this.selectedIndex,
    required this.onHover,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.mapIndexed((entry, index) {
        final isActive = index == hoveredIndex || index == selectedIndex;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => onHover(index),
          onExit: (_) => onHover(-1),
          child: GestureDetector(
            onTap: () => onSelect(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: ChartLayout.pieLegendColorSize,
                    height: ChartLayout.pieLegendColorSize,
                    decoration: BoxDecoration(
                      color: ChartColors.mainColors[index % ChartColors.mainColors.length],
                      borderRadius: BorderRadius.circular(ChartLayout.pieLegendColorRadius),
                      border: isActive
                          ? Border.all(color: ChartColors.highlightBorder, width: ChartLayout.pieActiveBorderWidth)
                          : null,
                    ),
                  ),
                  const SizedBox(width: ChartLayout.pieLegendSpacingItem),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: ChartTextStyle.label(isDark: isDark, isActive: isActive),
                    ),
                  ),
                  Text(
                    '${entry.value.toInt()}%',
                    style: ChartTextStyle.value(isDark: isDark, isActive: isActive),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}