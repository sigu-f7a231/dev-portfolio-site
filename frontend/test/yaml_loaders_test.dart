// Work / Private のローダーの正常系・異常系のテスト
// 対象：lib/utils/work_yaml_loader.dart、lib/utils/private_yaml_loader.dart
// 基本の動き（セッション優先・assets）は browser_storage_test.dart にある。ここでは読む順番の全通りと、壊れたデータを見る
//
// 実行：flutter test test/yaml_loaders_test.dart（frontend/ で）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/utils/browser/browser.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/private_yaml_loader.dart';
import 'package:dev_portfolio/utils/work_yaml_loader.dart';

import 'test_assets.dart';

/// Work と Private で同じテストを回すための入口
class _Loader {
  const _Loader(this.key, this.asset, this.set, this.clear, this.read, this.readMap);
  final String key;
  final String asset;
  final void Function(String) set;
  final void Function() clear;
  final Future<String> Function() read;
  final Future<YamlMap> Function() readMap;
}

final _loaders = [
  _Loader('work', 'assets/data/format_work.yaml', WorkYamlLoader.setCustomYaml, WorkYamlLoader.clearCustomYaml,
      WorkYamlLoader.loadYamlString, WorkYamlLoader.loadWorkYamlMap),
  _Loader('private', 'assets/data/format_private.yaml', PrivateYamlLoader.setCustomYaml,
      PrivateYamlLoader.clearCustomYaml, PrivateYamlLoader.loadYamlString, PrivateYamlLoader.loadPrivateYamlMap),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    stub.SessionStore.clear();
    WorkYamlLoader.clearCustomYaml();
    PrivateYamlLoader.clearCustomYaml();
    useFileAssets();
  });

  for (final l in _loaders) {
    group('${l.key}：読む順番（セッション → メモリ → assets）', () {
      test('何もなければ assets のサンプル', () async {
        expect(await l.read(), File(l.asset).readAsStringSync());
      });

      test('セッションとメモリの両方にあれば、セッション', () async {
        l.set('projects:\n  - title: メモリ\n');
        SessionStore.write(l.key, 'projects:\n  - title: セッション\n');
        expect(await l.read(), contains('セッション'));
      });

      test('セッションが消えても、メモリにあればメモリ', () async {
        l.set('projects:\n  - title: メモリ\n');
        SessionStore.remove(l.key);
        expect(await l.read(), contains('メモリ'));
      });

      test('clearCustomYaml でメモリもセッションも消え、assets に戻る', () async {
        l.set('projects:\n  - title: メモリ\n');
        l.clear();
        expect(SessionStore.read(l.key), isNull);
        expect(await l.read(), File(l.asset).readAsStringSync());
      });

      test('正常系：YamlMap として読める（assets のサンプルには projects がある）', () async {
        final map = await l.readMap();
        expect(map['projects'], isA<YamlList>());
        expect((map['projects'] as YamlList), isNotEmpty);
      });
    });

    group('${l.key}：異常系', () {
      test('YAML の書き方の誤りは YamlException', () async {
        SessionStore.write(l.key, 'projects: [\n');
        await expectLater(l.readMap(), throwsA(isA<YamlException>()));
      });

      test('トップが Map でない（並び・文字）は型のエラー', () async {
        SessionStore.write(l.key, '- title: A\n');
        await expectLater(l.readMap(), throwsA(isA<TypeError>()));
        SessionStore.write(l.key, 'just text');
        await expectLater(l.readMap(), throwsA(isA<TypeError>()));
      });

      test('文字列としては、壊れていてもそのまま返す（確かめるのは呼び出し側）', () async {
        SessionStore.write(l.key, 'projects: [\n');
        expect(await l.read(), 'projects: [\n');
      });

      test('ほかの種類（Work ↔ Private）のセッションには影響されない', () async {
        final other = l.key == 'work' ? 'private' : 'work';
        SessionStore.write(other, 'projects:\n  - title: ほか\n');
        expect(await l.read(), File(l.asset).readAsStringSync());
      });
    });
  }
}
