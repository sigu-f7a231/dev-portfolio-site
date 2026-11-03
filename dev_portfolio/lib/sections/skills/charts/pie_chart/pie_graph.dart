import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/skills/skills_pie_chart_config.dart';
import 'package:flutter/gestures.dart';
import '../../../../utils/graph_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

class PieGraph extends StatelessWidget {
  final Map<String, double> data;
  final int? hoveredIndex;
  final int? selectedIndex;
  final Function(int?) onHover;
  final Function(int?) onSelect;
  final int topN;

  /// 円グラフの大きさ。PieChartLayout.pieSize を基準に、半径も同じ比率で縮める
  final double size;

  const PieGraph({
    super.key,
    required this.data,
    this.size = PieChartLayout.pieSize,
    this.hoveredIndex,
    this.selectedIndex,
    required this.onHover,
    required this.onSelect,
    this.topN = AppSizes.chartTopN,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final scale = size / PieChartLayout.pieSize;

    // データを値順にソート
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 上位N件とその他
    final topEntries = sortedEntries.take(topN).toList();
    final otherEntries = sortedEntries.skip(topN).toList();
    if (otherEntries.isNotEmpty) {
      final otherValue =
          otherEntries.fold<double>(0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry(AppTexts.chartOthers, otherValue));
    }

    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          sectionsSpace: PieChartLayout.pieSectionsSpace,
          centerSpaceRadius: PieChartLayout.pieCenterRadius * scale,
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex;
              if (event is PointerDownEvent) {
                onSelect(idx);
              } else if (event is! PointerExitEvent && event is! PointerUpEvent) {
                onHover(idx);
              } else {
                onHover(null);
              }
            },
          ),
          sections: topEntries.mapIndexed((entry, index) {
            final isHovered = index == hoveredIndex;
            final isSelected = index == selectedIndex;
            final baseColor = colors.seriesColor(index);

            Color sectionColor = baseColor.withOpacity(
              PieChartOpacity.of(
                isDark: isDark,
                isHovered: isHovered,
                isSelected: isSelected,
              ),
            );

            if (isSelected) {
              sectionColor = HSLColor.fromColor(baseColor)
                  .withLightness(PieChartLayout.pieHighlightLightness)
                  .toColor();
            }

            return PieChartSectionData(
              value: entry.value,
              color: sectionColor,
              radius: (isSelected
                      ? PieChartLayout.pieActiveRadius
                      : PieChartLayout.pieRadius) *
                  scale,
              borderSide: isSelected
                  ? BorderSide(
                      color: colors.chartHighlight,
                      width: PieChartLayout.pieActiveBorderWidth,
                    )
                  : BorderSide.none, // 非選択時は枠線なし
              showTitle: false,
            );
          }).toList(),
        ),
      ),
    );
  }
}