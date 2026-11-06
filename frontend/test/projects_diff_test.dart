// 今の Work / Private とこれからアップロードする内容の違い（上書きの確認）のテスト
// 対象：lib/utils/projects_diff.dart
//
// 実行：flutter test test/projects_diff_test.dart（frontend/ で）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/utils/data_format.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';
import 'package:dev_portfolio/utils/projects_diff.dart';

String _asset(String name) => File('assets/data/$name').readAsStringSync();

const _base = '''
projects:
  - title: 案件A
    period: ["2024-01", "2024-03"]
    skills: [Dart]
  - title: 案件B
    skills: [Python]
''';

void main() {
  group('違いがない（上書きの確認を出さない）', () {
    test('同じ内容', () {
      expect(diffProjects(_base, _base).hasChanges, isFalse);
    });

    test('書き方だけが違う（YAML と JSON、詳細の末尾の改行、期間の数値と文字列、空のリンク、キーの順番）', () {
      const a = '''
projects:
  - title: 案件A
    details: |
      1 行目
    period: [2024-01, 2024-03]
    link: ""
    skills: [Dart]
''';
      const b = '{"projects":[{"skills":["Dart"],"title":"案件A","period":["2024-01","2024-03"],"details":"1 行目"}]}';
      expect(diffProjects(a, b).hasChanges, isFalse);
    });

    test('Markdown 版のテンプレートと YAML 版のテンプレート', () {
      for (final kind in [DataKind.work, DataKind.private]) {
        final md = normalizeInput(_asset('format_${kind.name}.md'), kind: kind, fileName: 'x.md').text!;
        expect(diffProjects(_asset('format_${kind.name}.yaml'), md).hasChanges, isFalse, reason: kind.name);
      }
    });
  });

  group('違いがある', () {
    test('追加・削除・変更をタイトルで知らせる', () {
      const next = '''
projects:
  - title: 案件A
    period: ["2024-01", "2024-06"]
    skills: [Dart]
  - title: 案件C
''';
      final d = diffProjects(_base, next);
      expect(d.hasChanges, isTrue);
      expect(d.changed, ['案件A']); // 期間が変わった
      expect(d.removed, ['案件B']);
      expect(d.added, ['案件C']);
    });

    test('並び順だけが違うときは変更なし', () {
      const swapped = '''
projects:
  - title: 案件B
    skills: [Python]
  - title: 案件A
    period: ["2024-01", "2024-03"]
    skills: [Dart]
''';
      expect(diffProjects(_base, swapped).hasChanges, isFalse);
    });

    test('同じタイトルが複数あるときは出てきた順で対応づける', () {
      const two = 'projects:\n  - title: 同名\n    skills: [A]\n  - title: 同名\n    skills: [B]\n';
      const one = 'projects:\n  - title: 同名\n    skills: [A]\n';
      final d = diffProjects(two, one);
      expect(d.removed, ['同名']);
      expect(d.changed, isEmpty);
    });

    test('今の内容が読めないときは、すべて追加とみなす', () {
      final d = diffProjects('壊れた: [', _base);
      expect(d.added, ['案件A', '案件B']);
      expect(d.removed, isEmpty);
    });
  });

  group('テンプレートがそろっている', () {
    test('プロフィールのテンプレートに入れた Work / Private は、単独のテンプレートと同じ', () {
      for (final name in ['format_profile.yaml', 'format_profile.md']) {
        final b = readProfileBundle(_asset(name), fileName: name);
        expect(diffProjects(_asset('format_work.yaml'), b.workText!).hasChanges, isFalse, reason: name);
        expect(diffProjects(_asset('format_private.yaml'), b.privateText!).hasChanges, isFalse, reason: name);
      }
    });
  });
}
