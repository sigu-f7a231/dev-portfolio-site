// lib/utils/projects_yaml_validator.dart
//
// Work / Private の YAML として正しい形かを確かめる
// （dart:html を使わないので、flutter test からも呼べる）
import 'package:yaml/yaml.dart';

/// Work / Private の YAML として正しい形か
/// - `projects:` が 1 件以上の配列
/// - 各プロジェクトに `title` がある
/// - Work（dataType == 'work'）は `workflow` が必須、Private は `workflow` を書かない
bool isValidProjectsYaml(String text, String dataType) {
  try {
    final doc = loadYaml(text);
    if (doc is! YamlMap || !doc.containsKey('projects')) return false;
    final projects = doc['projects'];
    if (projects is! YamlList || projects.isEmpty) return false;

    for (final item in projects) {
      if (item is! YamlMap || !item.containsKey('title')) return false;
      if (dataType == 'work' && !item.containsKey('workflow')) return false;
      if (dataType == 'private' && item.containsKey('workflow')) return false;
    }
    return true;
  } catch (_) {
    return false;
  }
}
