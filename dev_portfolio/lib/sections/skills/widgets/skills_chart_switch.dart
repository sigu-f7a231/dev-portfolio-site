import 'package:flutter/material.dart';
import '../../../widgets/app_segment.dart';
import '../../../constants/app_texts.dart';

/// Bar / Pie 切り替え（アイコン）
class SkillsChartSwitch extends StatelessWidget {
  final bool showPie; // true: Pie 選択, false: Bar 選択
  final ValueChanged<bool> onToggle;

  const SkillsChartSwitch({
    super.key,
    required this.showPie,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AppSegment<bool>(
      value: showPie,
      onChanged: onToggle,
      items: const [
        AppSegmentItem(
          value: false,
          icon: Icons.bar_chart,
          tooltip: AppTexts.chartBarTooltip,
        ),
        AppSegmentItem(
          value: true,
          icon: Icons.pie_chart_outline,
          tooltip: AppTexts.chartPieTooltip,
        ),
      ],
    );
  }
}
