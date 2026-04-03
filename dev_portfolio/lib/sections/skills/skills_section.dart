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
    with TickerProviderStateMixin {
  late TabController _mainTabController; // Work / Private
  late TabController _categoryTabController; // skills / server_os / db / tools_fw
  bool _showPie = false;

  late Future<Map<String, Map<String, double>>> _workSkillsFuture;
  late Future<Map<String, Map<String, double>>> _privateSkillsFuture;

  final List<String> categories = ['skills', 'server_os', 'db', 'tools_fw'];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _categoryTabController = TabController(length: categories.length, vsync: this);

    // データ読み込み
    _workSkillsFuture = loadWorkSkillsAll();
    _privateSkillsFuture = loadPrivateSkillsAll();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _categoryTabController.dispose();
    super.dispose();
  }

  Map<String, double> _getCategoryData(Map<String, Map<String, double>> data, String category) {
    return data[category] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.black : const Color(0xFFDADAE3);
    final cardColor = isDark ? const Color(0xFF2A2A3D) : const Color(0xFFFDFDFD);
    final textColor = isDark ? Colors.white : const Color(0xFF222222);

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          // タイトルとPie切り替え
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
          // Work / Private タブ
          TabBar(
            controller: _mainTabController,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: textColor,
            indicatorColor: Colors.orangeAccent,
            tabs: const [
              Tab(text: 'Work'),
              Tab(text: 'Private'),
            ],
          ),
          const SizedBox(height: 16),
          // カテゴリータブ
          TabBar(
            controller: _categoryTabController,
            labelColor: Colors.orangeAccent,
            unselectedLabelColor: textColor,
            indicatorColor: Colors.orangeAccent,
            tabs: categories.map((c) => Tab(text: c.toUpperCase())).toList(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // Work Tab
                FutureBuilder<Map<String, Map<String, double>>>(
                  future: _workSkillsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final data = snapshot.data!;
                    return TabBarView(
                      controller: _categoryTabController,
                      children: categories.map((category) {
                        final categoryData = _getCategoryData(data, category);
                        return Center(
                          child: Container(
                            width: 1000,
                            height: 500,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                              ],
                            ),
                            child: _showPie
                                ? SkillsPieChart(data: categoryData, isDark: isDark)
                                : SkillsBarChart(data: categoryData, isDark: isDark),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                // Private Tab
                FutureBuilder<Map<String, Map<String, double>>>(
                  future: _privateSkillsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final data = snapshot.data!;
                    return TabBarView(
                      controller: _categoryTabController,
                      children: categories.map((category) {
                        final categoryData = _getCategoryData(data, category);
                        return Center(
                          child: Container(
                            width: 1000,
                            height: 500,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                              ],
                            ),
                            child: _showPie
                                ? SkillsPieChart(data: categoryData, isDark: isDark)
                                : SkillsBarChart(data: categoryData, isDark: isDark),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}