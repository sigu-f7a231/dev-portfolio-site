import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';

class SkillsPieChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsPieChart({super.key, required this.data, required this.isDark});

  @override
  _SkillsPieChartState createState() => _SkillsPieChartState();
}

class _SkillsPieChartState extends State<SkillsPieChart> {
  int? hoveredIndex;   // マウスオーバー
  int? selectedIndex;  // クリック選択

  final List<Color> colors = [
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------- 円グラフ --------
        SizedBox(
          width: 300,
          height: 300,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 60,
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  setState(() {
                    final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex;
                    hoveredIndex = (idx != null &&
                            event is! PointerExitEvent &&
                            event is! PointerUpEvent)
                        ? idx
                        : null;

                    // クリックで選択状態にする
                    if (event is PointerDownEvent && idx != null) {
                      if (selectedIndex == idx) {
                        selectedIndex = null; // 同じ箇所なら選択解除
                      } else {
                        selectedIndex = idx;
                      }
                    }
                  });
                },
              ),
              sections: widget.data.entries.mapIndexed((entry, index) {
                final isActive = index == hoveredIndex || index == selectedIndex;

                Color baseColor = colors[index % colors.length];
                Color highlightColor = HSLColor.fromColor(baseColor)
                    .withLightness(0.7)
                    .toColor(); // 明るくして光らせる

                return PieChartSectionData(
                  value: entry.value,
                  color: isActive ? highlightColor : baseColor,
                  radius: isActive ? 120 : 100,
                  borderSide: isActive
                      ? BorderSide(color: Colors.orangeAccent, width: 3)
                      : BorderSide(color: Colors.transparent, width: 0),
                  showTitle: false, // 円内ラベル非表示
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // -------- 凡例 --------
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.data.entries.mapIndexed((entry, index) {
              final isActive = index == hoveredIndex || index == selectedIndex;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => hoveredIndex = index),
                onExit: (_) => setState(() => hoveredIndex = null),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedIndex == index) {
                        selectedIndex = null;
                      } else {
                        selectedIndex = index;
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            borderRadius: BorderRadius.circular(4),
                            border: isActive
                                ? Border.all(color: Colors.orangeAccent, width: 2)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive
                                  ? Colors.orangeAccent
                                  : (widget.isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value.toInt()}%',
                          style: TextStyle(
                            color: widget.isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Map.entries に index を付けるヘルパー
extension MapIndex<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<T> mapIndexed<T>(T Function(MapEntry<K, V>, int) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}