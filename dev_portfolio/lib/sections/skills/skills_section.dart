// lib/sections/skills/skills_section.dart
import 'package:flutter/material.dart';
import 'data/skills_work.dart';
import 'data/skills_private.dart';
import 'charts/skills_bar_chart.dart';
import 'charts/skills_pie_chart.dart';

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPie = false;

  // 非同期でロードしたスキルデータ
  Map<String, double>? workSkills;
  Map<String, double>? privateSkills;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final loadedWork = await loadWorkSkillsAll(); // workSkills の非同期読み込み
      final loadedPrivate = await loadPrivateSkillsAll(); // privateSkills の非同期読み込み

      setState(() {
        workSkills = loadedWork['skills'];
        privateSkills = loadedPrivate['skills'];
        _isLoading = false;
      });
    } catch (e) {
      // エラー処理
      debugPrint('Error loading skills: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Work タブ
                      Center(
                        child: SizedBox(
                          width: 1000,
                          height: 500,
                          child: _showPie
                              ? SkillsPieChart(data: workSkills!, isDark: isDark)
                              : SkillsBarChart(data: workSkills!, isDark: isDark),
                        ),
                      ),
                      // Private タブ
                      Center(
                        child: SizedBox(
                          width: 1000,
                          height: 500,
                          child: _showPie
                              ? SkillsPieChart(data: privateSkills!, isDark: isDark)
                              : SkillsBarChart(data: privateSkills!, isDark: isDark),
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