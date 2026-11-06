// lib/data/records.dart
//
// Repository が受け渡す「構造のデータ」と、YAML の文字との行き来
// - 1 件は普通の Map（キーは YAML の項目と同じ。Firestore の文書と同じ形。docs/plan/data-model.md）
// - YAML の文字からは loadYaml → 普通の Map に。書き出しは yaml_writer.dart の toYaml
import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../utils/yaml_writer.dart';

/// 構造のデータ 1 件（プロフィール全体、またはプロジェクト 1 件）
typedef DataRecord = Map<String, dynamic>;

/// YAML の文字 → 普通の Map。先頭が Map でなければ FormatException（書き方の誤りは YamlException）
DataRecord recordOfYaml(String text) {
  final doc = loadYaml(text);
  if (doc is! Map) throw const FormatException('先頭が「項目: 値」の形ではありません');
  return jsonDecode(jsonEncode(doc)) as DataRecord;
}

/// Work / Private の YAML の文字 → プロジェクトの並び。projects の並びがなければ FormatException
List<DataRecord> projectRecordsOfYaml(String text) {
  final projects = recordOfYaml(text)['projects'];
  if (projects is! List) throw const FormatException('projects の並びがありません');
  return [for (final p in projects) Map<String, dynamic>.from(p as Map)];
}

/// 普通の Map → YAML の文字
String yamlOfRecord(DataRecord record) => toYaml(record);

/// プロジェクトの並び → Work / Private の YAML の文字（projects: の下に並べる）
String yamlOfProjects(List<DataRecord> records) => toYaml({'projects': records});
