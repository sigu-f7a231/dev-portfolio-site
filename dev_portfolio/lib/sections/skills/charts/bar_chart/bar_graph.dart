import 'package:flutter/material.dart';
import '../../../config/skills/skills_bar_chart_config.dart';

class BarGraph extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final int? touchedIndex;
  final bool isDark;
  final Function(int?)? onHover;

  const BarGraph({
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
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: BarChartLayout.barHeight,
                        decoration: BoxDecoration(
                          color: BarChartColors.bgBarColor(isDark),
                          borderRadius: BorderRadius.circular(
                            BarChartLayout.barBorderRadius,
                          ),
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: e.value / 100,
                        child: Container(
                          height: BarChartLayout.barHeight,
                          decoration: BoxDecoration(
                            color: BarChartColors
                                .mainColors[i % BarChartColors.mainColors.length]
                                .withOpacity(
                                  isActive
                                      ? BarChartLayout.barActiveOpacity
                                      : BarChartLayout.barInactiveOpacity,
                                ),
                            borderRadius: BorderRadius.circular(
                              BarChartLayout.barBorderRadius,
                            ),
                            border: isActive
                                ? Border.all(
                                    color: BarChartColors.highlightBorder,
                                    width: BarChartLayout.barActiveBorderWidth,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BarChartLayout.barValueSpacing),
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