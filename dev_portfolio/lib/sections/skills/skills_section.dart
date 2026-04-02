// lib/sections/skills/skills_section.dart
import 'package:flutter/material.dart';
import 'work_skills.dart';
import 'private_skills.dart';
import 'skills_bar_chart.dart';
import 'skills_pie_chart.dart';

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPie = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.deepPurple;
    final textColor = Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // タイトルと Pie/Switch
          Row(
            children: [
              Text('Skills', style: TextStyle(fontSize: 28, color: textColor)),
              const Spacer(),
              Row(
                children: [
                  Text('Pie', style: TextStyle(color: textColor)),
                  Switch(
                    value: _showPie,
                    onChanged: (val) => setState(() => _showPie = val),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // タブ
          TabBar(
            controller: _tabController,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: textColor,
            indicatorColor: Colors.orangeAccent,
            tabs: const [Tab(text: 'Work'), Tab(text: 'Private')],
          ),
          const SizedBox(height: 16),

          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Center(
                  child: SizedBox(
                    width: 1000, // グラフ領域
                    height: 500,
                    child: _showPie
                        ? SkillsPieChart(data: workSkills, isDark: isDark)
                        : SkillsBarChart(data: workSkills, isDark: isDark),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 1000,
                    height: 500,
                    child: _showPie
                        ? SkillsPieChart(data: privateSkills, isDark: isDark)
                        : SkillsBarChart(data: privateSkills, isDark: isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}