// tool/coverage_check.dart
//
// flutter test が書いた coverage/lcov.info を集計し、行網羅率（C0）と分岐網羅率（C1）を出す。
// 基準に届かなければ終了コード 1（CI で失敗にする）。
//
//   flutter test --coverage --branch-coverage       … lcov.info を作る（分岐の情報は --branch-coverage のときだけ）
//   dart run tool/coverage_check.dart                … 行・分岐とも 90% 以上か
//   dart run tool/coverage_check.dart --min-line 80 --min-branch 90
//   dart run tool/coverage_check.dart --top 50       … 基準に届かないファイルを 50 件まで表示（既定 30）
//
// 通っていない行・分岐の行番号は coverage/uncovered.txt に書く（--details で場所を変えられる）。
//
// 除くもの：
// - テストの VM では動かない Web 専用の実装（*_web.dart）と、runApp するだけの main.dart（_excluded）
// - 1 行だけ・一部だけ除くときは、ソースに // coverage:ignore-line、// coverage:ignore-start 〜 // coverage:ignore-end
//   （flutter test がその行を lcov.info に入れない）。除く理由をコメントに書くこと
//
// Flutter・ほかのパッケージに依存しない。
import 'dart:io';

/// 集計から除くファイル（lib/ からのパス）
final List<RegExp> _excluded = [
  RegExp(r'^lib/main\.dart$'), // runApp するだけ。Web で起動して確かめる
  RegExp(r'_web\.dart$'), // package:web を使う Web 専用の実装。テストでは *_stub.dart が使われる
];

/// すべてのファイルを読み込むだけのテスト（集計の漏れを防ぐ。--update-imports で作り直す）
const String _importsTest = 'test/all_files_loaded_test.dart';

/// pubspec.yaml の name
String get _package {
  final m = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync());
  return m?.group(1) ?? 'dev_portfolio';
}

/// 集計の対象になる lib/ のファイル（_excluded を除く）
List<String> _libFiles() => [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f.path.replaceAll('\\', '/'),
    ].where((p) => !_excluded.any((r) => r.hasMatch(p))).toList()
      ..sort();

void _writeImportsTest() {
  final files = _libFiles();
  final b = StringBuffer()
    ..writeln('// $_importsTest')
    ..writeln('//')
    ..writeln('// lib/ のすべてのファイルを読み込むだけのテスト（tool/coverage_check.dart --update-imports で作る。手で直さない）')
    ..writeln('// flutter test の網羅率は、テストから読み込まれたファイルしか数えない。')
    ..writeln('// これがないと、テストのないファイルが集計から漏れ、網羅率が実際より高く出る。')
    ..writeln('// ignore_for_file: unused_import, directives_ordering')
    ..writeln("import 'package:flutter_test/flutter_test.dart';")
    ..writeln();
  for (var i = 0; i < files.length; i++) {
    b.writeln("import 'package:$_package/${files[i].substring(4)}' as f$i;");
  }
  b
    ..writeln()
    ..writeln('void main() {')
    ..writeln("  test('lib/ のファイルをすべて読み込める（${files.length} ファイル）', () {});")
    ..writeln('}');
  File(_importsTest).writeAsStringSync(b.toString());
  stdout.writeln('$_importsTest を作りました（${files.length} ファイル）');
}

class _FileCov {
  _FileCov(this.path);
  final String path;

  /// 行番号 → 通った回数
  final Map<int, int> lines = {};

  /// 「行:ブロック:分岐」→ 通ったか
  final Map<String, bool> branches = {};

  int get lineTotal => lines.length;
  int get lineHit => lines.values.where((h) => h > 0).length;
  int get branchTotal => branches.length;
  int get branchHit => branches.values.where((b) => b).length;

  List<int> get uncoveredLines => (lines.entries.where((e) => e.value == 0).map((e) => e.key).toList())..sort();

  List<int> get uncoveredBranchLines =>
      ({for (final e in branches.entries) if (!e.value) int.parse(e.key.split(':').first)}.toList())..sort();
}

double _pct(int hit, int total) => total == 0 ? 100 : hit * 100 / total;

String _fmt(double v) => '${v.toStringAsFixed(1).padLeft(5)}%';

/// [3, 4, 5, 9] → "3-5, 9"
String _ranges(List<int> ns) {
  final out = <String>[];
  for (var i = 0; i < ns.length; i++) {
    final start = ns[i];
    var end = start;
    while (i + 1 < ns.length && ns[i + 1] == end + 1) {
      end = ns[++i];
    }
    out.add(start == end ? '$start' : '$start-$end');
  }
  return out.join(', ');
}

/// lcov の SF:（絶対パスのこともある）を lib/ からのパスにする
String _normalize(String path) {
  final p = path.replaceAll('\\', '/');
  if (p.startsWith('lib/')) return p;
  final i = p.lastIndexOf('/lib/');
  return i >= 0 ? p.substring(i + 1) : p;
}

Map<String, _FileCov> _parse(List<String> lcov) {
  final files = <String, _FileCov>{};
  _FileCov? current;
  for (final raw in lcov) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      final path = _normalize(line.substring(3));
      current = files.putIfAbsent(path, () => _FileCov(path));
    } else if (line == 'end_of_record') {
      current = null;
    } else if (current != null && line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final no = int.tryParse(parts[0]);
      final hits = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      if (no != null) current.lines[no] = (current.lines[no] ?? 0) > hits ? current.lines[no]! : hits;
    } else if (current != null && line.startsWith('BRDA:')) {
      // BRDA:行,ブロック,分岐,通った回数（通っていなければ "-"）
      final parts = line.substring(5).split(',');
      if (parts.length < 4) continue;
      final key = '${parts[0]}:${parts[1]}:${parts[2]}';
      final taken = parts[3] != '-' && (int.tryParse(parts[3]) ?? 0) > 0;
      current.branches[key] = (current.branches[key] ?? false) || taken;
    }
  }
  return files;
}

void main(List<String> args) {
  var lcovPath = 'coverage/lcov.info';
  var detailsPath = 'coverage/uncovered.txt';
  var minLine = 90.0;
  var minBranch = 90.0;
  var top = 30;

  if (args.contains('--update-imports')) {
    _writeImportsTest();
    return;
  }

  final rest = [...args];
  String valueOf(String flag) {
    if (rest.isEmpty) {
      stderr.writeln('$flag のあとに値がありません');
      exit(64);
    }
    return rest.removeAt(0);
  }

  while (rest.isNotEmpty) {
    final flag = rest.removeAt(0);
    switch (flag) {
      case '--lcov':
        lcovPath = valueOf(flag);
      case '--details':
        detailsPath = valueOf(flag);
      case '--min-line':
        minLine = double.parse(valueOf(flag));
      case '--min-branch':
        minBranch = double.parse(valueOf(flag));
      case '--min':
        minLine = minBranch = double.parse(valueOf(flag));
      case '--top':
        top = int.parse(valueOf(flag));
      default:
        stderr.writeln('知らない引数です: $flag');
        exit(64);
    }
  }

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln('$lcovPath がありません。先に flutter test --coverage --branch-coverage を実行してください');
    exit(66);
  }

  final all = _parse(file.readAsLinesSync());

  // どのテストからも読み込まれていないファイルは lcov.info に出てこない（＝集計から漏れる）。
  // _importsTest がすべてのファイルを読み込むので、そこにないファイル（新しく足したもの）を知らせる。
  // _importsTest にあるのに lcov.info にないファイルは、実行される行がない（定数・export だけ）ので数えなくてよい
  final imported = File(_importsTest).existsSync() ? File(_importsTest).readAsStringSync() : '';
  final missing = [
    for (final path in _libFiles())
      if (!all.containsKey(path) && !imported.contains("'package:$_package/${path.substring(4)}'")) path,
  ];
  final excluded = all.keys.where((p) => _excluded.any((r) => r.hasMatch(p))).toList()..sort();
  final files = [
    for (final f in all.values)
      if (f.path.startsWith('lib/') && !excluded.contains(f.path)) f,
  ]..sort((a, b) => a.path.compareTo(b.path));

  final lineTotal = files.fold(0, (s, f) => s + f.lineTotal);
  final lineHit = files.fold(0, (s, f) => s + f.lineHit);
  final branchTotal = files.fold(0, (s, f) => s + f.branchTotal);
  final branchHit = files.fold(0, (s, f) => s + f.branchHit);
  final linePct = _pct(lineHit, lineTotal);
  final branchPct = _pct(branchHit, branchTotal);

  stdout.writeln('網羅率（${files.length} ファイル。除外 ${excluded.length}: ${excluded.join(', ')}）');
  stdout.writeln('  行（C0）  ${_fmt(linePct)}  ($lineHit / $lineTotal)   基準 ${minLine.toStringAsFixed(0)}%');
  if (branchTotal == 0) {
    stdout.writeln('  分岐（C1） 情報なし … flutter test --coverage --branch-coverage で実行してください');
  } else {
    stdout.writeln('  分岐（C1）${_fmt(branchPct)}  ($branchHit / $branchTotal)   基準 ${minBranch.toStringAsFixed(0)}%');
  }

  // 基準に届かないファイル（通っていない分岐・行が多い順）
  final short = files
      .where((f) => _pct(f.branchHit, f.branchTotal) < minBranch || _pct(f.lineHit, f.lineTotal) < minLine)
      .toList()
    ..sort((a, b) {
      final byBranch = (b.branchTotal - b.branchHit).compareTo(a.branchTotal - a.branchHit);
      return byBranch != 0 ? byBranch : (b.lineTotal - b.lineHit).compareTo(a.lineTotal - a.lineHit);
    });
  if (short.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('基準に届かないファイル ${short.length} 件（通っていない分岐が多い順。上位 $top 件）');
    stdout.writeln('   分岐     行   未通過(分岐/行)  ファイル');
    for (final f in short.take(top)) {
      stdout.writeln('  ${_fmt(_pct(f.branchHit, f.branchTotal))} ${_fmt(_pct(f.lineHit, f.lineTotal))}'
          '   ${'${f.branchTotal - f.branchHit}'.padLeft(4)} / ${'${f.lineTotal - f.lineHit}'.padLeft(4)}   ${f.path}');
    }
  }

  // 通っていない場所の一覧（テストを足すときの手がかり）
  final details = StringBuffer();
  for (final f in files) {
    final lines = f.uncoveredLines;
    final branchLines = f.uncoveredBranchLines;
    if (lines.isEmpty && branchLines.isEmpty) continue;
    details.writeln('${f.path}  分岐 ${_fmt(_pct(f.branchHit, f.branchTotal))}  行 ${_fmt(_pct(f.lineHit, f.lineTotal))}');
    if (lines.isNotEmpty) details.writeln('  通っていない行: ${_ranges(lines)}');
    if (branchLines.isNotEmpty) details.writeln('  通っていない分岐のある行: ${_ranges(branchLines)}');
  }
  File(detailsPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(details.toString());
  stdout.writeln('');
  stdout.writeln('通っていない行・分岐の行番号: $detailsPath');

  if (missing.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('集計に入っていないファイル ${missing.length} 件（どのテストからも読み込まれていない）:');
    for (final p in missing) {
      stdout.writeln('  $p');
    }
    stdout.writeln('→ dart run tool/coverage_check.dart --update-imports で $_importsTest を作り直してから、もう一度テストを実行してください');
  }

  final ok = linePct >= minLine && (branchTotal == 0 || branchPct >= minBranch) && missing.isEmpty;
  if (branchTotal == 0) {
    stderr.writeln('分岐の情報がないため、分岐網羅率を確かめられません');
    exit(2);
  }
  if (!ok) {
    stderr.writeln('網羅率が基準に届いていません');
    exit(1);
  }
  stdout.writeln('基準を満たしています');
}
