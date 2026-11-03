// tool/run.dart
//
// プロフィール YAML を指定して起動する
//
//   dart run tool/run.dart my_profile.yaml          … my_profile.yaml の内容で Home / About を表示
//   dart run tool/run.dart                          … 起動後に「あなたのことを教えてください」を表示
//   dart run tool/run.dart my_profile.yaml --release … 2 つ目以降の引数は flutter run にそのまま渡す
//
// ※ `flutter run -d chrome my_profile.yaml` のように flutter run へ直接 YAML を渡すことはできない
//   （flutter run の引数は「起動する Dart ファイル」として扱われるため）。そのためこのスクリプトを使う。
//
// 仕組み：指定した YAML を assets/profile/profile.yaml にコピーし、
//        --dart-define=PROFILE_FROM_ARG=true を付けて flutter run -d chrome を実行する。
//        アプリはこの印があるときだけ assets/profile/profile.yaml を読む
//        （印なしで起動すると、前回コピーしたファイルが残っていても使わない）。
import 'dart:io';
import 'package:yaml/yaml.dart';

const _profileAsset = 'assets/profile/profile.yaml';

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
    if (yamlPath == null && !a.startsWith('-') && (lower.endsWith('.yaml') || lower.endsWith('.yml'))) {
      yamlPath = a;
    } else {
      passThrough.add(a);
    }
  }

  final flutterArgs = ['run', '-d', 'chrome'];

  if (yamlPath != null) {
    final src = File(yamlPath);
    if (!src.existsSync()) {
      stderr.writeln('YAML ファイルが見つかりません: $yamlPath');
      exit(66);
    }
    // 起動前に、プロフィールの形になっているかを軽く確かめる（詳しい確認はアプリ側でも行う）
    try {
      final doc = loadYaml(src.readAsStringSync());
      if (doc is! YamlMap || doc['home'] is! YamlMap || doc['about'] is! YamlMap) {
        stderr.writeln('プロフィールの形式ではありません（home: と about: が必要です）: $yamlPath');
        stderr.writeln('ひな形：assets/data/format_profile.yaml');
        exit(65);
      }
    } on YamlException catch (e) {
      stderr.writeln('YAML の書き方に誤りがあります: $e');
      exit(65);
    }

    final dest = File(_profileAsset);
    dest.parent.createSync(recursive: true);
    src.copySync(dest.path);
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
