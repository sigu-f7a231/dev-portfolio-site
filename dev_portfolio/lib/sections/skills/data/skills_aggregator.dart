import '../../../utils/string_utils.dart';
import '../../../utils/skill_name.dart';

/// カテゴリごとの出現割合（%）
/// 表記ゆれ（大文字・小文字、全角・半角、末尾の「;」「:」「.」「/」など、キャメルケース・スネークケース、
/// クラウドのサービスの先頭の「AWS」など）は 1 つにまとめて数える（lib/utils/skill_name.dart）
Map<String, double> aggregateCategory(
  List<dynamic> projects, // YamlList か、redistributeProjects の結果
  String key,
) {
  // 1 つのプロジェクトの中で同じもの（AWS Lambda と Lambda など）が重なっていても 1 回と数える
  final names = <String>[];
  for (var project in projects) {
    final seen = <String>{};
    for (final item in parseToList(project[key])) {
      final name = cleanSkillName(item);
      if (name.isEmpty || name == '利用なし') continue;
      if (seen.add(skillKey(name, category: key))) names.add(name);
    }
  }

  final display = canonicalSkillNames(names, category: key); // キー → 表示する名前
  final Map<String, int> countMap = {};
  for (final name in names) {
    final label = display[skillKey(name, category: key)]!;
    countMap[label] = (countMap[label] ?? 0) + 1;
  }

  final total = countMap.values.fold<int>(0, (sum, v) => sum + v);

  return countMap.map(
    (key, value) => MapEntry(
      key,
      total == 0 ? 0 : (value / total) * 100,
    ),
  );
}

/// workflow（true率）
Map<String, double> aggregateWorkflow(List<dynamic> projects) {
  final Map<String, int> trueCount = {};
  final Map<String, int> totalCount = {};

  for (var project in projects) {
    final raw = project['workflow'] as Map?;
    if (raw == null) continue;

    for (var entry in raw.entries) {
      final key = entry.key.toString();
      final value = entry.value == true;

      trueCount[key] = (trueCount[key] ?? 0) + (value ? 1 : 0);
      totalCount[key] = (totalCount[key] ?? 0) + 1;
    }
  }

  return trueCount.map(
    (key, value) => MapEntry(
      key,
      totalCount[key] == 0 ? 0 : (value / totalCount[key]!) * 100,
    ),
  );
}