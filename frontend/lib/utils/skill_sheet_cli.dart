// lib/utils/skill_sheet_cli.dart
//
// 見る人向けのスキルシートをコマンドで作る（bin/skill_sheet.dart の中身。テストできるようにここに置く）
//
//   skill_sheet --format pdf|xlsx --template format_skill_sheet.xlsx [--font ipagp.ttf] < 入力.json > 出力
//
// 入力（標準入力の JSON）：{ "data": 公開ページのデータ（API の形）, "today": "YYYY-MM-DD"（作成日。なければ今日） }
// 出力（標準出力）：Excel か PDF のバイト列。PDF には --font が要る
// 失敗したら、理由を 1 行で返し、終わりの数字は 2（使い方・入力の誤り）
// services/excel-fastapi が dart compile exe したものを呼ぶ。Flutter に依存しない。
import 'dart:convert';
import 'dart:typed_data';

import 'skill_sheet_data.dart';

/// 結果：終わりの数字（0 は成功）・出力のバイト列・失敗の理由
typedef SkillSheetCliResult = ({int exitCode, Uint8List output, String error});

const String skillSheetCliUsage =
    '使い方：skill_sheet --format pdf|xlsx --template テンプレート.xlsx [--font フォント.ttf] < 入力.json';

SkillSheetCliResult _fail(String message) => (exitCode: 2, output: Uint8List(0), error: message);

/// [args] と標準入力の中身から作る。ファイルは [readFile] で読む（テストでは偽物）
Future<SkillSheetCliResult> runSkillSheetCli(
  List<String> args,
  List<int> input, {
  required Uint8List Function(String path) readFile,
}) async {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final key = args[i];
    if (!key.startsWith('--') || i + 1 >= args.length) return _fail(skillSheetCliUsage);
    options[key.substring(2)] = args[++i];
  }
  final format = options['format'];
  final templatePath = options['template'];
  if ((format != 'pdf' && format != 'xlsx') || templatePath == null) return _fail(skillSheetCliUsage);
  if (format == 'pdf' && options['font'] == null) return _fail('PDF には --font が要ります');

  final Object? json;
  try {
    json = jsonDecode(utf8.decode(input));
  } on FormatException {
    return _fail('入力が JSON として読めません');
  }
  if (json is! Map || json['data'] is! Map) return _fail('入力は { "data": 公開ページのデータ } の形にしてください');
  final todayText = json['today'];
  final today = todayText is String ? DateTime.tryParse(todayText) : null;
  if (todayText != null && today == null) return _fail('today は YYYY-MM-DD の形にしてください');

  final Uint8List template;
  final Uint8List? font;
  try {
    template = readFile(templatePath);
    font = format == 'pdf' ? readFile(options['font']!) : null;
  } catch (e) {
    return _fail('ファイルを読めません：$e');
  }

  final data = publicSkillSheetData(Map<String, dynamic>.from(json['data'] as Map));
  final output = await buildSkillSheet(
    template,
    data,
    font: font == null ? null : ByteData.sublistView(font),
    today: today,
  );
  return (exitCode: 0, output: output, error: '');
}
