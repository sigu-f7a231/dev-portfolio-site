// lib/sections/skills/charts/bar_chart/bar_legend.dart
import 'package:flutter/material.dart';
import '../../../config/skills_chart_config.dart';

class BarLegend extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final int? touchedIndex;
  final bool isDark;
  final Function(int?)? onHover;

  const BarLegend({
    super.key,
    required this.entries,
    required this.isDark,
    this.touchedIndex,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final isActive = i == touchedIndex;

        return MouseRegion(
          onEnter: (_) => onHover?.call(i),
          onExit: (_) => onHover?.call(null),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ChartLayout.barItemSpacing),
            child: Row(
              children: [
                Container(
                  width: ChartLayout.barLegendColorSize,
                  height: ChartLayout.barLegendColorSize,
                  decoration: BoxDecoration(
                    color: ChartColors.mainColors[i % ChartColors.mainColors.length],
                    borderRadius:
                        BorderRadius.circular(ChartLayout.barLegendColorRadius),
                    border: isActive
                        ? Border.all(
                            color: ChartColors.highlightBorder,
                            width: ChartLayout.barActiveBorderWidth)
                        : null,
                  ),
                ),
                const SizedBox(width: ChartLayout.barLegendSpacingItem),
                Expanded(
                  child: Text(
                    e.key,
                    style: ChartTextStyle.label(isDark: isDark, isActive: isActive),
                  ),
                ),
                SizedBox(
                  width: ChartLayout.barValueWidth,
                  child: Text(
                    '${e.value.toStringAsFixed(1)}%',
                    style: ChartTextStyle.value(isDark: isDark, isActive: isActive),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}