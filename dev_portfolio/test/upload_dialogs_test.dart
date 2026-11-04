// アップロード画面（Work / Private / 最初の入力画面）の流れのテスト
// 読み込み（テキストの貼り付け）→ 形式の確認 → アップロード → 確認画面 → OK で反映
//
// 対象：
//   lib/sections/header/yaml_upload_dialog.dart（Work / Private）
//   lib/widgets/profile_setup_dialog.dart（最初の入力画面）
// ※ ファイル選択（OS のダイアログ）はテストから操作できないので、同じ確認処理を通る「テキストを貼り付け」で確かめる
//
// 実行：flutter test test/upload_dialogs_test.dart（dev_portfolio/ で）
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/header/yaml_upload_dialog.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/browser/browser.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/widgets/profile_setup_dialog.dart';

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

/// アップロード後の全画面ローディング（最低 5 秒）が消えるまで時間を進める
Future<void> _waitReloading(WidgetTester tester) async {
  for (var i = 0; i < 40 && find.text(AppTexts.reloading).evaluate().isNotEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pump();
}

void main() {
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
      expect(find.text(AppTexts.fileReady(AppTexts.pastedTextName)), findsOneWidget);
      expect(_uploadButton(tester).onPressed, isNotNull);

      // 確認画面：読み込み元・件数・タイトル
      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      expect(find.text(AppTexts.confirmTitle), findsOneWidget);
      expect(find.text(AppTexts.confirmFile(AppTexts.pastedTextName)), findsOneWidget);
      expect(find.text('${AppTexts.work}：${AppTexts.confirmProjectCount(1)}'), findsOneWidget);
      expect(find.text('1. 貼り付けた業務'), findsOneWidget);
      expect(SessionStore.read('work'), isNull, reason: 'OK を押すまでは反映しない');

      await tester.tap(find.text(AppTexts.confirmOk));
      await tester.pump(const Duration(milliseconds: 100)); // 確認画面を閉じ、全画面ローディングを出す
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

      expect(find.text(AppTexts.fileRejected(AppTexts.pastedTextName)), findsOneWidget);
      expect(
        find.text('${AppTexts.bullet}${AppTexts.formatMismatch('work', 'format_work.yaml')}'),
        findsOneWidget,
      );
      expect(_uploadButton(tester).onPressed, isNull);
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

      await tester.tap(find.text(AppTexts.confirmOk));
      await tester.pump(const Duration(milliseconds: 100)); // 確認画面を閉じ、全画面ローディングを出す
      await _waitReloading(tester);

      expect(SessionStore.read('private'), _privateYaml);
      expect(SessionStore.read('work'), isNull);
    });

    testWidgets('Work 用の YAML（workflow あり）は弾く', (tester) async {
      await _pumpOpener(tester, (c) => showYamlUploadDialog(c, dataType: 'private'));
      await _paste(tester, _workYaml);

      expect(find.text(AppTexts.fileRejected(AppTexts.pastedTextName)), findsOneWidget);
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
      expect(find.text(AppTexts.fileReady(AppTexts.pastedTextName)), findsOneWidget);

      await tester.tap(find.text(AppTexts.upload));
      await tester.pumpAndSettle();
      expect(find.text(AppTexts.confirmTitle), findsOneWidget);
      expect(find.text('貼り付け 太郎'), findsOneWidget); // 確認画面に名前
      expect(ProfileStore.instance.value, isNull, reason: 'OK を押すまでは反映しない');

      await tester.tap(find.text(AppTexts.confirmOk));
      await tester.pump(const Duration(milliseconds: 100)); // 確認画面を閉じ、全画面ローディングを出す
      await _waitReloading(tester);

      expect(ProfileStore.instance.value?.name, '貼り付け 太郎');
      expect(SessionStore.read(ProfileStore.sessionKey), _profileYaml);
      expect(find.text(ProfileTexts.setupTitle), findsNothing);
      expect(find.text(ProfileTexts.uploaded), findsOneWidget);
    });

    testWidgets('必須項目が足りない YAML は理由を出して弾く', (tester) async {
      await _pumpOpener(tester, showProfileSetupDialog);
      await _paste(tester, 'home:\n  name: 太郎\n  role: エンジニア\n  tagline: 紹介文\nabout:\n  domains: [Web]\n');

      expect(find.text(AppTexts.fileRejected(AppTexts.pastedTextName)), findsOneWidget);
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
}
