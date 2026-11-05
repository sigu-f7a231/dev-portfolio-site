// lib/utils/project_append.dart
//
// Work / Private の一覧に、プロジェクトを「追加」する（置き換えではなく、今の一覧の後ろに足す）
// - readProjectsInput … 貼り付けたテキスト・ファイル（YAML / Markdown）から、追加するプロジェクトを読む
//   次のどの書き方でもよい：
//     projects: の下に並べる（テンプレートと同じ）／ トップに「- title: …」を並べる ／ 1 件だけ「title: …」
//   Markdown はテンプレート（format_*.md）と同じ書き方
// - appendProjects … 今の YAML に足した YAML（JSON＝YAML として読める）を作る
//
// Flutter に依存しない。
import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../constants/app_texts.dart';
import 'data_format.dart';
import 'skill_name.dart';
import 'tech_catalog.dart';
import 'projects_yaml_validator.dart';

class ProjectsInput {
  /// 読み取れたプロジェクト（JSON と同じ形の Map）
  final List<Map<String, dynamic>> projects;

  /// 読み取れない理由（空なら読み取れた）
  final List<String> errors;

  const ProjectsInput(this.projects, this.errors);

  bool get isOk => errors.isEmpty && projects.isNotEmpty;
}

/// テキストから、[dataType]（'work' / 'private'）に追加するプロジェクトを読む
ProjectsInput readProjectsInput(String raw, {required String dataType, String? fileName}) {
  final format = detectFormat(raw, fileName: fileName);

  Object? node;
  if (format == DataFormat.markdown) {
    final n = normalizeInput(raw, kind: projectKind(dataType), fileName: fileName);
    if (n.text == null) return ProjectsInput(const [], n.errors);
    node = loadYaml(n.text!);
  } else {
    try {
      node = loadYaml(raw);
    } on YamlException catch (e) {
      return ProjectsInput(const [], [ProfileTexts.errorSyntax(e.message)]);
    }
  }

  // projects: の下 ／ トップの並び ／ 1 件だけ
  Object? list;
  if (node is YamlMap && node['projects'] is YamlList) {
    list = node['projects'];
  } else if (node is YamlList) {
    list = node;
  } else if (node is YamlMap && node.containsKey('title')) {
    list = [node];
  }
  if (list is! List || list.isEmpty) {
    return const ProjectsInput([], [DataTexts.noProjectsFound]);
  }

  final errors = <String>[];
  final projects = <Map<String, dynamic>>[];
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    final no = i + 1;
    if (item is! Map) {
      errors.add(DataTexts.itemNotMap(no));
      continue;
    }
    final map = jsonDecode(jsonEncode(item)) as Map<String, dynamic>;
    if ('${map['title'] ?? ''}'.trim().isEmpty) errors.add(DataTexts.itemNoTitle(no));
    if (dataType == 'work' && !map.containsKey('workflow')) errors.add(DataTexts.itemNoWorkflow(no));
    if (dataType == 'private' && map.containsKey('workflow')) errors.add(DataTexts.itemHasWorkflow(no));
    projects.add(map);
  }
  return ProjectsInput(errors.isEmpty ? projects : const [], errors);
}

/// 今の YAML（[currentYaml]）のプロジェクト。読めなければ空
List<Map<String, dynamic>> projectsOf(String currentYaml) {
  try {
    final doc = loadYaml(currentYaml);
    if (doc is YamlMap && doc['projects'] is YamlList) {
      return [
        for (final p in doc['projects'] as YamlList)
          if (p is Map) jsonDecode(jsonEncode(p)) as Map<String, dynamic>,
      ];
    }
  } catch (_) {
    // 読めないときは空（今の一覧がないものとして足す）
  }
  return [];
}

/// 今の一覧の後ろに [adding] を足した YAML（JSON の文字列。YAML として読める）
/// [keepCurrent] が false なら今の一覧は使わない（サンプルを外すとき）
/// 足したあとも Work / Private として正しい形でなければ null
String? appendProjects(
  String currentYaml,
  List<Map<String, dynamic>> adding, {
  required String dataType,
  bool keepCurrent = true,
}) {
  final text = jsonEncode({
    'projects': [if (keepCurrent) ...projectsOf(currentYaml), ...adding],
  });
  return isValidProjectsYaml(text, dataType) ? text : null;
}

/// 今の一覧と同じタイトルのもの（追加しても両方残るので、確認画面で知らせる）
List<String> duplicateTitles(String currentYaml, List<Map<String, dynamic>> adding) {
  final current = {for (final p in projectsOf(currentYaml)) '${p['title']}'.trim()};
  return [
    for (final p in adding)
      if (current.contains('${p['title']}'.trim())) '${p['title']}'.trim(),
  ];
}

/// 技術の項目（YAML のキー）
const List<String> projectListKeys = [
  'server_os', 'db', 'tools', 'backend_frameworks', 'frontend_frameworks', 'ui_frameworks',
  'testing_frameworks', 'cloud_platforms', 'aws_services', 'azure_services', 'gcp_services',
  'container', 'container_orchestration', 'ai_services', 'skills',
];

/// 入力フォームの候補：今の Work / Private（[yamlTexts]）に書かれている技術を、項目ごとにまとめる
/// （表記ゆれは 1 つにまとめ、「利用なし」は除く。AWS などは先頭を外した名前）
/// Skills・Tools は、グループ（tools_vcs / skills_lang など）ごとの候補も入れる（書いたままの名前で見分ける）
Map<String, List<String>> tagSuggestions(Iterable<String> yamlTexts) {
  // Skills・Tools に書かれたフロントエンドなどは、本来の分類の候補にする
  final projects = redistributeProjects([for (final t in yamlTexts) ...projectsOf(t)]);
  List<String> valuesOf(Object? v) => v is List
      ? [for (final e in v) '$e']
      : v is String
          ? v.split(',')
          : const [];
  List<String> raw(String key) => [
        for (final p in projects)
          for (final v in valuesOf(p[key]))
            if (cleanSkillName(v).isNotEmpty && cleanSkillName(v) != ExcelTexts.notUsed) v,
      ];
  return {
    for (final g in SkillGroup.values)
      g.key: uniqueSkillNames([for (final v in raw('skills')) if (skillGroupOf(v) == g) v],
          category: 'skills'),
    for (final g in ToolGroup.values)
      g.key: uniqueSkillNames([for (final v in raw('tools')) if (toolGroupOf(v) == g) v],
          category: 'tools'),
    // 役割（PM・PL・SE・PG など）
    'role': uniqueSkillNames(raw('role'), category: 'role'),
    for (final key in projectListKeys)
      key: uniqueSkillNames(
        [
          for (final p in projects)
            for (final v in valuesOf(p[key]))
              if (cleanSkillName(v).isNotEmpty && cleanSkillName(v) != ExcelTexts.notUsed) v,
        ],
        category: key,
      ),
  };
}

