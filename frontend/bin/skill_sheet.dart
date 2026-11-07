// bin/skill_sheet.dart
//
// 見る人向けのスキルシート（Excel・PDF）をコマンドで作る。中身は lib/utils/skill_sheet_cli.dart
//   dart run bin/skill_sheet.dart --format pdf --template assets/data/format_skill_sheet.xlsx \
//     --font assets/fonts/ipagp.ttf < 入力.json > out.pdf
// services/excel-fastapi の Dockerfile が dart compile exe して、FastAPI から呼ぶ
import 'dart:io';

import 'package:dev_portfolio/utils/skill_sheet_cli.dart';

Future<void> main(List<String> args) async {
  final input = <int>[];
  await for (final chunk in stdin) {
    input.addAll(chunk);
  }
  final result = await runSkillSheetCli(args, input, readFile: (path) => File(path).readAsBytesSync());
  if (result.exitCode != 0) {
    stderr.writeln(result.error);
    exit(result.exitCode);
  }
  stdout.add(result.output);
  await stdout.flush();
}
