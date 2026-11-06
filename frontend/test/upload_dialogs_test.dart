// アップロード画面（Work / Private / 最初の入力画面）の流れのテスト
// 読み込み（テキストの貼り付け）→ 形式の確認 → アップロード → 確認画面 → OK で反映
//
// 対象：
//   lib/sections/header/yaml_upload_dialog.dart（Work / Private）
//   lib/widgets/profile_setup_dialog.dart（最初の入力画面）
// ※ ファイル選択（OS のダイアログ）はテストから操作できないので、同じ確認処理を通る「テキストを貼り付け」で確かめる
//
// 実行：flutter test test/upload_dialogs_test.dart（frontend/ で）
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/header/yaml_upload_dialog.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/browser/browser.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/widgets/profile_setup_dialog.dart';

import 'test_assets.dart';

const _workYaml = '''
projects:
  - title: 貼り付けた業務
    period: [2024-04, 現在]
    workflow:
      requirements: true
''';

const _privateYaml = '''
projects:
  - title: 貼り付けた個人開発
    period: [2023-01, 2023-06]
''';

const _profileYaml = '''
home:
  name: 貼り付け 太郎
  role: エンジニア
  tagline: 紹介文
about:
  intro: 自己紹介
''';

/// 「貼り付けたテキスト（YAML）」「（Markdown）」
final _pastedYaml = AppTexts.sourceWithFormat(AppTexts.pastedTextName, AppTexts.formatYaml);
final _pastedMd = AppTexts.sourceWithFormat(AppTexts.pastedTextName, AppTexts.formatMarkdown);

void _setScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 「open」ボタンで [open] を呼ぶだけの画面
Future<void> _pumpOpener(WidgetTester tester, void Function(BuildContext) open) async {
  _setScreen(tester);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(onPressed: () => open(context), child: const Text('open')),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 「テキストを貼り付け」→ 入力 →「読み込む」
Future<void> _paste(WidgetTester tester, String text) async {
  await tester.tap(find.text(AppTexts.pasteText));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.text(AppTexts.pasteApply));
  await tester.pumpAndSettle();
}

/// 「アップロード」ボタン（FilledButton.icon はサブクラスなので型で判定）
ButtonStyleButton _uploadButton(WidgetTester tester) => tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(AppTexts.upload),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );

/// 確認画面で OK → 今の内容と違いがあれば出る上書きの確認で「上書きしてアップロード」
/// （サンプルや前にアップロードしたものと違えば出る）→ 全画面ローディングを出す
Future<void> _confirmOk(WidgetTester tester, {bool overwrite = true}) async {
  await tester.tap(find.text(AppTexts.confirmOk));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  if (overwrite && find.text(OverwriteTexts.overwrite).evaluate().isNotEmpty) {
    await tester.tap(find.text(OverwriteTexts.overwrite));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// アップロード後の全画面ローディング（最低 5 秒）が消えるまで時間を進める
Future<void> _waitReloading(WidgetTester tester) async {
  for (var i = 0; i < 40 && find.text(AppTexts.reloading).evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pump();
}

void main() {
  // アセット（テンプレート・サンプル）はファイルから直接読む（テスト中の読み込みで止まらないように。test_assets.dart を参照）
  setUp(useFileAssets);

  setUp(() {
    stub.SessionStore.clear();
    ProfileStore.instance.value = null;
    ProfileStore.instance.startupErrors = const [];
  });

  group('Work のアップロード画面', () {
    testWidgets('最初は何も読み込んでおらず、アップロードを押せない', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));

      expect(find.text(AppTexts.workUploadTitle), findsOneWidget);
      expect(find.text(AppTexts.noFileChosen), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
      // テンプレートとデータの読み込み方法がそろっている
      for (final label in [
        AppTexts.downloadFormat,
        AppTexts.copyTemplate,
        AppTexts.chooseFile,
        AppTexts.pasteText,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('正しい YAML を貼り付け → 確認画面で OK → セッションに保存され、読み直しが呼ばれる',
        (tester) async {
      var saved = 0;
      await _pumpOpener(
        tester,
        (c) => showYamlUploadDialog(c, dataType: 'work', onSaved: () => saved++),
      );

      await _paste(tester, _workYaml);
      expect(find.text(AppTexts.fileReady(_pastedYaml)), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNotNull);

      // 確認画面：読み込み元・件数・タイトル
      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      expect(find.text(AppTexts.confirmTitle), findsOneWidget);
      expect(find.text(AppTexts.confirmFile(_pastedYaml)), findsOneWidget);
      expect(find.text('${AppTexts.work}：${AppTexts.confirmProjectCount(1)}'), findsOneWidget);
      expect(find.text('1. 貼り付けた業務'), findsOneWidget);
      expect(SessionStore.read('work'), isNull, reason: 'OK を押すまでは反映しない');

      await _confirmOk(tester);
      expect(find.text(AppTexts.reloading), findsOneWidget); // 全画面ローディング
      await _waitReloading(tester);

      expect(SessionStore.read('work'), _workYaml);
      expect(saved, 1);
      expect(find.text(AppTexts.workUploadTitle), findsNothing); // 画面は閉じた
      expect(find.text(AppTexts.uploadSaved('work')), findsOneWidget);
    });

    testWidgets('確認画面で「戻る」なら反映しない', (tester) async {
      var saved = 0;
      await _pumpOpener(
        tester,
        (c) => showYamlUploadDialog(c, dataType: 'work', onSaved: () => saved++),
      );
      await _paste(tester, _workYaml);
      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppTexts.confirmBack));
      await tester.pumpAndSettle();

      expect(find.text(AppTexts.workUploadTitle), findsOneWidget); // アップロード画面に戻る
      expect(SessionStore.read('work'), isNull);
      expect(saved, 0);
    });

    testWidgets('Private 用の YAML は理由を出して弾き、アップロードを押せない', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));
      await _paste(tester, _privateYaml);

      expect(find.text(AppTexts.fileRejected(_pastedYaml)), findsOneWidget);
      expect(
        find.text('${AppTexts.bullet}${AppTexts.formatMismatch('work', 'format_work.yaml')}'),
        findsOneWidget,
      );
      expect(_uploadButton(tester).onPressed, isNull);
    });

    testWidgets('貼り付け画面の見出しは、開くボタンと別の文言（どちらも 1 つずつ見つかる）', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));
      await tester.tap(find.text(AppTexts.pasteText));
      await tester.pumpAndSettle();

      expect(AppTexts.pasteTitle, isNot(AppTexts.pasteText));
      expect(find.text(AppTexts.pasteTitle), findsOneWidget); // 貼り付け画面の見出し
      expect(find.text(AppTexts.pasteText), findsOneWidget); // 後ろのアップロード画面のボタン
    });

    testWidgets('もう一度「テキストを貼り付け」を開くと、前の内容から直せる', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));
      await _paste(tester, _privateYaml); // 間違えた

      await tester.tap(find.text(AppTexts.pasteText));
      await tester.pumpAndSettle();
      expect(find.text(_privateYaml), findsOneWidget);
    });

    testWidgets('「テンプレートをコピー」で format_work.yaml の中身がクリップボードに入る', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
          (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));
      await tester.tap(find.text(AppTexts.copyTemplate));
      await tester.pumpAndSettle();

      expect(copied, File('assets/data/format_work.yaml').readAsStringSync());
    });
  });

  group('Private のアップロード画面', () {
    testWidgets('正しい YAML を貼り付け → OK で Private のセッションに保存（Work は変わらない）',
        (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'private'));
      expect(find.text(AppTexts.privateUploadTitle), findsOneWidget);

      await _paste(tester, _privateYaml);
      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      expect(find.text('1. 貼り付けた個人開発'), findsOneWidget);

      await _confirmOk(tester);
      await _waitReloading(tester);

      expect(SessionStore.read('private'), _privateYaml);
      expect(SessionStore.read('work'), isNull);
    });

    testWidgets('Work 用の YAML（workflow あり）は弾く', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'private'));
      await _paste(tester, _workYaml);

      expect(find.text(AppTexts.fileRejected(_pastedYaml)), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
    });
  });

  group('最初の入力画面（プロフィール）', () {
    testWidgets('読み込むまで閉じられない（外側のタップ・Esc）', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      expect(find.text(ProfileTexts.setupTitle), findsOneWidget);

      await tester.tapAt(const Offset(5, 5)); // 外側
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text(ProfileTexts.setupTitle), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
    });

    testWidgets('正しい YAML を貼り付け → 確認画面 → OK でプロフィールが反映され、画面が閉じる',
        (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(tester, _profileYaml);
      expect(find.text(AppTexts.fileReady(_pastedYaml)), findsOneWidget);

      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      expect(find.text(AppTexts.confirmTitle), findsOneWidget);
      expect(find.text('貼り付け 太郎'), findsOneWidget); // 確認画面に名前
      expect(ProfileStore.instance.value, isNull, reason: 'OK を押すまでは反映しない');

      await _confirmOk(tester);
      await _waitReloading(tester);

      expect(ProfileStore.instance.value?.name, '貼り付け 太郎');
      expect(SessionStore.read(ProfileStore.sessionKey), _profileYaml);
      expect(find.text(ProfileTexts.setupTitle), findsNothing);
      expect(find.text(ProfileTexts.uploaded), findsOneWidget);
    });

    testWidgets('必須項目が足りない YAML は理由を出して弾く', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(tester, 'home:\n  name: 太郎\n  role: エンジニア\n  tagline: 紹介文\nabout:\n  domains: [Web]\n');

      expect(find.text(AppTexts.fileRejected(_pastedYaml)), findsOneWidget);
      expect(
        find.text('${AppTexts.bullet}${ProfileTexts.errorRequired('about.intro')}'),
        findsOneWidget,
      );
      expect(_uploadButton(tester).onPressed, isNull);
    });

    testWidgets('Work の YAML を貼り付けても弾く', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(tester, _workYaml);

      expect(
        find.text('${AppTexts.bullet}${ProfileTexts.errorUnknownKey('projects')}'),
        findsOneWidget,
      );
      expect(_uploadButton(tester).onPressed, isNull);
    });
  });

  group('Markdown で読み込む', () {
    testWidgets('Work：Markdown を貼り付け → OK で保存（YAML として読める形で保存される）', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));
      await _paste(tester, '# 業務 Markdown\n- period: 2024-04 ~ 現在\n- workflow: 基本設計\n');
      expect(find.text(AppTexts.fileReady(_pastedMd)), findsOneWidget);

      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      expect(find.text('1. 業務 Markdown'), findsOneWidget);
      await _confirmOk(tester);
      await _waitReloading(tester);

      final saved = loadYaml(SessionStore.read('work')!) as YamlMap;
      expect(saved['projects'][0]['title'], '業務 Markdown');
      expect(saved['projects'][0]['workflow']['basic_design'], true);
    });

    testWidgets('Private：Markdown の書き方の誤りは行番号付きで出し、アップロードを押せない', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'private'));
      await _paste(tester, '# 個人開発\n- skils: Dart\n');

      expect(find.text(AppTexts.fileRejected(_pastedMd)), findsOneWidget);
      expect(find.text('${AppTexts.bullet}${MarkdownTexts.unknownKey(2, 'skils')}'), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
    });

    testWidgets('プロフィール：Markdown を貼り付け → OK で反映', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(
        tester,
        '# home\n- name: Markdown 太郎\n- role: エンジニア\n## tagline\n紹介文\n# about\n## intro\n自己紹介\n',
      );
      expect(find.text(AppTexts.fileReady(_pastedMd)), findsOneWidget);

      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      await _confirmOk(tester);
      await _waitReloading(tester);

      expect(ProfileStore.instance.value?.name, 'Markdown 太郎');
      expect(ProfileStore.instance.value?.intro, '自己紹介');
    });

    testWidgets('テンプレートの形式を Markdown にすると、Markdown のひな形をコピーする', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
          (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _pumpOpener(tester, showProfileSetupDialog);
      await tester.tap(find.text(AppTexts.formatMarkdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppTexts.copyTemplate));
      await tester.pumpAndSettle();

      expect(copied, File('assets/data/format_profile.md').readAsStringSync());
    });
  });

  group('最初の入力画面：Work / Private も一緒に読み込む', () {
    const bundleYaml = '''
home:
  name: まとめて 太郎
  role: エンジニア
  tagline: 紹介文
about:
  intro: 自己紹介
work:
  - title: 一緒の業務
    workflow:
      requirements: true
private:
  - title: 一緒の個人開発
''';

    testWidgets('1 回のアップロードでプロフィール・Work・Private が反映され、Skills / Projects を作り直す', (tester) async {
      var changed = 0;
      await _pumpOpener(tester, (c) => showProfileSetupDialog(c, onProjectsChanged: () => changed++));
      await _paste(tester, bundleYaml);

      expect(
        find.text(BundleTexts.alsoLoads(BundleTexts.includes(1, 1))),
        findsOneWidget,
      );

      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      expect(find.text(BundleTexts.confirmSection(AppTexts.work, 1)), findsOneWidget);
      expect(find.text('1. 一緒の業務'), findsOneWidget);
      expect(find.text(BundleTexts.confirmSection(AppTexts.private, 1)), findsOneWidget);
      expect(find.text('1. 一緒の個人開発'), findsOneWidget);

      await _confirmOk(tester);
      await _waitReloading(tester);

      expect(ProfileStore.instance.value?.name, 'まとめて 太郎');
      expect(((loadYaml(SessionStore.read('work')!) as YamlMap)['projects'] as YamlList)[0]['title'], '一緒の業務');
      expect(((loadYaml(SessionStore.read('private')!) as YamlMap)['projects'] as YamlList)[0]['title'], '一緒の個人開発');
      expect(changed, 1);
    });

    testWidgets('プロフィールだけなら Work / Private は変えず、作り直しも呼ばない', (tester) async {
      var changed = 0;
      SessionStore.write('work', 'projects:\n  - title: 前からの業務\n    workflow: {}\n');
      await _pumpOpener(tester, (c) => showProfileSetupDialog(c, onProjectsChanged: () => changed++));
      await _paste(tester, _profileYaml);
      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      await _confirmOk(tester);
      await _waitReloading(tester);

      expect(SessionStore.read('work'), contains('前からの業務'));
      expect(SessionStore.read('private'), isNull);
      expect(changed, 0);
    });

    testWidgets('一緒に書いた Work が正しくなければ、理由を出してアップロードを押せない', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(tester, '$_profileYaml\nwork:\n  - title: workflow がない\n');

      expect(find.text('${AppTexts.bullet}${BundleTexts.workInvalid}'), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);
    });
  });

  group('今の内容と違うときは、上書きしてよいかを確かめる', () {
    /// 今表示している Work（前にアップロードしたもの）
    const currentWork = '''
projects:
  - title: 今の業務
    workflow:
      requirements: true
''';

    Future<void> openWorkAndPaste(WidgetTester tester, String text) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'work'));
      await _paste(tester, text);
      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppTexts.confirmOk));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('違いがあれば上書きの確認を出し、なくなる・追加されるプロジェクトを並べる', (tester) async {
      SessionStore.write('work', currentWork);
      await openWorkAndPaste(tester, _workYaml);

      expect(find.text(OverwriteTexts.title), findsOneWidget);
      expect(find.text(OverwriteTexts.removed(1)), findsOneWidget);
      expect(find.text('${AppTexts.bullet}今の業務'), findsOneWidget);
      expect(find.text(OverwriteTexts.added(1)), findsOneWidget);
      expect(find.text('${AppTexts.bullet}貼り付けた業務'), findsOneWidget);
    });

    testWidgets('「やめる」なら反映せず、アップロード画面に戻る', (tester) async {
      SessionStore.write('work', currentWork);
      await openWorkAndPaste(tester, _workYaml);

      await tester.tap(find.text(OverwriteTexts.cancel));
      await tester.pumpAndSettle();

      expect(SessionStore.read('work'), currentWork); // 今の内容のまま
      expect(find.text(AppTexts.workUploadTitle), findsOneWidget);
      expect(find.text(AppTexts.reloading), findsNothing);
    });

    testWidgets('「上書きしてアップロード」を選んだときだけ反映する', (tester) async {
      SessionStore.write('work', currentWork);
      await openWorkAndPaste(tester, _workYaml);

      await tester.tap(find.text(OverwriteTexts.overwrite));
      await tester.pump(const Duration(milliseconds: 100));
      await _waitReloading(tester);

      expect(SessionStore.read('work'), _workYaml);
    });

    testWidgets('今と同じ内容なら、上書きの確認は出さずに反映する', (tester) async {
      SessionStore.write('work', _workYaml);
      await openWorkAndPaste(tester, _workYaml);

      expect(find.text(OverwriteTexts.title), findsNothing);
      expect(find.text(AppTexts.reloading), findsOneWidget);
      await _waitReloading(tester);
      expect(SessionStore.read('work'), _workYaml);
    });

    testWidgets('最初の入力画面：一緒に書いた Work / Private が違えば確かめ、「やめる」なら何も反映しない', (tester) async {
      SessionStore.write('work', currentWork);
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(tester, '''
$_profileYaml
work:
  - title: 新しい業務
    workflow:
      requirements: true
private:
  - title: 新しい個人開発
''');
      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppTexts.confirmOk));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Work と Private の両方の違いを、それぞれの見出しの下に並べる
      expect(find.text(OverwriteTexts.title), findsOneWidget);
      expect(find.text(AppTexts.work), findsWidgets);
      expect(find.text('${AppTexts.bullet}今の業務'), findsOneWidget);
      expect(find.text('${AppTexts.bullet}新しい個人開発'), findsOneWidget);

      await tester.tap(find.text(OverwriteTexts.cancel));
      await tester.pumpAndSettle();

      expect(ProfileStore.instance.value, isNull);
      expect(SessionStore.read('work'), currentWork);
      expect(SessionStore.read('private'), isNull);
      expect(find.text(ProfileTexts.setupTitle), findsOneWidget); // 入力画面に戻る
    });
  });

  group('最初の入力画面：入力方法（Excel / YAML・Markdown）', () {
    testWidgets('はじめは YAML / Markdown。Excel に切り替えると Excel のボタンだけになる', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      expect(find.text(ExcelTexts.methodExcel), findsOneWidget);
      expect(find.text(AppTexts.pasteText), findsOneWidget);
      expect(find.text(ExcelTexts.chooseExcel), findsNothing);

      await tester.tap(find.text(ExcelTexts.methodExcel));
      await tester.pumpAndSettle();
      expect(find.text(ExcelTexts.saveTemplate), findsOneWidget);
      expect(find.text(ExcelTexts.chooseExcel), findsOneWidget);
      expect(find.text(AppTexts.pasteText), findsNothing);
      expect(find.text(ExcelTexts.steps.first), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNull);

      // Excel テンプレートの保存（テストでは保存先がないので、エラーにならないことだけ確かめる）
      await tester.tap(find.text(ExcelTexts.saveTemplate));
      await tester.pumpAndSettle();
      expect(find.textContaining(AppTexts.downloadFailed('').trim()), findsNothing);
    });

    testWidgets('YAML を読み込んだあとに切り替えると、選択は取り消される', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(tester, _profileYaml);
      expect(_uploadButton(tester).onPressed, isNotNull);

      await tester.tap(find.text(ExcelTexts.methodExcel));
      await tester.pumpAndSettle();
      expect(_uploadButton(tester).onPressed, isNull);
      expect(find.text(AppTexts.noFileChosen), findsOneWidget);

      await tester.tap(find.text(ExcelTexts.methodText));
      await tester.pumpAndSettle();
      expect(_uploadButton(tester).onPressed, isNull);
    });
  });
}
