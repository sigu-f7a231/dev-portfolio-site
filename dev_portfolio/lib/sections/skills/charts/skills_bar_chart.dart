// lib/sections/skills/charts/skills_bar_chart.dart

import 'package:flutter/material.dart';

class SkillsBarChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsBarChart({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  State<SkillsBarChart> createState() => _SkillsBarChartState();
}

class _SkillsBarChartState extends State<SkillsBarChart> {
  int? touchedIndex;

  final colors = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.yellowAccent,
    Colors.pinkAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 文字色をテーマに応じて設定
    final labelColor = widget.isDark ? Colors.white : Colors.black87;
    final valueColor = widget.isDark ? Colors.white70 : Colors.black54;
    final bgBarColor = widget.isDark ? Colors.white10 : Colors.black12;

    return Row(
      children: [
        // -------- 左：棒グラフ --------
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final isActive = i == touchedIndex;

              return MouseRegion(
                onEnter: (_) => setState(() => touchedIndex = i),
                onExit: (_) => setState(() => touchedIndex = null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // バー
                      Expanded(
                        child: Stack(
                          children: [
                            // 背景バー（100%）
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: bgBarColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // 実際の値
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: e.value / 100,
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length]
                                      .withOpacity(isActive ? 0.8 : 1.0),
                                  borderRadius: BorderRadius.circular(4),
                                  border: isActive
                                      ? Border.all(
                                          color: Colors.orangeAccent, width: 2)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // %
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${e.value.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isActive ? Colors.orangeAccent : valueColor,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 32),

        // -------- 右：凡例 --------
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              final isActive = i == touchedIndex;

              return MouseRegion(
                onEnter: (_) => setState(() => touchedIndex = i),
                onExit: (_) => setState(() => touchedIndex = null),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // 色
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(4),
                          border: isActive
                              ? Border.all(color: Colors.orangeAccent, width: 2)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 名前
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            color: isActive ? Colors.orangeAccent : labelColor,
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      // %
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${e.value.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isActive ? Colors.orangeAccent : valueColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}