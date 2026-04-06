import 'package:flutter/material.dart';
import '../charts/skills_bar_chart.dart';
import '../charts/skills_pie_chart.dart';
import '../../../utils/language_utils.dart';
import '../../config/skills_widgets_card_config.dart';

class SkillsCard extends StatelessWidget {
  final Map<String, double> data;
  final bool isDark;
  final bool showPie;

  const SkillsCard({
    super.key,
    required this.data,
    required this.isDark,
    required this.showPie,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = SkillsCardConfig.cardColor(isDark);

    // workflow データなら日本語化
    final displayData = data.keys.any(
            (k) => LanguageUtils.workflowLabels['ja']?.containsKey(k) ?? false)
        ? LanguageUtils.translateWorkflowData(data)
        : data;

    return Center(
      child: Container(
        width: SkillsCardConfig.width,
        height: SkillsCardConfig.height,
        padding: const EdgeInsets.all(SkillsCardConfig.padding),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(SkillsCardConfig.borderRadius),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(SkillsCardConfig.shadowOpacity),
                blurRadius: SkillsCardConfig.shadowBlur,
                offset: SkillsCardConfig.shadowOffset,
              ),
          ],
        ),
        child: showPie
            ? SkillsPieChart(data: displayData, isDark: isDark)
            : SkillsBarChart(entries: displayData.entries.toList(), isDark: isDark),
      ),
    );
  }
}