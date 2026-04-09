import 'package:flutter/material.dart';
import '../../../config/skills/skills_bar_chart_config.dart';

class BarLegend extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final int? touchedIndex;
  final bool isDark;
  final Function(int?)? onHover;
  final int topN;

  const BarLegend({
    super.key,
    required this.entries,
    required this.isDark,
    this.touchedIndex,
    this.onHover,
    this.topN = 10,
  });

  @override
  Widget build(BuildContext context) {
    // 値で降順ソート
    final sortedEntries = entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(topN).toList();
    final otherEntries = sortedEntries.skip(topN).toList();
    if (otherEntries.isNotEmpty) {
      final otherValue = otherEntries.fold<double>(0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry('その他', otherValue));
    }

    return ListView.builder(
      itemCount: topEntries.length,
      itemBuilder: (context, i) {
        final e = topEntries[i];
        final isActive = i == touchedIndex;

        return MouseRegion(
          onEnter: (_) => onHover?.call(i),
          onExit: (_) => onHover?.call(null),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: BarChartLayout.barItemSpacing,
            ),
            child: Row(
              children: [
                Container(
                  width: BarChartLayout.barLegendColorSize,
                  height: BarChartLayout.barLegendColorSize,
                  decoration: BoxDecoration(
                    color: BarChartColors
                        .mainColors[i % BarChartColors.mainColors.length],
                    borderRadius: BorderRadius.circular(
                      BarChartLayout.barLegendColorRadius,
                    ),
                    border: isActive
                        ? Border.all(
                            color: BarChartColors.highlightBorder,
                            width: BarChartLayout.barActiveBorderWidth,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: BarChartLayout.barLegendSpacingItem),
                Expanded(
                  child: Text(
                    e.key,
                    style: BarChartTextStyle.label(
                      isDark: isDark,
                      isActive: isActive,
                    ),
                  ),
                ),
                SizedBox(
                  width: BarChartLayout.barValueWidth,
                  child: Text(
                    '${e.value.toStringAsFixed(1)}%',
                    style: BarChartTextStyle.value(
                      isDark: isDark,
                      isActive: isActive,
                    ),
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