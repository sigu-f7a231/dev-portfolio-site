// lib/utils/skill_sheet_writer.dart
//
// スキルシート（Excel のテンプレート assets/data/format_skill_sheet.xlsx）に、今のプロフィールと
// Work / Private のプロジェクトを書き込む（ヘッダーの［ダウンロード］→ Excel / PDF）
// - テンプレートの書式（罫線・塗り・文字・結合・列幅・行の高さ・ページ設定）は変えず、セルの値だけを書き換える
// - 書き込むところ：氏名・過去 / 直近の開発経験と主な技術・作成日（今日）・プロジェクト（No.・期間・名前・業務概要・
//   役割 / 規模・サーバ OS・DB・FW・MW ツール等・使用言語・作業工程）
// - ふりがな・性別・年齢・生年月日・国籍・配偶者・最寄駅・学歴：プロフィールの sheet（読み込んだ Excel に書かれていたもの）を
//   そのまま書く。書かれていない項目は空にする。生年月日が読めれば、年齢は出力した日の年齢（テンプレートと同じ数式）
// - プロジェクトは 1 件目の枠（行・結合・書式・作業工程の選択肢）を件数分複製する（Work → Private の順）。
//   文章が枠に入りきらないときだけ、枠の最後の行を高くする
// - 書き込んだものは、このサイトの「Excel を選択」でそのまま読み込める形にしてある（Private の名前には【個人開発】を付ける）
//
// Flutter に依存しない。
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../constants/app_texts.dart';
import '../models/profile.dart';
import 'skill_sheet.dart';
import 'xlsx_layout.dart';

/// 書き込む中身
class SkillSheetData {
  final String name;

  /// 「過去の開発経験 … 主な使用技術・開発環境 … 直近の開発経験 …」の文章（experienceTextOf で作る）
  final String experience;

  /// YAML と同じ形のプロジェクト（title / description / details / link / period / 各技術 / workflow）
  final List<Map<String, dynamic>> work;
  final List<Map<String, dynamic>> private;

  /// ふりがな・性別・年齢・生年月日・国籍・配偶者・最寄駅・学歴（Profile.sheet。キーは ExcelTexts.sheetLabels）
  final Map<String, String> sheet;

  const SkillSheetData({
    required this.name,
    required this.experience,
    required this.work,
    required this.private,
    this.sheet = const {},
  });
}

/// プロフィールから、スキルシートの「開発経験」のセルの文章を作る（テンプレートと同じ書き方）
String experienceTextOf(Profile p) {
  String block(String heading, String lines, Map<String, List<String>> tech) {
    final b = StringBuffer(heading);
    if (lines.trim().isNotEmpty) b.write('\n\n${lines.trim()}');
    if (tech.isNotEmpty) {
      b.write('\n\n${SkillSheetTexts.techHeading}\n\n');
      b.write([for (final e in tech.entries) '${e.key}：${e.value.join('、')}'].join('\n'));
    }
    return b.toString();
  }

  final parts = [
    if (p.past.isNotEmpty || p.pastTech.isNotEmpty)
      block(SkillSheetTexts.pastHeading, p.past, p.pastTech),
    if (p.recent.isNotEmpty || p.recentTech.isNotEmpty)
      block(SkillSheetTexts.recentHeading, p.recent, p.recentTech),
  ];
  // 開発経験を書いていないプロフィール（YAML で作ったものなど）は、自己紹介と得意な領域を直近の経験として書く
  if (parts.isEmpty) {
    final lines = [
      p.intro,
      if (p.domains.isNotEmpty) '${AboutContent.domainsLabel}：${p.domains.join('、')}',
    ].join('\n');
    parts.add(block(SkillSheetTexts.recentHeading, lines, const {}));
  }
  return parts.join('\n\n\n');
}

/// テンプレートに書き込んだ .xlsx を返す
Uint8List fillSkillSheet(Uint8List template, SkillSheetData data, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final archive = ZipDecoder().decodeBytes(template);
  final sheetPath = firstSheetPath(archive);
  final layout = readXlsxLayout(template);
  final doc = XmlDocument.parse(utf8.decode(archive.findFile(sheetPath)!.content));

  final writer = _SheetWriter(doc, layout);
  writer.write(data, now);

  final xml = utf8.encode(doc.toXmlString());
  final out = Archive();
  for (final f in archive.files) {
    if (!f.isFile) continue;
    if (f.name == sheetPath) {
      out.addFile(ArchiveFile(f.name, xml.length, xml));
    } else {
      final bytes = f.content;
      out.addFile(ArchiveFile(f.name, bytes.length, bytes));
    }
  }
  return Uint8List.fromList(ZipEncoder().encode(out));
}

// ============================================================
// 書き込み
// ============================================================
String _colName(int c) {
  var n = c;
  var s = '';
  while (n > 0) {
    final m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

String _ref(int r, int c) => '${_colName(c)}$r';

String _compact(String s) => s.replaceAll(RegExp(r'\s'), '');

const _notUsed = '利用なし';

/// 作業工程の列見出し（先頭一致）→ workflow のキー（skill_sheet.dart と同じ）
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

class _SheetWriter {
  final XmlDocument doc;
  final XlsxLayout layout;
  late final XmlElement sheetData =
      doc.rootElement.childElements.firstWhere((e) => e.name.local == 'sheetData');
  late final String ns = doc.rootElement.name.namespaceUri ?? '';

  _SheetWriter(this.doc, this.layout);

  Map<int, XmlElement> get _rows => {
        for (final r in sheetData.childElements.where((e) => e.name.local == 'row'))
          int.parse(r.getAttribute('r')!): r,
      };

  /// 見出しの文字（空白を除いて）で探す
  (int, int)? _find(bool Function(String text) test) {
    final keys = layout.cells.keys.toList()..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    for (final k in keys) {
      if (test(_compact(layout.cells[k]!.value))) return k;
    }
    return null;
  }

  XmlElement? _cell(XmlElement row, int r, int c) {
    final ref = _ref(r, c);
    return row.childElements
        .where((e) => e.name.local == 'c' && e.getAttribute('r') == ref)
        .firstOrNull;
  }

  /// セルに文字を入れる（書式 s はそのまま。共有文字列ではなくセルの中に書く）。空なら値を消す
  void _set(XmlElement row, int r, int c, String text) {
    var cell = _cell(row, r, c);
    if (cell == null) {
      // 列の順に並べたまま、足りないセルを足す
      cell = XmlElement(XmlName('c'), [XmlAttribute(XmlName('r'), _ref(r, c))]);
      final after = row.childElements
          .where((e) => e.name.local == 'c' && (parseCellRef(e.getAttribute('r') ?? '')?.$2 ?? 0) > c)
          .firstOrNull;
      if (after != null) {
        after.parent!.children.insert(after.parent!.children.indexOf(after), cell);
      } else {
        row.children.add(cell);
      }
    }
    cell.removeAttribute('t');
    cell.children.clear();
    if (text.isEmpty) return;
    cell.setAttribute('t', 'inlineStr');
    cell.children.add(XmlElement(XmlName('is'), [], [
      XmlElement(XmlName('t'), [XmlAttribute(XmlName('space', 'xml'), 'preserve')], [XmlText(text)]),
    ]));
  }

  /// 数式のセルの計算結果だけを変える（作成日の年・月・日）
  void _setCached(XmlElement row, int r, int c, String value) {
    final cell = _cell(row, r, c);
    final v = cell?.childElements.where((e) => e.name.local == 'v').firstOrNull;
    if (v != null) {
      v.children
        ..clear()
        ..add(XmlText(value));
    }
  }

  void write(SkillSheetData data, DateTime now) {
    final rows = _rows;

    // ---------- 作成日（数式 YEAR / MONTH / DAY(TODAY()) の計算結果を今日に） ----------
    for (final e in layout.cells.entries) {
      final (r, c) = e.key;
      final row = rows[r];
      if (row == null) continue;
      final f = _cell(row, r, c)?.childElements.where((x) => x.name.local == 'f').firstOrNull?.innerText;
      if (f == null) continue;
      final upper = f.toUpperCase().replaceAll(' ', '');
      if (upper == 'YEAR(TODAY())') _setCached(row, r, c, '${now.year}');
      if (upper == 'MONTH(TODAY())') _setCached(row, r, c, '${now.month}');
      if (upper == 'DAY(TODAY())') _setCached(row, r, c, '${now.day}');
    }

    // ---------- 氏名（「氏名」の右のセル） ----------
    final nameLabel = _find((t) => t == SkillSheetTexts.labelName);
    if (nameLabel != null && data.name.isNotEmpty) {
      final (r, c) = nameLabel;
      final right = (layout.cells.keys.where((k) => k.$1 == r && k.$2 > c).toList()
            ..sort((a, b) => a.$2 - b.$2))
          .firstOrNull;
      // 「氏名」のセルの結合の右隣
      final labelEnd = layout.merges.where((m) => m.contains(r, c)).firstOrNull?.c2 ?? c;
      final target = right != null && right.$2 > labelEnd ? right.$2 : labelEnd + 1;
      _set(rows[r]!, r, target, data.name);
    }

    // ---------- ふりがな・性別・年齢・生年月日・国籍・配偶者・最寄駅・学歴 ----------
    _writeSheetInfo(data.sheet, now);

    // ---------- 開発経験 ----------
    final exp = _find((t) => t.contains(SkillSheetTexts.pastHeading) || t.contains(SkillSheetTexts.recentHeading));
    if (exp != null && data.experience.isNotEmpty) {
      _set(rows[exp.$1]!, exp.$1, exp.$2, data.experience);
    }

    _writeProjects(data);
  }

  /// 見出しのセル（結合していればその範囲）の右隣のセル
  (int, int)? _rightOfLabel(String label) {
    final at = _find((t) => t == label);
    if (at == null) return null;
    final (r, c) = at;
    final labelEnd = layout.merges.where((m) => m.contains(r, c)).firstOrNull?.c2 ?? c;
    return (r, labelEnd + 1);
  }

  XmlElement _rowOf(int r) {
    final rows = _rows;
    if (rows[r] case final row?) return row;
    // 行がなければ番号の順に足す
    final row = XmlElement(XmlName('row'), [XmlAttribute(XmlName('r'), '$r')]);
    final after = rows.entries.where((e) => e.key > r).map((e) => e.value).firstOrNull;
    if (after != null) {
      sheetData.children.insert(sheetData.children.indexOf(after), row);
    } else {
      sheetData.children.add(row);
    }
    return row;
  }

  /// セルを数式にする（[cached] は Excel が開くまでの表示・PDF に使う計算結果）
  void _setFormula(int r, int c, String formula, String cached, {required bool isText}) {
    final row = _rowOf(r);
    _set(row, r, c, ''); // セルを用意して中身を消す（書式 s はそのまま）
    final cell = _cell(row, r, c)!;
    if (isText) cell.setAttribute('t', 'str');
    cell.children
      ..add(XmlElement(XmlName('f'), [], [XmlText(formula)]))
      ..add(XmlElement(XmlName('v'), [], [XmlText(cached)]));
  }

  void _writeSheetInfo(Map<String, String> info, DateTime now) {
    final birthday = parseSheetDate(info['birthday'] ?? '');
    for (final e in ExcelTexts.sheetLabels.entries) {
      final at = _rightOfLabel(e.value);
      if (at == null) continue;
      final (r, c) = at;
      final value = info[e.key] ?? '';
      if (birthday != null && e.key == 'birthday') {
        // テンプレートと同じ数式（"1990"&"年"&"04"&"月"&"01"&"日"）
        final (y, m, d) = birthday;
        final mm = '$m'.padLeft(2, '0'), dd = '$d'.padLeft(2, '0');
        _setFormula(r, c, '"$y"&"年"&"$mm"&"月"&"$dd"&"日"', sheetDateText(y, m, d), isText: true);
      } else if (birthday != null && e.key == 'age') {
        // 開いた日の年齢になる数式（テンプレートと同じ DATEDIF）。表示は出力した日の年齢
        final (y, m, d) = birthday;
        var age = now.year - y;
        if (now.month < m || (now.month == m && now.day < d)) age--;
        _setFormula(r, c, 'DATEDIF(DATE($y,$m,$d),TODAY(),"Y")', '$age', isText: false);
      } else {
        _set(_rowOf(r), r, c, value);
      }
    }
  }

  void _writeProjects(SkillSheetData data) {
    final header = _find((t) => t.startsWith(SkillSheetTexts.headerProjectName));
    if (header == null) return;
    final headerRow = header.$1;
    final nameCol = header.$2;

    int? colOf(bool Function(String) test) {
      for (final e in layout.cells.entries) {
        if (e.key.$1 == headerRow && e.key.$2 != nameCol && test(_compact(e.value.value))) return e.key.$2;
      }
      return null;
    }

    final noCol = colOf((t) => t.toLowerCase().startsWith('no'));
    final periodCol = colOf((t) => t.contains('期間'));
    final roleCol = colOf((t) => t.contains('役割') || t.contains('規模'));
    final osCol = colOf((t) => t.contains('サーバ') || t.endsWith('OS'));
    final toolsCol = colOf((t) => t.contains('FW') || t.contains('ツール'));
    final langCol = colOf((t) => t.contains('言語'));
    final dbCol = colOf((t) => t == 'DB' || t.contains('データベース'));
    final workflowCols = <String, int>{};
    for (final e in layout.cells.entries) {
      if (e.key.$1 != headerRow && e.key.$1 != headerRow + 1) continue;
      final t = _compact(e.value.value);
      for (final h in _workflowHeadings.entries) {
        if (t.startsWith(h.key)) {
          workflowCols.putIfAbsent(h.value, () => e.key.$2);
          break;
        }
      }
    }
    if (noCol == null) return;

    // テンプレートのプロジェクトの枠：No. に値がある行から。1 件目を複製の元にする
    final firstRow = headerRow + (workflowCols.isEmpty ? 1 : 2);
    final starts = (layout.cells.keys
            .where((k) => k.$2 == noCol && k.$1 >= firstRow && layout.cells[k]!.value.trim().isNotEmpty)
            .map((k) => k.$1)
            .toSet()
            .toList()
          ..sort());
    if (starts.isEmpty) return;
    final protoStart = starts.first;
    final protoEnd = starts.length > 1
        ? starts[1] - 1
        : layout.merges.where((m) => m.r1 >= protoStart).fold(protoStart, (a, m) => m.r2 > a ? m.r2 : a);
    // テンプレートの枠が終わる行（最後の枠の結合の下端）
    final regionEnd = layout.merges
        .where((m) => m.r1 >= protoStart)
        .fold(protoEnd, (a, m) => m.r2 > a ? m.r2 : a);
    final blockSize = protoEnd - protoStart + 1;
    _protoBase = protoStart;

    final projects = [
      for (final p in data.work) (p, false),
      for (final p in data.private) (p, true),
    ];
    final delta = projects.length * blockSize - (regionEnd - protoStart + 1);

    final rows = _rows;
    final protoRows = [for (var r = protoStart; r <= protoEnd; r++) rows[r]];
    final protoMerges = layout.merges.where((m) => m.r1 >= protoStart && m.r2 <= protoEnd).toList();

    // ---------- 行：テンプレートの枠を外し、件数分の枠を入れ、後ろの行をずらす ----------
    final anchor = rows.entries.where((e) => e.key > regionEnd).map((e) => e.value).firstOrNull;
    for (var r = protoStart; r <= regionEnd; r++) {
      rows[r]?.remove();
    }
    for (final e in rows.entries.where((e) => e.key > regionEnd)) {
      _moveRow(e.value, e.key + delta);
    }

    final newRows = <XmlElement>[];
    for (var i = 0; i < projects.length; i++) {
      final base = protoStart + i * blockSize;
      for (var k = 0; k < blockSize; k++) {
        final proto = protoRows[k];
        final row = proto == null
            ? XmlElement(XmlName('row'), [XmlAttribute(XmlName('r'), '${base + k}')])
            : proto.copy();
        _moveRow(row, base + k);
        newRows.add(row);
      }
      _fillBlock(newRows.sublist(i * blockSize), base, blockSize, projects[i].$1, projects[i].$2, i + 1,
          noCol: noCol,
          periodCol: periodCol,
          roleCol: roleCol,
          nameCol: nameCol,
          osCol: osCol,
          dbCol: dbCol,
          toolsCol: toolsCol,
          langCol: langCol,
          workflowCols: workflowCols);
    }
    if (anchor != null) {
      final i = sheetData.children.indexOf(anchor);
      sheetData.children.insertAll(i, newRows);
    } else {
      sheetData.children.addAll(newRows);
    }

    // ---------- 結合：テンプレートの枠の分を外し、件数分を足し、後ろをずらす ----------
    final mergeCells = doc.rootElement.childElements.where((e) => e.name.local == 'mergeCells').firstOrNull;
    if (mergeCells != null) {
      final keep = <String>[];
      for (final m in layout.merges) {
        if (m.r1 >= protoStart && m.r1 <= regionEnd) continue;
        final shift = m.r1 > regionEnd ? delta : 0;
        keep.add('${_ref(m.r1 + shift, m.c1)}:${_ref(m.r2 + shift, m.c2)}');
      }
      for (var i = 0; i < projects.length; i++) {
        final off = i * blockSize;
        for (final m in protoMerges) {
          keep.add('${_ref(m.r1 + off, m.c1)}:${_ref(m.r2 + off, m.c2)}');
        }
      }
      mergeCells.children.clear();
      for (final ref in keep) {
        mergeCells.children.add(XmlElement(XmlName('mergeCell'), [XmlAttribute(XmlName('ref'), ref)]));
      }
      mergeCells.setAttribute('count', '${keep.length}');
    }

    // ---------- 作業工程の選択肢（●）：各枠の 1 行目に ----------
    if (workflowCols.isNotEmpty) {
      final c1 = workflowCols.values.reduce((a, b) => a < b ? a : b);
      final c2 = workflowCols.values.reduce((a, b) => a > b ? a : b);
      for (final dv in doc.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'dataValidation')
          .toList()) {
        final sqref = dv.getAttribute('sqref') ?? '';
        final touchesBlocks = sqref.split(' ').any((part) {
          final a = parseCellRef(part.split(':').first);
          return a != null && a.$1 >= protoStart && a.$1 <= regionEnd;
        });
        if (!touchesBlocks) continue;
        if (projects.isEmpty) {
          // 案件が 0 件なら選択肢も外す（空の sqref は Excel が「修復」を出す）
          final parent = dv.parentElement;
          dv.remove();
          if (parent != null) {
            final left = parent.childElements.where((e) => e.name.local == 'dataValidation').length;
            if (left == 0) {
              parent.remove();
            } else {
              parent.setAttribute('count', '$left');
            }
          }
          continue;
        }
        dv.setAttribute('sqref', [
          for (var i = 0; i < projects.length; i++)
            '${_ref(protoStart + i * blockSize, c1)}:${_ref(protoStart + i * blockSize, c2)}',
        ].join(' '));
      }
    }

    // ---------- テンプレートのサンプルのリンク（枠の中のセルへのハイパーリンク）は外す ----------
    for (final links in doc.rootElement.childElements.where((e) => e.name.local == 'hyperlinks').toList()) {
      for (final h in links.childElements.toList()) {
        final a = parseCellRef(h.getAttribute('ref') ?? '');
        if (a != null && a.$1 >= protoStart && a.$1 <= regionEnd) h.remove();
      }
      if (links.childElements.isEmpty) links.remove();
    }
  }

  /// 行の番号を変える（セルの番地も合わせる）
  void _moveRow(XmlElement row, int newR) {
    row.setAttribute('r', '$newR');
    for (final c in row.childElements.where((e) => e.name.local == 'c')) {
      final ref = parseCellRef(c.getAttribute('r') ?? '');
      if (ref != null) c.setAttribute('r', _ref(newR, ref.$2));
    }
  }

  void _fillBlock(
    List<XmlElement> blockRows,
    int base,
    int size,
    Map<String, dynamic> p,
    bool isPrivate,
    int no, {
    required int noCol,
    required int? periodCol,
    required int? roleCol,
    required int nameCol,
    required int? osCol,
    required int? dbCol,
    required int? toolsCol,
    required int? langCol,
    required Map<String, int> workflowCols,
  }) {
    XmlElement row(int k) => blockRows[k];

    _set(row(0), base, noCol, '$no');

    // 期間：開始 ／ ↓ ／ 終了 ／（N ヶ月）
    if (periodCol != null) {
      final period = _items(p['period']);
      final start = period.isNotEmpty ? _ym(period.first) : null;
      final endRaw = period.length > 1 ? period[1] : null;
      final ongoing = endRaw != null && RegExp(r'現在|present', caseSensitive: false).hasMatch(endRaw);
      final end = endRaw == null ? null : (ongoing ? null : _ym(endRaw));
      final lines = <String>[
        if (start != null) '${start.$1}/${start.$2}' else '',
        if (start != null) '↓' else '',
        if (ongoing) AppTexts.periodNow else (end != null ? '${end.$1}/${end.$2}' : ''),
        if (start != null && (end != null || ongoing))
          SkillSheetTexts.months(_months(start, end ?? (DateTime.now().year, DateTime.now().month)))
        else
          '',
      ];
      for (var k = 0; k < size && k < lines.length; k++) {
        _set(row(k), base + k, periodCol, lines[k]);
      }
    }

    // プロジェクト名（Private は【個人開発】を付ける＝読み込み直したときも Private になる）
    var title = '${p['title'] ?? ''}'.trim();
    if (isPrivate && !ExcelTexts.privateMarkers.any(title.contains)) title = '$title${SkillSheetTexts.privateMark}';
    _set(row(0), base, nameCol, title);

    // 業務概要
    final description = '${p['description'] ?? ''}'.trim();
    final details = '${p['details'] ?? ''}'.trim();
    final link = '${p['link'] ?? ''}'.trim();
    final summary = skillSheetSummary(description, details, link);
    if (size > 1) _set(row(1), base + 1, nameCol, summary);

    List<String> list(String key) => [
          for (final v in _items(p[key]))
            if (v != _notUsed) v,
        ];
    String section(String heading, List<String> items, {bool bullets = true}) =>
        items.isEmpty ? '' : '$heading\n${items.map((e) => bullets ? '- $e' : e).join('\n')}';
    String sections(List<String> parts) => parts.where((e) => e.isNotEmpty).join('\n\n');

    // 役割・規模：テンプレートと同じく枠の 2 行目（大きいセル）に「PG」、その下に「規模：10名」
    if (roleCol != null) {
      final roles = _items(p['role']);
      final scale = '${p['scale'] ?? ''}'.trim();
      final text = [
        if (roles.isNotEmpty) roles.join(' / '),
        if (scale.isNotEmpty) '${SkillSheetTexts.scaleHeading}$scale',
      ].join('\n');
      _set(row(0), base, roleCol, '');
      if (size > 1) {
        _set(row(1), base + 1, roleCol, text);
      } else {
        _set(row(0), base, roleCol, text);
      }
    }

    if (osCol != null) {
      final os = list('server_os');
      _set(row(0), base, osCol, '${SkillSheetTexts.osHeading}\n${os.isEmpty ? SkillSheetTexts.none : os.join(' / ')}');
    }
    if (dbCol != null) {
      final db = list('db');
      _set(row(0), base, dbCol,
          db.isEmpty ? '${SkillSheetTexts.dbHeading}\n${SkillSheetTexts.none}' : section(SkillSheetTexts.dbHeading, db));
    }
    if (toolsCol != null) {
      _set(row(0), base, toolsCol, sections([
        section(SkillSheetTexts.toolsHeading, list('tools')),
        section(SkillSheetTexts.cloudHeading, list('cloud_platforms')),
        section(SkillSheetTexts.awsHeading, list('aws_services')),
        section(SkillSheetTexts.azureHeading, list('azure_services')),
        section(SkillSheetTexts.gcpHeading, list('gcp_services')),
        section(SkillSheetTexts.containerHeading, list('container')),
        section(SkillSheetTexts.orchestrationHeading, list('container_orchestration')),
        section(SkillSheetTexts.aiHeading, list('ai_services')),
      ]));
    }
    if (langCol != null) {
      _set(row(0), base, langCol, sections([
        section(SkillSheetTexts.languageHeading, list('skills')),
        section(SkillSheetTexts.frameworkHeading, [
          ...list('backend_frameworks'),
          ...list('frontend_frameworks'),
          ...list('ui_frameworks'),
          ...list('testing_frameworks'),
        ]),
      ]));
    }

    // 作業工程（Work だけ ●。Private は空）
    final workflow = p['workflow'];
    for (final e in workflowCols.entries) {
      final on = !isPrivate && workflow is Map && workflow[e.key] == true;
      _set(row(0), base, e.value, on ? SkillSheetTexts.check : '');
    }

    _fitLastRow(blockRows, base, size,
        nameCol: nameCol, roleCol: roleCol, cols: [osCol, dbCol, toolsCol, langCol]);
  }

  /// 文章が枠に入りきらないときだけ、枠の最後の行を高くする（テンプレートの高さより低くはしない）
  void _fitLastRow(List<XmlElement> blockRows, int base, int size,
      {required int nameCol, int? roleCol, required List<int?> cols}) {
    double heightOf(int r1, int r2) {
      var h = 0.0;
      for (var r = r1; r <= r2; r++) {
        final row = blockRows[r - base];
        h += double.tryParse(row.getAttribute('ht') ?? '') ?? layout.defaultRowHeight;
      }
      return h;
    }

    var extra = 0.0;
    void check(int r, int c) {
      final row = blockRows[r - base];
      final cell = _cell(row, r, c);
      if (cell == null) return;
      final text = cell.innerText;
      if (text.isEmpty) return;
      // テンプレートの結合の範囲（行は枠の中に読み替える）
      final protoR = r - base;
      final m = layout.merges
          .where((m) => m.c1 == c && m.r1 - _protoBase == protoR)
          .firstOrNull;
      final c2 = m?.c2 ?? c;
      final r2 = m == null ? r : base + (m.r2 - _protoBase);
      var width = 0.0;
      for (var x = c; x <= c2; x++) {
        width += layout.colWidthPt(x);
      }
      final style = layout.styleAt(m?.r1 ?? (_protoBase + protoR), c);
      final need = estimateTextHeight(text, width, style.fontSize);
      final have = heightOf(r, r2);
      if (need > have && need - have > extra) extra = need - have;
    }

    if (size > 1) check(base + 1, nameCol);
    if (size > 1 && roleCol != null) check(base + 1, roleCol);
    for (final c in cols) {
      if (c != null) check(base, c);
    }
    if (extra > 0) {
      final last = blockRows[size - 1];
      final h = double.tryParse(last.getAttribute('ht') ?? '') ?? layout.defaultRowHeight;
      last.setAttribute('ht', (h + extra).toStringAsFixed(2));
      last.setAttribute('customHeight', '1');
    }
  }

  /// 複製の元の枠の最初の行（_writeProjects で決める）
  int _protoBase = 0;
}

/// 業務概要のセルの文章
/// - ふつう：「概要：説明」「内容：詳細」「URL：リンク」
/// - 詳細がスキルシート（Excel）から読み込んだもの（業務概要のセル全体。「概要：」などの見出し入り）なら、詳細をそのまま書く
///   （見出しを重ねない）
/// - リンクがすでに詳細に書いてあれば、「URL：」を足さない
String skillSheetSummary(String description, String details, String link) {
  final hasLink = link.isNotEmpty && details.contains(link);
  if (_summaryLabel.hasMatch(details)) {
    return [
      details,
      if (link.isNotEmpty && !hasLink) '${SkillSheetTexts.urlHeading}\n$link',
    ].join('\n\n');
  }
  return [
    '${SkillSheetTexts.summaryHeading}\n$description',
    if (details.isNotEmpty) '${SkillSheetTexts.detailsHeading}\n$details',
    if (link.isNotEmpty && !hasLink) '${SkillSheetTexts.urlHeading}\n$link',
  ].join('\n\n');
}

/// 「概要：」の見出しの行（Excel の業務概要のセル全体が詳細に入っているかの目印）
final _summaryLabel = RegExp(r'^\s*概要\s*[：:]', multiLine: true);

/// 文章の高さ（pt）の見積もり：全角 1 文字＝文字の大きさ、半角＝その 0.55 倍として折り返し、1 行＝1.3 倍
double estimateTextHeight(String text, double widthPt, double fontSize) {
  if (widthPt <= 0) return 0;
  var lines = 0;
  for (final para in text.split('\n')) {
    var w = 0.0;
    var n = 1;
    for (final rune in para.runes) {
      final cw = (rune < 0x2E80 ? 0.55 : 1.0) * fontSize;
      if (w + cw > widthPt - 2) {
        n++;
        w = 0;
      }
      w += cw;
    }
    lines += n;
  }
  return lines * fontSize * 1.3 + 4;
}

List<String> _items(Object? v) {
  if (v is List) return [for (final e in v) '$e'.trim()].where((e) => e.isNotEmpty).toList();
  if (v is String) return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  return [];
}

(int, int)? _ym(String s) {
  final m = RegExp(r'(\d{4})\s*[-/.年]\s*(\d{1,2})').firstMatch(s);
  if (m == null) return null;
  return (int.parse(m.group(1)!), int.parse(m.group(2)!));
}

int _months((int, int) a, (int, int) b) {
  final n = (b.$1 * 12 + b.$2) - (a.$1 * 12 + a.$2) + 1;
  return n < 1 ? 1 : n;
}
