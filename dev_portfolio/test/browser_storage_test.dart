// sessionStorage の置き換え（dart:html → package:web）まわりのテスト
// flutter test（VM）では lib/utils/browser/browser_stub.dart（メモリ上の Map）が選ばれる。
//
// 対象：SessionStore / WorkYamlLoader / PrivateYamlLoader / ProfileStore
// 実行：flutter test test/browser_storage_test.dart（dev_portfolio/ で）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/utils/browser/browser.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/work_yaml_loader.dart';
import 'package:dev_portfolio/utils/private_yaml_loader.dart';
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/utils/asset_text.dart';

String _asset(String name) => File('assets/data/$name').readAsStringSync();

const _workYaml = '''
projects:
  - title: アップロードした業務
    workflow:
      requirements: true
''';

const _privateYaml = '''
projects:
  - title: アップロードした個人開発
''';

const _profileYaml = '''
home:
  name: テスト 太郎
  role: エンジニア
  tagline: 紹介文
about:
  intro: 自己紹介
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // rootBundle（assets）を使うため

  setUp(() {
    stub.SessionStore.clear();
    WorkYamlLoader.clearCustomYaml();
    PrivateYamlLoader.clearCustomYaml();
    ProfileStore.instance.value = null;
    ProfileStore.instance.startupErrors = const [];
  });

  group('SessionStore（テストではメモリで代用）', () {
    test('書いた値を読め、消すと null になる', () {
      expect(SessionStore.read('k'), isNull);
      SessionStore.write('k', 'v');
      expect(SessionStore.read('k'), 'v');
      SessionStore.write('k', 'v2');
      expect(SessionStore.read('k'), 'v2');
      SessionStore.remove('k');
      expect(SessionStore.read('k'), isNull);
    });

    test('dispatchBrowserEvent は Web 以外では何もしない（例外にならない）', () {
      expect(() => dispatchBrowserEvent('app-ready'), returnsNormally);
    });
  });

  group('WorkYamlLoader', () {
    test('何もアップロードしていなければ assets の format_work.yaml', () async {
      expect(await WorkYamlLoader.loadYamlString(), _asset('format_work.yaml'));
    });

    test('セッションにあればそれを優先する', () async {
      SessionStore.write('work', _workYaml);
      expect(await WorkYamlLoader.loadYamlString(), _workYaml);
      final map = await WorkYamlLoader.loadWorkYamlMap();
      expect(map['projects'][0]['title'], 'アップロードした業務');
    });

    test('setCustomYaml はセッションにも保存し、clearCustomYaml で元に戻る', () async {
      WorkYamlLoader.setCustomYaml(_workYaml);
      expect(SessionStore.read('work'), _workYaml);
      expect(await WorkYamlLoader.loadYamlString(), _workYaml);

      WorkYamlLoader.clearCustomYaml();
      expect(SessionStore.read('work'), isNull);
      expect(await WorkYamlLoader.loadYamlString(), _asset('format_work.yaml'));
    });

    test('空文字のセッションは無視して assets を読む', () async {
      SessionStore.write('work', '');
      expect(await WorkYamlLoader.loadYamlString(), _asset('format_work.yaml'));
    });

    test('Private のセッションには影響されない', () async {
      SessionStore.write('private', _privateYaml);
      expect(await WorkYamlLoader.loadYamlString(), _asset('format_work.yaml'));
    });
  });

  group('アセットの読み込み（loadAssetText）', () {
    tearDown(resetAssetTextLoader);

    test('差し替えると、ローダーのサンプル読み込みもそれを使う', () async {
      final asked = <String>[];
      loadAssetText = (path) async {
        asked.add(path);
        return 'projects: []\n';
      };
      expect(await WorkYamlLoader.loadYamlString(), 'projects: []\n');
      expect(await PrivateYamlLoader.loadYamlString(), 'projects: []\n');
      expect(asked, ['assets/data/format_work.yaml', 'assets/data/format_private.yaml']);
    });

    test('アップロードしたものがあれば、アセットは読まない', () async {
      var called = 0;
      loadAssetText = (path) async {
        called++;
        return '';
      };
      SessionStore.write('work', 'projects: []\n');
      await WorkYamlLoader.loadYamlString();
      expect(called, 0);
    });

    test('元に戻すと rootBundle で読む（中身はファイルと同じ）', () async {
      resetAssetTextLoader();
      expect(await loadAssetText('assets/data/format_work.yaml'), _asset('format_work.yaml'));
    });
  });

  group('PrivateYamlLoader', () {
    test('何もアップロードしていなければ assets の format_private.yaml', () async {
      expect(await PrivateYamlLoader.loadYamlString(), _asset('format_private.yaml'));
    });

    test('セッションにあればそれを優先する', () async {
      SessionStore.write('private', _privateYaml);
      expect(await PrivateYamlLoader.loadYamlString(), _privateYaml);
    });

    test('setCustomYaml / clearCustomYaml', () async {
      PrivateYamlLoader.setCustomYaml(_privateYaml);
      expect(SessionStore.read('private'), _privateYaml);
      PrivateYamlLoader.clearCustomYaml();
      expect(await PrivateYamlLoader.loadYamlString(), _asset('format_private.yaml'));
    });
  });

  group('ProfileStore', () {
    test('YAML を指定せず起動・未アップロードなら null（入力画面を出す）', () async {
      // flutter test は --dart-define=PROFILE_FROM_ARG=true なしで動くので、起動時の YAML は読まない
      expect(ProfileStore.fromArg, isFalse);
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.value, isNull);
      expect(ProfileStore.instance.startupErrors, isEmpty);
    });

    test('セッションに正しいプロフィールがあれば読み込む（同じタブでの再読み込み）', () async {
      SessionStore.write(ProfileStore.sessionKey, _profileYaml);
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.value?.name, 'テスト 太郎');
    });

    test('セッションの内容が壊れていれば読み込まない', () async {
      SessionStore.write(ProfileStore.sessionKey, 'home: [壊れている');
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.value, isNull);
    });

    test('setUploaded はセッションに保存し、表示中のプロフィールを差し替えて通知する', () {
      final profile = Profile.parse(_profileYaml).profile!;
      var notified = 0;
      void listener() => notified++;
      ProfileStore.instance.addListener(listener);
      ProfileStore.instance.startupErrors = const ['前のエラー'];

      ProfileStore.instance.setUploaded(_profileYaml, profile);

      expect(SessionStore.read(ProfileStore.sessionKey), _profileYaml);
      expect(ProfileStore.instance.value, same(profile));
      expect(ProfileStore.instance.startupErrors, isEmpty);
      expect(notified, 1);
      ProfileStore.instance.removeListener(listener);
    });
  });
}
