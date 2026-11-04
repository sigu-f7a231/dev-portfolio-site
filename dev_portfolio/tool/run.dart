// tool/run.dart
//
// プロフィール YAML を指定して起動する
//
//   dart run tool/run.dart my_profile.yaml          … my_profile.yaml の内容で Home / About を表示
//   dart run tool/run.dart my_profile.md            … Markdown で書いたプロフィールでもよい（format_profile.md の書き方）
//   dart run tool/run.dart                          … 起動後に「あなたのことを教えてください」を表示
//   dart run tool/run.dart my_profile.yaml --release … 2 つ目以降の引数は flutter run にそのまま渡す
//
// ※ `flutter run -d chrome my_profile.yaml` のように flutter run へ直接 YAML を渡すことはできない
//   （flutter run の引数は「起動する Dart ファイル」として扱われるため）。そのためこのスクリプトを使う。
//
// 仕組み：指定した YAML（Markdown は同じ中身の JSON＝YAML として読める形に変えて）を assets/profile/profile.yaml に書き、
//        --dart-define=PROFILE_FROM_ARG=true を付けて flutter run -d chrome を実行する。
//        アプリはこの印があるときだけ assets/profile/profile.yaml を読む
//        （印なしで起動すると、前回コピーしたファイルが残っていても使わない）。
import 'dart:io';

import 'package:dev_portfolio/utils/data_format.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';
import 'package:dev_portfolio/constants/app_texts.dart';

const _profileAsset = 'assets/profile/profile.yaml';
// プロフィールに work / private も書かれていたときの書き出し先（なければ消す）
const _workAsset = 'assets/profile/work.yaml';
const _privateAsset = 'assets/profile/private.yaml';

Future<void> main(List<String> args) async {
  // dev_portfolio/ で実行する（pubspec.yaml がある場所）
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('dev_portfolio/ フォルダで実行してください（pubspec.yaml が見つかりません）');
    exit(64);
  }

  String? yamlPath;
  final passThrough = <String>[];
  for (final a in args) {
    final lower = a.toLowerCase();
    if (yamlPath == null && !a.startsWith('-') && hasAcceptedExtension(lower)) {
      yamlPath = a;
    } else {
      passThrough.add(a);
    }
  }

  final flutterArgs = ['run', '-d', 'chrome'];

  if (yamlPath != null) {
    final src = File(yamlPath);
    if (!src.existsSync()) {
      stderr.writeln('ファイルが見つかりません: $yamlPath');
      exit(66);
    }
    // 起動前に、アプリと同じ確認をする（YAML / Markdown を見分け、Markdown は YAML として読める形に変える。
    // work / private も書かれていれば、それぞれ Work / Private として確かめる）
    final bundle = readProfileBundle(src.readAsStringSync(), fileName: yamlPath);
    if (!bundle.isOk) {
      stderr.writeln('プロフィールとして読み込めません: $yamlPath');
      for (final e in bundle.errors) {
        stderr.writeln('  ・$e');
      }
      stderr.writeln('ひな形：assets/data/format_profile.yaml / format_profile.md');
      exit(65);
    }

    final dest = File(_profileAsset);
    dest.parent.createSync(recursive: true);
    dest.writeAsStringSync(bundle.profileText!);

    // Work / Private：書かれていれば書き出し、なければ前回の分を消す（サンプルが表示される）
    for (final (path, text) in [(_workAsset, bundle.workText), (_privateAsset, bundle.privateText)]) {
      final f = File(path);
      if (text != null) {
        f.writeAsStringSync(text);
      } else if (f.existsSync()) {
        f.deleteSync();
      }
    }
    final extra = BundleTexts.includes(bundle.workCount, bundle.privateCount);
    if (extra.isNotEmpty) stdout.writeln('一緒に読み込むもの: $extra');
    flutterArgs.add('--dart-define=PROFILE_FROM_ARG=true');
    stdout.writeln('プロフィール: $yamlPath を読み込んで起動します');
  } else {
    stdout.writeln('プロフィールの指定がないため、起動後に入力画面を表示します');
  }

  final process = await Process.start(
    'flutter',
    [...flutterArgs, ...passThrough],
    mode: ProcessStartMode.inheritStdio, // r（ホットリロード）などのキー操作もそのまま使える
    runInShell: true, // Windows でも flutter コマンドを見つけられるように
  );
  exit(await process.exitCode);
}
