import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart'; // PointerEvent系を使うため

class SkillsPieChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsPieChart({super.key, required this.data, required this.isDark});

  @override
  _SkillsPieChartState createState() => _SkillsPieChartState();
}

class _SkillsPieChartState extends State<SkillsPieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        height: 600, // 円グラフのサイズを大きく
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              touchCallback: (event, pieTouchResponse) {
                setState(() {
                  final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex;
                  if (idx != null &&
                      event is! PointerExitEvent &&
                      event is! PointerUpEvent) {
                    touchedIndex = idx;
                  } else {
                    touchedIndex = null;
                  }
                });
              },
            ),
            sections: widget.data.entries.mapIndexed((entry, index) {
              final isTouched = index == touchedIndex;
              final double radius = isTouched ? 110 : 100; // マウスオーバーで大きく
              return PieChartSectionData(
                value: entry.value,
                title: '${entry.key}\n${entry.value.toInt()}%',
                radius: radius,
                titleStyle: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontSize: isTouched ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
                color: colors[index % colors.length],
              );
            }).toList(),
          ),
        ),
      ),
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