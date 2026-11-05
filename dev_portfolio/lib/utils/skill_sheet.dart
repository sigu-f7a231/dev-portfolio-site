// lib/utils/skill_sheet.dart
//
// スキルシート（Excel）から、プロフィール（Home / About）と Work / Private の YAML を作る
// - レイアウトは assets/data/format_skill_sheet.xlsx（「Excel テンプレートを保存」で保存できるもの）
// - 作った YAML は、YAML / Markdown で読み込んだときと同じ readProfileBundle で確かめて反映する
//
// 読み取る場所（セルの位置ではなく、見出しの文字で探す。行や列が多少ずれても読める）
//   Home / About   … 「氏名」の右のセル ／ 「過去の開発経験」「直近の開発経験」を含むセル
//                    （それぞれの「主な使用技術・開発環境：」より下は「言語：A、B」の形の技術の一覧）
//   sheet          … 「ふりがな」「性別」「年齢」「生年月日」「国籍」「配偶者」「最寄駅」「学歴」の右のセル
//                    （画面には出さず、［ダウンロード］のスキルシートにそのまま書く。年齢は生年月日が読めないときだけ）
//   Work / Private … 「プロジェクト名」の見出しの行から下。「No.」の列に番号がある行から次の番号の前までが 1 件
//                    期間 ／ プロジェクト名（1 行目）と業務概要（2 行目以降）／ 役割・規模 ／ サーバ OS ／ DB ／ FW・MW ツール等 ／
//                    使用言語 ／ 作業工程（要件定義〜保守・運用の列に ● など何か書いてあれば担当）
//                    プロジェクト名に「プライベート」か「個人開発」が入っているものだけ Private（作業工程は使わない）
//
// Flutter に依存しない（dart run tool/run.dart からも使う）。
import 'dart:typed_data';

import '../constants/app_texts.dart';
import 'skill_name.dart';
import 'tech_catalog.dart';
import 'xlsx_reader.dart';
import 'yaml_writer.dart';

/// Excel のテンプレート（アセット）と、保存するときの名前
const String skillSheetTemplateAsset = 'assets/data/format_skill_sheet.xlsx';
const String skillSheetTemplateFileName = 'skill_sheet.xlsx';
const String skillSheetMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// ファイル選択で選べる拡張子（.xls は形式が違うので読めない）
const List<String> skillSheetExtensions = ['xlsx', 'xlsm'];

bool isSkillSheetFile(String fileName) {
  final lower = fileName.toLowerCase();
  return skillSheetExtensions.any((e) => lower.endsWith('.$e'));
}

/// 「xxx.xlsx」→「xxx.yaml」（作った YAML を保存するときの名前）
String skillSheetYamlName(String excelName) {
  final dot = excelName.lastIndexOf('.');
  return '${dot > 0 ? excelName.substring(0, dot) : excelName}.yaml';
}

class SkillSheetResult {
  /// プロフィール＋（あれば）work / private の YAML。読めなかったときは null
  final String? yamlText;

  /// 読めなかった理由
  final List<String> errors;

  const SkillSheetResult.ok(String this.yamlText) : errors = const [];
  const SkillSheetResult.error(this.errors) : yamlText = null;

  bool get isOk => yamlText != null;
}

/// 生成する Home / About の項目の数の上限
class SkillSheetLimits {
  SkillSheetLimits._();

  /// 右側のカードに出す技術の分類の数・1 分類あたりの数
  static const int cardGroups = 4;
  static const int cardItems = 6;

  /// 紹介文に挙げる言語（または領域）の数・自己紹介に挙げる領域の数
  static const int taglineItems = 4;
  static const int introAreas = 3;
}

/// Excel（.xlsx）のバイト列から YAML を作る。[fileName] は YAML の先頭のコメントに使う
SkillSheetResult convertSkillSheet(Uint8List bytes, {String? fileName}) {
  final List<XlsxSheet> sheets;
  try {
    sheets = readXlsx(bytes);
  } catch (_) {
    return const SkillSheetResult.error([ExcelTexts.notXlsx]);
  }

  // 「氏名」のあるシート（なければ最初のシート）
  final sheet = sheets.firstWhere(
    (s) => s.cells.any((c) => _compact(c.value) == ExcelTexts.labelName),
    orElse: () => sheets.first,
  );
  return _convert(sheet, fileName: fileName);
}

SkillSheetResult _convert(XlsxSheet sheet, {String? fileName}) {
  final errors = <String>[];
  final table = _ProjectTable.find(sheet);

  // ---------- Home / About ----------
  final name = _rightOf(sheet, ExcelTexts.labelName);
  if (name == null || name.isEmpty) errors.add(ExcelTexts.nameMissing);

  final experienceText = sheet.cells
      .where((c) => table == null || c.row < table.headerRow)
      .where((c) => _experienceHeading.hasMatch(c.value) && c.value.contains('\n'))
      .map((c) => c.value)
      .join('\n');
  final exp = _parseExperience(experienceText);
  if (exp.past.isEmpty && exp.recent.isEmpty) errors.add(ExcelTexts.experienceMissing);

  if (errors.isNotEmpty) return SkillSheetResult.error(errors);

  // ---------- Work / Private ----------
  final work = <Map<String, Object?>>[];
  final private = <Map<String, Object?>>[];
  if (table != null) {
    for (final p in table.projects(sheet)) {
      (p.isPrivate ? private : work).add(p.toMap());
    }
  }

  final sheetInfo = _sheetInfo(sheet);

  final data = <String, Object?>{
    'home': _home(name!, exp),
    'about': _about(exp),
    if (sheetInfo.isNotEmpty) 'sheet': sheetInfo,
    if (work.isNotEmpty) 'work': work,
    if (private.isNotEmpty) 'private': private,
  };
  return SkillSheetResult.ok(toYaml(data, header: ExcelTexts.yamlHeader(fileName)));
}

// ============================================================
// Home / About
// ============================================================
final _experienceHeading = RegExp(r'(過去|直近)の(開発|業務)経験');
final _sectionLine = RegExp(r'^(過去|直近)の(開発|業務)経験\s*[：:]?\s*$');
final _techHeading = RegExp(r'^主な(使用)?技術');
// 「見出し：値」（見出しに括弧を含まない。括弧の中の「：」や URL の「https:」では分けない）
final _labelValue = RegExp(r'^([^：:（）()]{1,30}?)\s*[：:]\s*(.*)$');

class _Experience {
  /// 「領域：説明」の行
  final List<String> past = [];
  final List<String> recent = [];

  /// 分類（言語 / FW・ライブラリ / …）→ 技術
  final Map<String, List<String>> pastTech = {};
  final Map<String, List<String>> recentTech = {};

  /// 「領域：説明」の領域の部分
  static List<String> areas(List<String> lines) => [
        for (final l in lines)
          if (_labelValue.firstMatch(l) case final m?) m.group(1)!.trim(),
      ];
}

_Experience _parseExperience(String text) {
  final exp = _Experience();
  List<String>? lines;
  Map<String, List<String>>? tech;
  var inTech = false;

  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final section = _sectionLine.firstMatch(line);
    if (section != null) {
      final isPast = section.group(1) == '過去';
      lines = isPast ? exp.past : exp.recent;
      tech = isPast ? exp.pastTech : exp.recentTech;
      inTech = false;
      continue;
    }
    if (lines == null || tech == null) continue; // 見出しより前は読まない
    if (_techHeading.hasMatch(line)) {
      inTech = true;
      continue;
    }
    if (inTech) {
      final m = _labelValue.firstMatch(line);
      if (m == null) continue;
      final items = _splitItems(m.group(2)!);
      if (items.isNotEmpty) tech[m.group(1)!.trim()] = items;
    } else {
      lines.add(line);
    }
  }
  return exp;
}

Map<String, Object?> _home(String name, _Experience exp) {
  final tech = exp.recentTech.isNotEmpty ? exp.recentTech : exp.pastTech;
  final languages = _languages(tech);
  final areas = _Experience.areas(exp.recent.isNotEmpty ? exp.recent : exp.past);

  final String tagline;
  if (languages.isNotEmpty) {
    tagline = ExcelTexts.taglineLanguages(languages.take(SkillSheetLimits.taglineItems).toList());
  } else if (areas.isNotEmpty) {
    tagline = ExcelTexts.taglineAreas(areas.take(SkillSheetLimits.taglineItems).toList());
  } else {
    tagline = ExcelTexts.taglineFallback;
  }

  return {
    'name': name,
    'role': ExcelTexts.defaultRole,
    'tagline': tagline,
    'card': {
      for (final e in tech.entries.take(SkillSheetLimits.cardGroups))
        e.key: e.value.take(SkillSheetLimits.cardItems).toList(),
    },
  };
}

Map<String, Object?> _about(_Experience exp) {
  final pastAreas = _Experience.areas(exp.past);
  final recentAreas = _Experience.areas(exp.recent);
  final intro = [
    if (pastAreas.isNotEmpty)
      ExcelTexts.introPast(pastAreas.take(SkillSheetLimits.introAreas).toList()),
    if (recentAreas.isNotEmpty)
      ExcelTexts.introRecent(recentAreas.take(SkillSheetLimits.introAreas).toList()),
  ].join();

  return {
    'intro': intro.isEmpty ? ExcelTexts.introFallback : intro,
    if (recentAreas.isNotEmpty) 'domains': recentAreas,
    if (exp.recent.isNotEmpty) 'recent': exp.recent.join('\n'),
    if (exp.recentTech.isNotEmpty) 'recent_tech': exp.recentTech,
    if (exp.past.isNotEmpty) 'past': exp.past.join('\n'),
    if (exp.pastTech.isNotEmpty) 'past_tech': exp.pastTech,
  };
}

/// 技術の一覧から「言語」の分類を探す（なければ空）
List<String> _languages(Map<String, List<String>> tech) {
  for (final e in tech.entries) {
    if (e.key.contains('言語')) return e.value;
  }
  return const [];
}

// ============================================================
// スキルシートだけの個人の項目（ふりがな・性別・年齢・生年月日・国籍・配偶者・最寄駅・学歴）
// ============================================================
/// 見出しの右の値（右に次の見出しがあれば空）。書かれていない項目は入れない
Map<String, String> _sheetInfo(XlsxSheet sheet) {
  final labels = {ExcelTexts.labelName, ...ExcelTexts.sheetLabels.values};
  final result = <String, String>{};
  for (final e in ExcelTexts.sheetLabels.entries) {
    final cell = sheet.cells
        .where((c) => _compact(c.value) == e.value || _compact(c.value) == e.value.replaceAll('寄', '寄り'))
        .firstOrNull;
    if (cell == null) continue;
    final row = sheet.rows[cell.row]!;
    final cols = row.keys.where((c) => c > cell.col).toList()..sort();
    if (cols.isEmpty) continue;
    var value = row[cols.first]!.trim();
    if (labels.contains(_compact(value))) continue; // 値が空で、次の見出しまで来た
    if (e.key == 'birthday') {
      // 日付の書式のセル（Excel の日付は 1899-12-30 からの日数）
      final serial = double.tryParse(value);
      if (serial != null && serial > 1000) {
        final d = DateTime.utc(1899, 12, 30).add(Duration(days: serial.floor()));
        value = sheetDateText(d.year, d.month, d.day);
      }
    }
    if (value.isNotEmpty) result[e.key] = value;
  }
  // 年齢は生年月日から出せる（［ダウンロード］では出力した日の年齢にする）ので、生年月日が読めるときは持たない
  if (parseSheetDate(result['birthday'] ?? '') != null) result.remove('age');
  return result;
}

/// 生年月日の書き方（テンプレートと同じ「1990年04月01日」）
String sheetDateText(int y, int m, int d) =>
    '$y年${'$m'.padLeft(2, '0')}月${'$d'.padLeft(2, '0')}日';

/// 「1990年04月01日」「1990/4/1」「1990-04-01」などを (年, 月, 日) に（読めなければ null）
(int, int, int)? parseSheetDate(String s) {
  final m = RegExp(r'(\d{4})\s*[-/.年]\s*(\d{1,2})\s*[-/.月]\s*(\d{1,2})').firstMatch(toHalfWidth(s));
  if (m == null) return null;
  final (y, mo, d) = (int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  return (y, mo, d);
}

// ============================================================
// 役割・規模（「役割 / 規模」の列）
// ============================================================
/// 列の中身（枠の中のセルをすべて）から、役割と規模に分ける
/// - 「役割：PG」「規模：10名」のような見出しがあればそれに従う
/// - 見出しのない行は、人数（「10名」「5人」）や「規模」「体制」などの言葉があれば規模、それ以外は役割
///   （役割は「 / 」「・」「、」「,」で分ける：PL / SE → PL, SE）
({List<String> role, String scale}) roleAndScaleOf(List<String> cells) {
  final roles = <String>[];
  final scales = <String>[];
  final labelRe = RegExp(r'^([^：:]{1,10})\s*[：:]\s*(.*)$');
  final peopleRe = RegExp(r'\d+\s*(名|人)');
  void addRoles(String s) {
    for (final r in s.split(RegExp(r'\s*[/／・、,，]\s*'))) {
      final v = r.trim();
      if (v.isNotEmpty && !roles.contains(v)) roles.add(v);
    }
  }

  for (final raw in cells.expand((c) => c.split('\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final m = labelRe.firstMatch(line);
    final label = m?.group(1)?.trim() ?? '';
    if (m != null && ExcelTexts.roleLabels.any(label.contains)) {
      addRoles(m.group(2)!);
    } else if (m != null && ExcelTexts.scaleLabels.any(label.contains)) {
      if (m.group(2)!.trim().isNotEmpty) scales.add(m.group(2)!.trim());
    } else if (peopleRe.hasMatch(toHalfWidth(line)) || ExcelTexts.scaleLabels.any(line.contains)) {
      scales.add(line);
    } else {
      addRoles(line);
    }
  }
  return (role: roles, scale: scales.join(' / '));
}

// ============================================================
// Work / Private
// ============================================================
/// 作業工程の列見出し（先頭一致）→ workflow のキー
const _workflowHeadings = <String, String>{
  '要件定義': 'requirements',
  '基本設計': 'basic_design',
  '詳細設計': 'detailed_design',
  '実装': 'implementation_unit_test',
  '結合': 'integration_test',
  '総合': 'system_test',
  'システムテスト': 'system_test',
  '保守': 'maintenance_operation',
  '運用': 'maintenance_operation',
};
const _workflowKeys = [
  'requirements',
  'basic_design',
  'detailed_design',
  'implementation_unit_test',
  'integration_test',
  'system_test',
  'maintenance_operation',
];

/// プロジェクトの表の見出しの位置
class _ProjectTable {
  final int headerRow;
  final int nameCol;
  final int? noCol, periodCol, roleCol, osCol, dbCol, toolsCol, langCol;

  /// 列 → workflow のキー
  final Map<int, String> workflowCols;

  _ProjectTable({
    required this.headerRow,
    required this.nameCol,
    required this.noCol,
    required this.periodCol,
    required this.roleCol,
    required this.osCol,
    required this.dbCol,
    required this.toolsCol,
    required this.langCol,
    required this.workflowCols,
  });

  /// 「プロジェクト名」で始まる見出しの行を探す（なければ null）
  static _ProjectTable? find(XlsxSheet sheet) {
    final header =
        sheet.cells.where((c) => _compact(c.value).startsWith('プロジェクト名')).firstOrNull;
    if (header == null) return null;
    final row = header.row;

    int? no, period, role, os, db, tools, lang;
    for (final c in sheet.cells.where((c) => c.row == row)) {
      final t = _compact(c.value);
      if (c.col == header.col) continue;
      if (t.toLowerCase().startsWith('no')) {
        no ??= c.col;
      } else if (t.contains('期間')) {
        period ??= c.col;
      } else if (t.contains('役割') || t.contains('規模')) {
        role ??= c.col;
      } else if (t.contains('サーバ') || t.endsWith('OS')) {
        os ??= c.col;
      } else if (t.contains('FW') || t.contains('ツール')) {
        tools ??= c.col;
      } else if (t.contains('言語')) {
        lang ??= c.col;
      } else if (t == 'DB' || t.contains('データベース')) {
        db ??= c.col;
      }
    }

    // 作業工程の小見出し（見出しの行か、その次の行）
    final workflow = <int, String>{};
    for (final c in sheet.cells.where((c) => c.row == row || c.row == row + 1)) {
      final t = _compact(c.value);
      for (final e in _workflowHeadings.entries) {
        if (t.startsWith(e.key)) {
          workflow[c.col] = e.value;
          break;
        }
      }
    }

    return _ProjectTable(
      headerRow: row,
      nameCol: header.col,
      noCol: no,
      periodCol: period,
      roleCol: role,
      osCol: os,
      dbCol: db,
      toolsCol: tools,
      langCol: lang,
      workflowCols: workflow,
    );
  }

  /// 「No.」の列に値がある行から、次の番号の前の行までを 1 件として読む（名前が空のものは飛ばす）
  /// 「No.」の列がなければ、プロジェクト名の列に値がある行ごとに 1 件とする
  List<_SheetProject> projects(XlsxSheet sheet) {
    final firstRow = headerRow + (workflowCols.isEmpty ? 1 : 2);
    final startCol = noCol ?? nameCol;
    final starts = <int>[
      for (final r in sheet.rows.keys.toList()..sort())
        if (r >= firstRow && sheet.cell(r, startCol) != null) r,
    ];

    final result = <_SheetProject>[];
    for (var i = 0; i < starts.length; i++) {
      final from = starts[i];
      final to = i + 1 < starts.length ? starts[i + 1] - 1 : sheet.maxRow;
      List<String> column(int? col) => col == null
          ? const []
          : [
              for (var r = from; r <= to; r++)
                if (sheet.cell(r, col) case final v?) v,
            ];

      final nameCells = column(nameCol);
      if (nameCells.isEmpty) continue;
      result.add(_SheetProject(
        name: nameCells.first.trim(),
        summary: nameCells.skip(1).join('\n').trim(),
        period: column(periodCol),
        roleCells: column(roleCol),
        os: column(osCol).join('\n'),
        db: column(dbCol).join('\n'),
        tools: column(toolsCol).join('\n'),
        languages: column(langCol).join('\n'),
        workflow: {
          for (final e in workflowCols.entries)
            if (column(e.key).any(_isChecked)) e.value: true,
        },
      ));
    }
    return result;
  }
}

class _SheetProject {
  final String name;
  final String summary;
  final List<String> period;
  final List<String> roleCells;
  final String os, db, tools, languages;
  final Map<String, bool> workflow;

  _SheetProject({
    required this.name,
    required this.summary,
    required this.period,
    required this.roleCells,
    required this.os,
    required this.db,
    required this.tools,
    required this.languages,
    required this.workflow,
  });

  bool get isPrivate => ExcelTexts.privateMarkers.any(name.contains);

  Map<String, Object?> toMap() {
    final categories = <String, List<String>>{for (final k in _listKeys) k: []};
    void add(String key, String item) {
      // 同じもの（表記ゆれ・AWS などの先頭の違いを含む）は 1 つだけ
      final list = categories[key]!;
      final k = skillKey(item, category: key);
      if (!list.any((e) => skillKey(e, category: key) == k)) list.add(item);
    }

    // セルの中の見出し（「AWS Service;」「使用言語：」など）で分類を決める。
    // 見出しのない FW・MW ツール等・使用言語は、知っている名前なら各分類へ、知らなければ tools / skills
    for (final (mode, item) in [
      ..._cellItems(os, 'server_os'),
      ..._cellItems(db, 'db'),
      ..._cellItems(tools, _asTool),
      ..._cellItems(languages, _asLanguage),
    ]) {
      // サーバ OS・DB は括弧の補足も残す（Linux（CentOS）など）。ほかは外す（Flutter（Flutter Web）→ Flutter）
      final base = mode == 'server_os' || mode == 'db' ? item.trim() : _withoutNotes(item);
      if (base.isEmpty || _isNone(base)) continue;
      if (mode == _asTool || mode == _asLanguage) {
        final known = classifyTech(base);
        if (known != null) {
          add(known.$1, base);
          if (known.$2 case final cloud?) add('cloud_platforms', cloud);
        } else {
          add(mode == _asLanguage ? 'skills' : 'tools', base);
        }
      } else {
        add(mode, base);
        if (_cloudOf[mode] case final cloud?) add('cloud_platforms', cloud);
      }
    }

    final dates = _periodOf(period);
    final link = _url.firstMatch(summary)?.group(0) ?? '';
    final roleScale = roleAndScaleOf(roleCells);

    return {
      'title': _cleanTitle(name),
      'description': _descriptionOf(summary),
      if (summary.isNotEmpty) 'details': summary,
      'role': roleScale.role,
      'scale': roleScale.scale,
      for (final k in _listKeys)
        k: categories[k]!.isEmpty ? [ExcelTexts.notUsed] : categories[k]!,
      if (dates != null) 'period': dates,
      'link': link,
      if (!isPrivate) 'workflow': {for (final k in _workflowKeys) k: workflow[k] ?? false},
    };
  }
}

const _listKeys = [
  'server_os', 'db', 'tools', 'backend_frameworks', 'frontend_frameworks', 'ui_frameworks',
  'testing_frameworks', 'cloud_platforms', 'aws_services', 'azure_services', 'gcp_services',
  'container', 'container_orchestration', 'ai_services', 'skills',
];

/// 見出しのない項目の読み方（知っている名前なら各分類へ。知らなければ tools / skills）
const _asTool = '_tool';
const _asLanguage = '_language';

/// クラウドのサービスの分類 → あわせて cloud_platforms に足すクラウド
const _cloudOf = {
  'aws_services': 'AWS',
  'azure_services': 'Microsoft Azure',
  'gcp_services': 'Google Cloud',
};

/// セルの中の見出し（「AWS Service;」「使用言語：」「AI：」など）→ 分類（_listKeys のどれか、または _asTool / _asLanguage）
/// わからない見出しは null
String? _modeOfLabel(String label) {
  final l = toHalfWidth(label).toUpperCase();
  bool word(String w) => RegExp('(^|[^A-Z])$w([^A-Z]|\$)').hasMatch(l);

  if (l.contains('AWS') || l.contains('AMAZON')) return 'aws_services';
  if (l.contains('AZURE')) return 'azure_services';
  if (word('GCP') || l.contains('GOOGLE CLOUD')) return 'gcp_services';
  if (word('AI') || l.contains('生成AI')) return 'ai_services';
  if (l.contains('オーケストレーション') || l.contains('ORCHESTRATION')) return 'container_orchestration';
  if (l.contains('コンテナ') || l.contains('CONTAINER')) return 'container';
  if (l.contains('クラウド') || l.contains('CLOUD')) return 'cloud_platforms';
  if (l.contains('テスト') || l.contains('TEST')) return 'testing_frameworks';
  if (l.contains('バックエンド') || l.contains('BACKEND')) return 'backend_frameworks';
  if (l.contains('フロントエンド') || l.contains('FRONTEND')) return 'frontend_frameworks';
  if (word('UI')) return 'ui_frameworks';
  if (l.contains('言語') || l.contains('LANGUAGE')) return _asLanguage;
  if (word('DB') || l.contains('データベース') || l.contains('DATABASE')) return 'db';
  if (word('OS') || l.contains('サーバ') || l.contains('SERVER')) return 'server_os';
  if (word('FW') || word('MW') || l.contains('ツール') || l.contains('TOOL') ||
      l.contains('ライブラリ') || l.contains('技術') || l.contains('フレームワーク')) {
    return _asTool;
  }
  return null;
}

/// セルの中の「見出し：値」「見出し; 値」（見出しに括弧を含まない）
final _cellLabel = RegExp(r'^([^：:；;（）()]{1,30}?)\s*([：:；;])\s*(.*)$');

/// セルの文字を（分類, 項目）に分ける（1 行 1 項目。「、」「,」「;」「 / 」でも分ける。行頭の「- 」「・」は外す）
/// - 「見出し：」の行があれば、次の見出しか、項目のあとの空行まではその分類として読む（後ろに値が続いていればそれも読む）
/// - 「;」で区切られた行は、前がわかる見出しのときだけ見出しとみなす（「Git; GitHub」は 2 つの項目）
List<(String, String)> _cellItems(String text, String initial) {
  final result = <(String, String)>[];
  var mode = initial;
  var readSinceHeading = false; // 見出しのあとに項目を読んだか
  for (final raw in text.split('\n')) {
    var line = toHalfWidth(raw).trim();
    if (line.isEmpty) {
      // 見出しの下の項目のあとの空行で、見出しの効き目は終わり（列のはじめの読み方に戻す）
      if (readSinceHeading) mode = initial;
      readSinceHeading = false;
      continue;
    }
    if (_url.hasMatch(line)) continue;
    if (!_bulletHead.hasMatch(line)) {
      final m = _cellLabel.firstMatch(line);
      if (m != null) {
        final labelMode = _modeOfLabel(m.group(1)!);
        final semicolon = m.group(2) == ';';
        if (labelMode != null || !semicolon) {
          if (labelMode != null) mode = labelMode;
          readSinceHeading = false;
          line = m.group(3)!.trim();
          if (line.isEmpty) continue;
        }
      }
    }
    for (final item in _splitItems(line)) {
      if (!_isNone(item)) result.add((mode, item));
    }
    readSinceHeading = true;
  }
  return result;
}

final _bulletHead = RegExp(r'^[-・•*]\s*');

/// 「、」「,」「，」「;」と、前後に空白のある「/」で分ける（括弧の中では分けない）
List<String> _splitItems(String text) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '（' || ch == '(') depth++;
    if ((ch == '）' || ch == ')') && depth > 0) depth--;
    final slash = (ch == '/' || ch == '／') &&
        i > 0 &&
        i + 1 < text.length &&
        text[i - 1] == ' ' &&
        text[i + 1] == ' ';
    if (depth == 0 && (ch == '、' || ch == ',' || ch == '，' || ch == ';' || ch == '；' || slash)) {
      parts.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  parts.add(buffer.toString());
  return [
    for (final p in parts)
      if (p.trim().replaceFirst(_bulletHead, '').trim() case final s when s.isNotEmpty) s,
  ];
}

/// 「なし」「利用なし」「-」など、使っていないことを表す値
bool _isNone(String item) {
  final s = item.trim();
  return s.startsWith('なし') ||
      s.startsWith('無し') ||
      s.startsWith(ExcelTexts.notUsed) ||
      const {'-', '－', 'ー', '―'}.contains(s);
}

/// 「（補足）」を外す（例：Flutter（Flutter Web）→ Flutter）
String _withoutNotes(String item) {
  final note = RegExp(r'\s*[（(][^（）()]*[）)]');
  var s = item;
  while (note.hasMatch(s)) {
    s = s.replaceAll(note, '');
  }
  return s.trim();
}

/// 作業工程の列が「担当した」になっているか（●・○・✓ など。「-」「×」は担当なし）
bool _isChecked(String v) {
  final s = v.trim();
  return s.isNotEmpty &&
      !const {'-', '－', 'ー', '―', '×', '✕', 'x', 'X', 'FALSE', '0'}.contains(s);
}

final _url = RegExp(r'https?://[^\s　）)」]+');

/// プロジェクト名から「【プライベート】」「（個人開発）」などの印を外す
String _cleanTitle(String name) {
  final markers = ExcelTexts.privateMarkers.join('|');
  final cleaned = name
      .replaceAll(RegExp('[【\\[［(（]\\s*(?:$markers)[^】\\]］)）]*[】\\]］)）]'), '')
      .trim();
  return cleaned.isEmpty ? name.trim() : cleaned;
}

/// 業務概要の「概要：」の最初の 1 行（なければ最初の行）
String _descriptionOf(String summary) {
  final lines =
      summary.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  String clean(String l) =>
      l.replaceFirst(RegExp(r'^(?:[①-⑳]|\d+[.．)）]|[-・•*])\s*'), '').trim();

  for (var i = 0; i < lines.length; i++) {
    final m = _labelValue.firstMatch(lines[i]);
    if (m == null || !m.group(1)!.contains('概要')) continue;
    final rest = m.group(2)!.trim();
    if (rest.isNotEmpty) return clean(rest);
    if (i + 1 < lines.length) return clean(lines[i + 1]);
  }
  for (final l in lines) {
    // 見出しだけの行（「担当業務：」など）は飛ばす
    if (_labelValue.firstMatch(l)?.group(2)?.trim().isEmpty ?? false) continue;
    return clean(l);
  }
  return '';
}

final _ongoing = RegExp(r'現在|継続|present', caseSensitive: false);
final _yearMonth = RegExp(r'(\d{4})\s*[/\-.年]\s*(\d{1,2})(?!\d)');

/// 期間の列（「2019/7」「↓」「2019/12」「（6ヶ月）」「2020/03～2020/１０」など）から [開始, 終了]
/// 全角の数字も読む。終わりが書かれていなければ進行中（現在）とする
List<String>? _periodOf(List<String> cells) {
  final found = <String>[];
  for (final v in cells) {
    final s = toHalfWidth(v).trim();
    var hit = false;
    for (final m in _yearMonth.allMatches(s)) {
      final month = int.parse(m.group(2)!);
      if (month < 1 || month > 12) continue;
      found.add('${m.group(1)}-${'$month'.padLeft(2, '0')}');
      hit = true;
    }
    if (_ongoing.hasMatch(s)) {
      found.add(ExcelTexts.periodOngoing);
      hit = true;
    }
    if (hit) continue;
    // 日付の書式のセル（Excel の日付は 1899-12-30 からの日数。小さい数は「6（ヶ月）」などなので除く）
    final serial = double.tryParse(s);
    if (serial != null && serial > 20000 && serial < 2958466) {
      final d = DateTime.utc(1899, 12, 30).add(Duration(days: serial.floor()));
      found.add('${d.year}-${'${d.month}'.padLeft(2, '0')}');
    }
  }
  if (found.isEmpty || found.first == ExcelTexts.periodOngoing) return null;
  return [found.first, found.length > 1 ? found[1] : ExcelTexts.periodOngoing];
}

/// 空白・改行を除いた文字（見出しを探すとき用）
String _compact(String s) => s.replaceAll(RegExp(r'\s'), '');

/// 「氏名」などの見出しの右にある最初の値
String? _rightOf(XlsxSheet sheet, String label) {
  final cell = sheet.cells.where((c) => _compact(c.value) == label).firstOrNull;
  if (cell == null) return null;
  final row = sheet.rows[cell.row]!;
  final cols = row.keys.where((c) => c > cell.col).toList()..sort();
  return cols.isEmpty ? '' : row[cols.first]!.trim();
}
