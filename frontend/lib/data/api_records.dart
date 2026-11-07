// lib/data/api_records.dart
//
// アプリのデータの形（YAML のテンプレートと同じ）⇔ API（Firestore）のデータの形（docs/plan/data-model.md の 2.）
//
//                     アプリ（YAML）                         API（Firestore）
//   プロフィール       home・about（recent_tech・past_tech）・sheet   profile（home・about・sheet）＋ skills（recentTech・pastTech）
//   プロジェクト       period: [開始, 終了 | 現在]              period: { start: YYYY-MM, end: YYYY-MM | null }
//                     server_os・db・…・skills を直に          tech: { server_os: [...], ... }
//                     「利用なし」                             空の並び（書かない）
//                     id なし                                 id・kind・order あり
// - API は形を厳しく確かめるので、送る前に合わせる（長すぎる文字は切る・https でないリンクは送らない・読めない期間は送らない）
// - id は、同じ種類・同じプロジェクト名の前のものがあれば引き継ぐ（表示設定で隠したプロジェクトが、保存し直しても隠れたままになるように）
// - 文字数の上限は API と同じ（services/api-hono/src/validate.ts の LIMITS）。名前・職種・スキルシートだけの項目は 100 文字、文章は 5000 文字
// - 生年月日は API では YYYY-MM-DD。アプリ（YAML・Excel）では「1990年04月01日」（読めない書き方なら送らない）
import 'dart:math';

import '../utils/skill_sheet.dart' show parseSheetDate, sheetDateText;

/// 技術の分類（YAML のキー。API の tech のキーと同じ）
const List<String> techKeys = [
  'server_os', 'db', 'tools', 'backend_frameworks', 'frontend_frameworks', 'ui_frameworks', 'testing_frameworks',
  'cloud_platforms', 'aws_services', 'azure_services', 'gcp_services', 'container', 'container_orchestration',
  'ai_services', 'skills',
];

/// 担当の工程（Work だけ）
const List<String> workflowKeys = [
  'requirements', 'basic_design', 'detailed_design', 'implementation_unit_test', 'integration_test', 'system_test',
  'maintenance_operation',
];

const List<String> _sheetKeys = ['furigana', 'gender', 'age', 'birthday', 'nationality', 'spouse', 'station', 'education'];
const List<String> _homeKeys = ['name', 'role', 'tagline'];
const List<String> _aboutKeys = ['intro', 'domains', 'strengths', 'style', 'closing', 'recent', 'past'];

const String _notUsed = '利用なし';
const String _now = '現在';
const int _shortText = 100;
const int _longText = 5000;
const int _listItems = 50;

String _text(Object? v, int max) {
  final s = v == null ? '' : '$v'.trim();
  return s.length > max ? s.substring(0, max) : s;
}

/// 文字の並び（「利用なし」・空は外す。カンマ・読点区切りの文字も並びにする）
List<String> _list(Object? v) {
  final Iterable<Object?> items = v is List ? v : (v is String ? v.split(RegExp(r'[,、]')) : const []);
  return [
    for (final item in items)
      if (_text(item, _shortText) case final s when s.isNotEmpty && s != _notUsed) s,
  ].take(_listItems).toList();
}

/// 「2023-04」「2023/4」「2023年4月」→ 2023-04。読めなければ null
String? _yearMonth(Object? v) {
  final m = RegExp(r'(\d{4})\D{0,3}(\d{1,2})').firstMatch(_text(v, _shortText));
  if (m == null) return null;
  final month = int.parse(m.group(2)!);
  if (month < 1 || month > 12) return null;
  return '${m.group(1)}-${month.toString().padLeft(2, '0')}';
}

Map<String, Object?>? _periodToApi(Object? v) {
  final parts = v is List ? v : (v is String ? v.split(RegExp(r'\s*[~〜～]\s*')) : const []);
  if (parts.isEmpty) return null;
  final start = _yearMonth(parts.first);
  if (start == null) return null;
  final endRaw = parts.length > 1 ? _text(parts[1], _shortText) : '';
  final end = endRaw.isEmpty || endRaw.contains(_now) ? null : _yearMonth(endRaw);
  if (end != null && end.compareTo(start) < 0) return {'start': start, 'end': null};
  return {'start': start, 'end': end};
}

final Random _random = Random.secure();

/// 新しいプロジェクトの id
String newProjectId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return 'p_${List.generate(20, (_) => chars[_random.nextInt(chars.length)]).join()}';
}

// ---------------- プロジェクト ----------------

/// アプリのプロジェクト（YAML の形）→ API の形
Map<String, dynamic> projectToApi(Map<String, dynamic> record, {required String kind, required int order, required String id}) {
  final tech = <String, List<String>>{
    for (final key in techKeys)
      if (_list(record[key]) case final items when items.isNotEmpty) key: items,
  };
  final link = _text(record['link'], 2000);
  final period = _periodToApi(record['period']);
  final workflow = record['workflow'];
  final title = _text(record['title'], _shortText);
  return {
    'id': id,
    'kind': kind,
    'order': order,
    'title': title.isEmpty ? '（名前なし）' : title,
    if (_text(record['description'], _longText) case final s when s.isNotEmpty) 'description': s,
    if (_text(record['details'], _longText) case final s when s.isNotEmpty) 'details': s,
    if (_list(record['role']) case final roles when roles.isNotEmpty) 'role': roles,
    if (_text(record['scale'], _shortText) case final s when s.isNotEmpty) 'scale': s,
    if (period != null) 'period': period,
    if (link.startsWith('https://') && !link.contains(' ')) 'link': link,
    if (tech.isNotEmpty) 'tech': tech,
    if (kind == 'work' && workflow is Map)
      'workflow': {for (final key in workflowKeys) if (workflow[key] is bool) key: workflow[key]},
  };
}

/// API のプロジェクト → アプリの形（YAML のテンプレートと同じキー。id・kind・order は持たない）
Map<String, dynamic> projectFromApi(Map<String, dynamic> project) {
  final period = project['period'];
  final tech = project['tech'] is Map ? project['tech'] as Map : const {};
  return {
    'title': project['title'] ?? '',
    'description': project['description'] ?? '',
    'details': project['details'] ?? '',
    'role': _list(project['role']),
    'scale': project['scale'] ?? '',
    for (final key in techKeys) key: (tech[key] is List && (tech[key] as List).isNotEmpty) ? List<String>.from((tech[key] as List).map((e) => '$e')) : [_notUsed],
    if (period is Map && period['start'] != null) 'period': ['${period['start']}', '${period['end'] ?? _now}'],
    'link': project['link'] ?? '',
    if (project['kind'] == 'work' && project['workflow'] is Map) 'workflow': Map<String, dynamic>.from(project['workflow'] as Map),
  };
}

/// [kind] の新しいプロジェクトの並び（アプリの形）を API の形にする。前のもの（API の形）と同じ名前なら id を引き継ぐ
List<Map<String, dynamic>> projectsToApi(
  List<Map<String, dynamic>> records, {
  required String kind,
  required List<Map<String, dynamic>> previous,
  String Function() newId = newProjectId,
}) {
  final unused = [for (final p in previous) if (p['kind'] == kind) p];
  return [
    for (var i = 0; i < records.length; i++)
      projectToApi(
        records[i],
        kind: kind,
        order: i,
        id: () {
          final title = _text(records[i]['title'], _shortText);
          final index = unused.indexWhere((p) => p['title'] == title);
          if (index < 0) return newId();
          return '${unused.removeAt(index)['id']}';
        }(),
      ),
  ];
}

// ---------------- プロフィール ----------------

Map<String, dynamic> _textMap(
  Object? v,
  List<String> keys, {
  List<String> lists = const [],
  List<String> short = const [],
}) {
  final map = v is Map ? v : const {};
  final result = <String, dynamic>{};
  for (final key in keys) {
    if (lists.contains(key)) {
      final items = _list(map[key]);
      if (items.isNotEmpty) result[key] = items;
    } else {
      final text = _text(map[key], short.contains(key) ? _shortText : _longText);
      if (text.isNotEmpty) result[key] = text;
    }
  }
  return result;
}

/// スキルシートだけの項目 → API の形（100 文字まで。生年月日は YYYY-MM-DD、読めなければ送らない）
Map<String, dynamic> _sheetToApi(Object? v) {
  final sheet = _textMap(v, _sheetKeys, short: _sheetKeys);
  final birthday = sheet['birthday'];
  if (birthday is String) {
    final date = parseSheetDate(birthday);
    if (date == null) {
      sheet.remove('birthday');
    } else {
      final (y, m, d) = date;
      sheet['birthday'] = '$y-${'$m'.padLeft(2, '0')}-${'$d'.padLeft(2, '0')}';
    }
  }
  return sheet;
}

Map<String, List<String>> _groups(Object? v) {
  if (v is! Map) return const {};
  return {
    for (final e in v.entries.take(30))
      if (_text(e.key, 50) case final key when key.isNotEmpty) key: _list(e.value),
  };
}

/// アプリのプロフィール（YAML の形）→ API の profile と skills
({Map<String, dynamic> profile, Map<String, dynamic> skills}) profileToApi(Map<String, dynamic> record) {
  final about = record['about'] is Map ? record['about'] as Map : const {};
  return (
    profile: {
      'home': _textMap(record['home'], _homeKeys, short: const ['name', 'role']),
      'about': _textMap(about, _aboutKeys, lists: const ['domains']),
      'sheet': _sheetToApi(record['sheet']),
    },
    skills: {
      if (_groups(about['recent_tech']) case final g when g.isNotEmpty) 'recentTech': g,
      if (_groups(about['past_tech']) case final g when g.isNotEmpty) 'pastTech': g,
    },
  );
}

/// API の profile と skills → アプリのプロフィール（YAML の形）
Map<String, dynamic> profileFromApi(Map<String, dynamic> profile, Map<String, dynamic> skills) {
  Map<String, dynamic> map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  final about = map(profile['about']);
  if (skills['recentTech'] is Map) about['recent_tech'] = map(skills['recentTech']);
  if (skills['pastTech'] is Map) about['past_tech'] = map(skills['pastTech']);
  final sheet = map(profile['sheet']);
  // 生年月日は、YAML・Excel と同じ「1990年04月01日」に戻す
  if (parseSheetDate('${sheet['birthday'] ?? ''}') case (final y, final m, final d)) sheet['birthday'] = sheetDateText(y, m, d);
  return {
    'home': map(profile['home']),
    'about': about,
    if (sheet.isNotEmpty) 'sheet': sheet,
  };
}
