import 'package:flutter/material.dart';
import '../config/skills_section_config.dart';
import '../charts/skills_bar_chart.dart';
import '../charts/skills_pie_chart.dart';

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
    final cardColor = SkillsColors.card(isDark);

    return Center(
      child: Container(
        width: SkillsLayout.cardWidth,
        height: SkillsLayout.cardHeight,
        padding: const EdgeInsets.all(SkillsLayout.cardPadding),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(SkillsLayout.borderRadius),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(SkillsLayout.shadowOpacity),
                blurRadius: SkillsLayout.shadowBlur,
                offset: SkillsLayout.shadowOffset,
              ),
          ],
        ),
        child: showPie
            ? SkillsPieChart(data: data, isDark: isDark)
            : SkillsBarChart(data: data, isDark: isDark),
      ),
    );
  }
}