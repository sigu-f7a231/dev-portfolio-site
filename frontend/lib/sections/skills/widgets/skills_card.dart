import 'package:flutter/material.dart';
import '../charts/skills_bar_chart.dart';
import '../charts/skills_pie_chart.dart';
import '../../../utils/language_utils.dart';
import '../../config/skills/skills_widgets_card_config.dart';
import '../../../theme/app_styles.dart';

class SkillsCard extends StatelessWidget {
  final Map<String, double> data;
  final bool showPie;

  const SkillsCard({
    super.key,
    required this.data,
    required this.showPie,
  });

  @override
  Widget build(BuildContext context) {
    // workflow データなら日本語化
    final displayData = data.keys.any(
            (k) => LanguageUtils.workflowLabels['ja']?.containsKey(k) ?? false)
        ? LanguageUtils.translateWorkflowData(data)
        : data;

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: SkillsCardConfig.maxWidth,
          minHeight: SkillsCardConfig.minHeight,
        ),
        padding: const EdgeInsets.all(SkillsCardConfig.padding),
        // 影はダークモードでは透明（＝影なし）になる
        decoration: AppStyles.card(
          context,
          radius: SkillsCardConfig.borderRadius,
          shadowBlur: SkillsCardConfig.shadowBlur,
          shadowOffset: SkillsCardConfig.shadowOffset,
        ),
        child: showPie
            ? SkillsPieChart(data: displayData)
            : SkillsBarChart(entries: displayData.entries.toList()),
      ),
    );
  }
}
