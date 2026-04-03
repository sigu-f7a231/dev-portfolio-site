// lib/sections/skills/data/skills_aggregator.dart

import 'package:yaml/yaml.dart';

Map<String, double> aggregateCategory(
  YamlList projects,
  String key,
) {
  final Map<String, int> countMap = {};

  for (var project in projects) {
    final raw = project[key];

    List<String> items;

    if (raw is YamlList) {
      items = raw.map((e) => e.toString()).toList();
    } else if (raw is String) {
      items = raw.split(',').map((e) => e.trim()).toList();
    } else {
      items = [];
    }

    for (var item in items) {
      countMap[item] = (countMap[item] ?? 0) + 1;
    }
  }

  final total = countMap.values.fold<int>(0, (sum, v) => sum + v);

  return countMap.map(
    (key, value) => MapEntry(key, total == 0 ? 0 : (value / total) * 100),
  );
}