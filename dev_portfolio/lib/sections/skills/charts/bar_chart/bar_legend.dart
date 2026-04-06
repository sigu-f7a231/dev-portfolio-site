import 'package:flutter/material.dart';
import '../../../config/skills_bar_chart_config.dart';

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
            padding: const EdgeInsets.symmetric(
              vertical: BarChartLayout.barItemSpacing,
            ),
            child: Row(
              children: [
                // カラーボックス
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

                // ラベル
                Expanded(
                  child: Text(
                    e.key,
                    style: BarChartTextStyle.label(
                      isDark: isDark,
                      isActive: isActive,
                    ),
                  ),
                ),

                // 値
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