// lib/utils/projects_diff.dart
//
// 今表示している Work / Private と、これからアップロードする内容の違い（上書きの確認に使う）
// - プロジェクトはタイトルで対応づける（同じタイトルが複数あるときは、出てきた順番で対応づける）
// - 比べるときは表記の違いをそろえる（前後の空白・改行、数値と文字列、空のリンク）
//
// Flutter に依存しない。
import 'dart:convert';

import 'package:yaml/yaml.dart';

class ProjectsDiff {
  final List<String> added; // これからの内容にだけある
  final List<String> removed; // 今の内容にだけある（アップロードすると消える）
  final List<String> changed; // 両方にあるが中身が違う

  const ProjectsDiff({
    this.added = const [],
    this.removed = const [],
    this.changed = const [],
  });

  bool get hasChanges => added.isNotEmpty || removed.isNotEmpty || changed.isNotEmpty;
}

/// [current]（今の内容）と [next]（これからの内容）の YAML（JSON も可）を比べる
/// 今の内容が読めないときは、空とみなす
ProjectsDiff diffProjects(String current, String next) {
  final before = _keyed(_projects(current));
  final after = _keyed(_projects(next));

  return ProjectsDiff(
    added: [for (final k in after.keys) if (!before.containsKey(k)) k.$1],
    removed: [for (final k in before.keys) if (!after.containsKey(k)) k.$1],
    changed: [
      for (final k in after.keys)
        if (before.containsKey(k) && jsonEncode(before[k]) != jsonEncode(after[k])) k.$1,
    ],
  );
}

List<Object?> _projects(String text) {
  try {
    final doc = loadYaml(text);
    if (doc is YamlMap && doc['projects'] is YamlList) {
      return [for (final p in doc['projects'] as YamlList) _normalize(p)];
    }
  } catch (_) {
    // 読めない → 空
  }
  return const [];
}

/// タイトル（と同じタイトルの中での順番）→ 中身
Map<(String, int), Object?> _keyed(List<Object?> projects) {
  final seen = <String, int>{};
  final result = <(String, int), Object?>{};
  for (final p in projects) {
    final title = p is Map ? '${p['title'] ?? ''}' : '';
    final n = seen[title] = (seen[title] ?? 0) + 1;
    result[(title, n)] = p;
  }
  return result;
}

/// 比べやすい形にそろえる（キーは並べ替え、文字列・数値は前後の空白を除いた文字列、null・空文字は同じ扱い）
Object? _normalize(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => '$k').toList()..sort();
    return {
      for (final k in keys)
        if (_normalize(v[k]) != null) k: _normalize(v[k]),
    };
  }
  if (v is List) return [for (final e in v) _normalize(e)];
  if (v is bool) return v;
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}
