// tool/measure_skill_sheet.dart
//
// スキルシート（Excel / PDF）の作成・読み込みにかかる時間と、ファイルの大きさを測る（段階 6：ブラウザか FastAPI かを比べる材料）
//
//   dart run tool/measure_skill_sheet.dart            … Work 12・50・200 件で測る（frontend/ で）
//   dart run tool/measure_skill_sheet.dart 30 100     … 件数を指定
//
// - 中身はテンプレート（assets/data/format_skill_sheet.xlsx）のサンプルのプロジェクトを件数分複製したもの（個人の情報は使わない）
// - Dart VM で測る。ブラウザ（dart2js の JavaScript）では数倍遅くなりうるので、目安として読む（docs/plan/excel.md）
// - build/web/ があれば（flutter build web --release のあと）、main.dart.js の大きさ（gzip 後も）も出す
// Flutter に依存しない。
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dev_portfolio/data/records.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/utils/skill_sheet_pdf.dart';
import 'package:dev_portfolio/utils/skill_sheet_writer.dart';

/// [action] を [times] 回動かし、真ん中の時間（ミリ秒）と最後の結果
Future<(int, T)> _measure<T>(FutureOr<T> Function() action, {int times = 3}) async {
  final ms = <int>[];
  late T result;
  for (var i = 0; i < times; i++) {
    final watch = Stopwatch()..start();
    result = await action();
    ms.add(watch.elapsedMilliseconds);
  }
  ms.sort();
  return (ms[ms.length ~/ 2], result);
}

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(0)} KB';

Future<void> main(List<String> args) async {
  final counts = args.isEmpty ? [12, 50, 200] : args.map(int.parse).toList();
  final template = File(skillSheetTemplateAsset).readAsBytesSync();
  final font = File(skillSheetPdfFontAsset).readAsBytesSync();

  final sample = recordOfYaml(convertSkillSheet(template).yamlText!);
  final profile = Profile.parse(yamlOfRecord({
    for (final key in ['home', 'about', 'sheet']) if (sample[key] != null) key: sample[key],
  })).profile!;
  final base = Map<String, dynamic>.from((sample['work'] as List).first as Map);

  stdout.writeln('| Work の件数 | Excel を作る | PDF を作る | Excel を読む | Excel の大きさ | PDF の大きさ |');
  stdout.writeln('|---|---|---|---|---|---|');
  for (final n in counts) {
    final work = [for (var i = 0; i < n; i++) {...base, 'title': '${base['title']} ${i + 1}'}];
    final data = SkillSheetData(
      name: profile.name,
      experience: experienceTextOf(profile),
      work: work,
      private: const [],
      sheet: profile.sheet,
    );
    final (xlsxMs, xlsx) = await _measure(() => fillSkillSheet(template, data, today: DateTime(2026, 11, 6)));
    final (pdfMs, pdf) = await _measure(() => skillSheetPdf(xlsx, ByteData.sublistView(font)), times: n > 100 ? 1 : 3);
    final (readMs, _) = await _measure(() => convertSkillSheet(xlsx));
    stdout.writeln('| $n | $xlsxMs ms | $pdfMs ms | $readMs ms | ${_kb(xlsx.length)} | ${_kb(pdf.length)} |');
  }

  stdout.writeln();
  stdout.writeln('PDF のフォント（$skillSheetPdfFontAsset）：${_kb(font.length)}（PDF を作るときだけ読む）');
  final js = File('build/web/main.dart.js');
  if (js.existsSync()) {
    final bytes = js.readAsBytesSync();
    stdout.writeln('build/web/main.dart.js：${_kb(bytes.length)}（gzip 後 ${_kb(gzip.encode(bytes).length)}）');
  } else {
    stdout.writeln('build/web/main.dart.js はありません（flutter build web --release のあとに測れます）');
  }
}
