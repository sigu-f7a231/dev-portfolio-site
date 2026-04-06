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

// workflow は true の割合を % で返す
Map<String, double> aggregateWorkflow(YamlList projects) {
  final Map<String, int> trueCount = {};
  final Map<String, int> totalCount = {};

  for (var project in projects) {
    final raw = project['workflow'] as YamlMap?;
    if (raw == null) continue;

    for (var entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value == true;

      trueCount[key] = (trueCount[key] ?? 0) + (value ? 1 : 0);
      totalCount[key] = (totalCount[key] ?? 0) + 1;
    }
  }

  return trueCount.map(
    (key, value) =>
        MapEntry(key, totalCount[key] == 0 ? 0 : (value / totalCount[key]!) * 100),
  );
}