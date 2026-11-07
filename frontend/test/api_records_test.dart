// アプリのデータ ⇔ API のデータの行き来と、API の Repository のテスト
// 対象：lib/data/api_records.dart、lib/data/api_portfolio_repository.dart
//
// 実行：flutter test test/api_records_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/api/json_client.dart';
import 'package:dev_portfolio/data/api_portfolio_repository.dart';
import 'package:dev_portfolio/data/api_records.dart';
import 'package:dev_portfolio/data/portfolio_repository.dart';

import 'fake_backend.dart';

void main() {
  group('プロジェクトの行き来', () {
    test('アプリ → API：技術は tech に、「利用なし」は外す、期間は start・end に', () {
      final api = projectToApi({
        'title': '  業務  ',
        'description': '説明',
        'details': '',
        'role': ['PG', '利用なし'],
        'scale': '5 名',
        'period': ['2023-04', '2023-09'],
        'link': 'https://example.com',
        'skills': ['Dart', '利用なし'],
        'db': '利用なし',
        'tools': 'Git, VSCode、Docker',
        'workflow': {'requirements': true, 'basic_design': false, 'unknown': true, 'system_test': 'yes'},
      }, kind: 'work', order: 2, id: 'p1');
      expect(api, {
        'id': 'p1',
        'kind': 'work',
        'order': 2,
        'title': '業務',
        'description': '説明',
        'role': ['PG'],
        'scale': '5 名',
        'period': {'start': '2023-04', 'end': '2023-09'},
        'link': 'https://example.com',
        'tech': {
          'tools': ['Git', 'VSCode', 'Docker'],
          'skills': ['Dart'],
        },
        'workflow': {'requirements': true, 'basic_design': false},
      });
    });

    test('期間のいろいろな書き方', () {
      Object? period(Object? v) => projectToApi({'period': v}, kind: 'private', order: 0, id: 'p')['period'];
      expect(period(['2024/1', '現在']), {'start': '2024-01', 'end': null});
      expect(period('2023年4月 〜 2023年9月'), {'start': '2023-04', 'end': '2023-09'});
      expect(period(['2024-01']), {'start': '2024-01', 'end': null});
      expect(period(['2024-05', '2024-01']), {'start': '2024-05', 'end': null}, reason: '終わりが始まりより前なら終わりは外す');
      expect(period(['2024-13']), isNull, reason: '月が読めない');
      expect(period(['いつか']), isNull);
      expect(period([]), isNull);
      expect(period(null), isNull);
    });

    test('名前なし・長すぎる文字・https でないリンク・Private の工程は送らない', () {
      final api = projectToApi({
        'title': '',
        'description': 'あ' * 6000,
        'link': 'http://example.com',
        'workflow': {'requirements': true},
      }, kind: 'private', order: 0, id: 'p');
      expect(api['title'], '（名前なし）');
      expect((api['description'] as String).length, 5000);
      expect(api.containsKey('link'), isFalse);
      expect(api.containsKey('workflow'), isFalse);
      expect(api.containsKey('tech'), isFalse);
      expect(projectToApi({'link': 'https://a b'}, kind: 'work', order: 0, id: 'p').containsKey('link'), isFalse);
    });

    test('API → アプリ：YAML のテンプレートと同じキー（ない技術は「利用なし」、終わりがなければ「現在」）', () {
      final app = projectFromApi({
        'id': 'p1',
        'kind': 'work',
        'order': 0,
        'title': '業務',
        'role': ['PG'],
        'period': {'start': '2024-01', 'end': null},
        'tech': {'skills': ['Dart'], 'db': []},
        'workflow': {'requirements': true},
      });
      expect(app['title'], '業務');
      expect(app['description'], '');
      expect(app['skills'], ['Dart']);
      expect(app['db'], ['利用なし']);
      expect(app['period'], ['2024-01', '現在']);
      expect(app['workflow'], {'requirements': true});
      expect(app.containsKey('id'), isFalse);

      final private = projectFromApi({'kind': 'private', 'workflow': {'requirements': true}});
      expect(private.containsKey('workflow'), isFalse);
      expect(private.containsKey('period'), isFalse);
      expect(private['tools'], ['利用なし']);
    });

    test('並びを送るとき：同じ種類・同じ名前の前のものがあれば id を引き継ぐ', () {
      var n = 0;
      final previous = [
        {'id': 'old-a', 'kind': 'work', 'title': 'A'},
        {'id': 'old-b', 'kind': 'private', 'title': 'B'},
      ];
      final result = projectsToApi(
        [
          {'title': 'B'},
          {'title': 'A'},
          {'title': 'A'},
        ],
        kind: 'work',
        previous: previous,
        newId: () => 'new-${n++}',
      );
      expect([for (final p in result) p['id']], ['new-0', 'old-a', 'new-1']);
      expect([for (final p in result) p['order']], [0, 1, 2]);
    });

    test('新しい id は p_ ＋ 20 文字で、毎回違う', () {
      final a = newProjectId();
      expect(a, matches(RegExp(r'^p_[a-z0-9]{20}$')));
      expect(newProjectId(), isNot(a));
    });
  });

  group('プロフィールの行き来', () {
    test('アプリ → API：about の recent_tech・past_tech は skills に。空は送らない', () {
      final api = profileToApi({
        'home': {'name': '試験 太郎', 'role': '', 'card': 'x'},
        'about': {
          'intro': '紹介',
          'domains': 'Web、モバイル',
          'recent_tech': {'skills': ['Dart', '利用なし'], '': ['x']},
          'past_tech': {'skills': []},
        },
        'sheet': {'furigana': 'しけん たろう', 'unknown': 'x'},
      });
      expect(api.profile, {
        'home': {'name': '試験 太郎'},
        'about': {'intro': '紹介', 'domains': ['Web', 'モバイル']},
        'sheet': {'furigana': 'しけん たろう'},
      });
      expect(api.skills, {
        'recentTech': {'skills': ['Dart']},
        'pastTech': {'skills': <String>[]},
      });
      final empty = profileToApi({});
      expect(empty.profile, {'home': {}, 'about': {}, 'sheet': {}});
      expect(empty.skills, isEmpty);
      expect(profileToApi({'about': {'recent_tech': 'x'}}).skills, isEmpty);
    });

    test('文字数は API と同じ上限。生年月日は API では YYYY-MM-DD（読めなければ送らない）', () {
      final api = profileToApi({
        'home': {'name': 'あ' * 150, 'tagline': 'い' * 150},
        'sheet': {'birthday': '1990年4月1日', 'education': 'う' * 150, 'age': '30'},
      }).profile;
      expect((api['home']['name'] as String).length, 100);
      expect((api['home']['tagline'] as String).length, 150, reason: '紹介文は文章（5000 文字まで）');
      expect(api['sheet']['birthday'], '1990-04-01');
      expect((api['sheet']['education'] as String).length, 100);
      expect(api['sheet']['age'], '30');
      expect(profileToApi({'sheet': {'birthday': 'いつか'}}).profile['sheet'], isEmpty);

      expect(profileFromApi({'sheet': {'birthday': '1990-04-01'}}, {})['sheet'], {'birthday': '1990年04月01日'});
      expect(profileFromApi({'sheet': {'birthday': 'x'}}, {})['sheet'], {'birthday': 'x'});
    });

    test('API → アプリ', () {
      final app = profileFromApi(
        {'home': {'name': '試験'}, 'about': {'intro': '紹介'}, 'sheet': {}},
        {'recentTech': {'skills': ['Dart']}, 'pastTech': {'skills': ['Python']}},
      );
      expect(app, {
        'home': {'name': '試験'},
        'about': {'intro': '紹介', 'recent_tech': {'skills': ['Dart']}, 'past_tech': {'skills': ['Python']}},
      });
      expect(profileFromApi({'sheet': {'station': '○○駅'}}, {})['sheet'], {'station': '○○駅'});
    });
  });

  group('ApiPortfolioRepository', () {
    late FakeBackend backend;
    late ApiPortfolioRepository repository;
    setUp(() {
      backend = FakeBackend();
      var n = 0;
      repository = ApiPortfolioRepository(backend.portfolioApi(), newId: () => 'id${n++}');
    });

    test('まだ何も保存していなければ、プロフィールはなし・プロジェクトはサンプル', () async {
      expect(await repository.loadProfileRecord(), isNull);
      expect(await repository.loadProjectRecords(ProjectsKind.work), isNull);
      expect(await repository.isSampleProjects(ProjectsKind.private), isTrue);
    });

    test('プロフィールを保存して読む（形を行き来する）', () async {
      await repository.saveProfileRecord({
        'home': {'name': '試験 太郎', 'role': 'エンジニア', 'tagline': '紹介文'},
        'about': {'intro': '自己紹介', 'recent_tech': {'skills': ['Dart']}},
      });
      expect(backend.data['skills'], {'recentTech': {'skills': ['Dart']}});
      final record = await repository.loadProfileRecord();
      expect(record!['home'], {'name': '試験 太郎', 'role': 'エンジニア', 'tagline': '紹介文'});
      expect(record['about']['recent_tech'], {'skills': ['Dart']});
      final loaded = await repository.loadProfile();
      expect(loaded.profile?.name, '試験 太郎');
    });

    test('Work を保存しても Private は残る。並び順・id を保つ', () async {
      await repository.saveProjectRecords(ProjectsKind.private, [
        {'title': '個人'},
      ]);
      await repository.saveProjectRecords(ProjectsKind.work, [
        {'title': '業務 B'},
        {'title': '業務 A'},
      ]);
      expect(await repository.loadProfileRecord(), isNull, reason: 'プロジェクトだけ保存したときは、プロフィールはまだない');
      final work = await repository.loadProjectRecords(ProjectsKind.work);
      expect([for (final p in work!) p['title']], ['業務 B', '業務 A']);
      expect([for (final p in (await repository.loadProjectRecords(ProjectsKind.private))!) p['title']], ['個人']);

      // 並べ替えても id は同じ名前のものを引き継ぐ
      await repository.saveProjectRecords(ProjectsKind.work, [
        {'title': '業務 A'},
        {'title': '業務 B'},
      ]);
      final ids = {for (final p in backend.data['projects'] as List) p['title']: p['id']};
      expect(ids, {'個人': 'id0', '業務 B': 'id1', '業務 A': 'id2'});

      await repository.clearProjects(ProjectsKind.work);
      expect(await repository.loadProjectRecords(ProjectsKind.work), isEmpty);
      expect(await repository.isSampleProjects(ProjectsKind.work), isFalse, reason: '空にしたのはサンプルではない');
    });

    test('ほかの場所で先に変わっていたら（409）読み直してやり直す', () async {
      backend.conflicts = 2;
      await repository.saveProjectRecords(ProjectsKind.work, [
        {'title': '業務'},
      ]);
      expect(backend.calls.where((c) => c == 'PUT /api/me/draft').length, 3);
      expect((backend.data['projects'] as List).single['title'], '業務');
    });

    test('異常系：3 回とも重なったら、409 の ApiException', () async {
      backend.conflicts = 3;
      await expectLater(
        repository.saveProfileRecord({'home': {'name': 'x'}}),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );
    });

    test('異常系：409 でない失敗は、やり直さない', () async {
      backend.failures['PUT /api/me/draft'] = 400;
      await expectLater(repository.saveProfileRecord({'home': {'name': 'x'}}), throwsA(isA<ApiException>()));
      expect(backend.calls.where((c) => c == 'PUT /api/me/draft').length, 1);
    });

    test('既定の id は newProjectId', () async {
      final defaults = ApiPortfolioRepository(backend.portfolioApi());
      await defaults.saveProjectRecords(ProjectsKind.work, [
        {'title': 'x'},
      ]);
      expect((backend.data['projects'] as List).single['id'], startsWith('p_'));
    });
  });
}
