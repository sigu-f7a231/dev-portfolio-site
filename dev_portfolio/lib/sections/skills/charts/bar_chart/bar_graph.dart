import 'package:flutter/material.dart';
import '../../../config/skills/skills_bar_chart_config.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

class BarGraph extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final int? touchedIndex;
  final Function(int?)? onHover;
  final int topN;

  const BarGraph({
    super.key,
    required this.entries,
    this.touchedIndex,
    this.onHover,
    this.topN = AppSizes.chartTopN,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 値で降順ソート
    final sortedEntries = entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 上位 N 件
    final topEntries = sortedEntries.take(topN).toList();
    final otherEntries = sortedEntries.skip(topN).toList();

    // その他を追加
    if (otherEntries.isNotEmpty) {
      final otherValue = otherEntries.fold<double>(0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry(AppTexts.chartOthers, otherValue));
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
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: BarChartLayout.barHeight,
                        decoration: BoxDecoration(
                          color: colors.chartTrack,
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
                            color: colors
                                .seriesColor(i)
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
                                    color: colors.chartHighlight,
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
                    style: AppStyles.chartValue(context, isActive: isActive),
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