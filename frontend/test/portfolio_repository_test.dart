// Repository（データの読み書きの入口）の正常系・異常系のテスト
// 対象：lib/data/portfolio_repository.dart、lib/data/local_portfolio_repository.dart、lib/data/records.dart
// ローダー（WorkYamlLoader など）・ProfileStore を通した確認は yaml_loaders_test.dart・browser_storage_test.dart・coverage_extra_test.dart にある。
// ここでは
//   - 構造のデータ（DataRecord）と YAML の文字の行き来
//   - LocalPortfolioRepository を直接呼んだときの動き（文字・構造のデータ）
//   - 構造のデータの 5 つだけを書いた偽物（Firestore の実装の代わり）に差し替えると、文字の読み書き・サンプル・画面側（ローダー・ProfileStore）がそのまま動くこと
// を見る
//
// 実行：flutter test test/portfolio_repository_test.dart（frontend/ で）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/data/local_portfolio_repository.dart';
import 'package:dev_portfolio/data/portfolio_repository.dart';
import 'package:dev_portfolio/data/records.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/utils/asset_text.dart';
import 'package:dev_portfolio/utils/browser/browser.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/private_yaml_loader.dart';
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/utils/work_yaml_loader.dart';

import 'test_assets.dart';

const _profileYaml = '''
home:
  name: リポジトリ 太郎
  role: エンジニア
  tagline: 紹介文
about:
  intro: 自己紹介
''';

const _workYaml = '''
# コメントも残る
projects:
  - title: 保存した業務
    skills:
      - Dart
    period: [2024-01, 現在]
    workflow:
      implementation_unit_test: true
''';

/// 構造のデータの 5 つだけを書いた偽物（API・Firestore の実装の代わり）。呼ばれたことを残す
class _RecordsOnlyRepository extends PortfolioRepository {
  DataRecord? profile;
  final Map<ProjectsKind, List<DataRecord>> projects = {};
  final List<String> calls = [];

  @override
  Future<DataRecord?> loadProfileRecord() async {
    calls.add('loadProfile');
    return profile;
  }

  @override
  Future<void> saveProfileRecord(DataRecord record) async {
    calls.add('saveProfile');
    profile = record;
  }

  @override
  Future<List<DataRecord>?> loadProjectRecords(ProjectsKind kind) async {
    calls.add('load:${kind.name}');
    return projects[kind];
  }

  @override
  Future<void> saveProjectRecords(ProjectsKind kind, List<DataRecord> records) async {
    calls.add('save:${kind.name}');
    projects[kind] = records;
  }

  @override
  Future<void> clearProjects(ProjectsKind kind) async {
    calls.add('clear:${kind.name}');
    projects.remove(kind);
  }
}

String _asset(ProjectsKind kind) => File(PortfolioRepository.sampleAssetPath(kind)).readAsStringSync();

void main() {
  late LocalPortfolioRepository repo;

  setUp(() {
    useFileAssets();
    stub.SessionStore.clear();
    PortfolioRepository.reset();
    repo = LocalPortfolioRepository();
  });
  tearDown(() {
    LocalPortfolioRepository.fromArg = false;
    PortfolioRepository.reset();
    ProfileStore.instance.value = null;
    ProfileStore.instance.startupErrors = const [];
  });

  group('ProjectsKind', () {
    test("'work' は Work、それ以外は Private", () {
      expect(ProjectsKind.of('work'), ProjectsKind.work);
      expect(ProjectsKind.of('private'), ProjectsKind.private);
      expect(ProjectsKind.of('other'), ProjectsKind.private);
    });

    test('名前は sessionStorage のキー・テンプレートの名前と同じ', () {
      expect(ProjectsKind.work.name, 'work');
      expect(PortfolioRepository.sampleAssetPath(ProjectsKind.private), 'assets/data/format_private.yaml');
    });
  });

  group('構造のデータと YAML の文字（records.dart）', () {
    test('YAML → 普通の Map（YamlMap / YamlList ではない）', () {
      final r = recordOfYaml(_profileYaml);
      expect(r, isNot(isA<YamlMap>()));
      expect(r['home'], isNot(isA<YamlMap>()));
      expect((r['home'] as Map)['name'], 'リポジトリ 太郎');
    });

    test('プロジェクトの並び → YAML → 並び で同じ中身', () {
      final records = projectRecordsOfYaml(_workYaml);
      expect(records.single['title'], '保存した業務');
      expect(records.single['skills'], isNot(isA<YamlList>()));
      expect(projectRecordsOfYaml(yamlOfProjects(records)), records);
      expect(recordOfYaml(yamlOfRecord(recordOfYaml(_profileYaml))), recordOfYaml(_profileYaml));
    });

    test('サンプル（テンプレート）も並びとして読める', () {
      for (final kind in ProjectsKind.values) {
        expect(projectRecordsOfYaml(_asset(kind)), isNotEmpty);
      }
    });

    test('異常系：先頭が Map でない・projects の並びがない・書き方の誤り', () {
      expect(() => recordOfYaml('- a\n'), throwsFormatException);
      expect(() => recordOfYaml('just text'), throwsFormatException);
      expect(() => projectRecordsOfYaml('home: {}\n'), throwsFormatException);
      expect(() => projectRecordsOfYaml('projects: text\n'), throwsFormatException);
      expect(() => recordOfYaml('projects: [\n'), throwsA(isA<YamlException>()));
    });
  });

  group('LocalPortfolioRepository：Work / Private（文字）', () {
    for (final kind in ProjectsKind.values) {
      test('${kind.name}：何もなければサンプル（サンプルと判定）', () async {
        expect(await repo.loadProjectsText(kind), _asset(kind));
        expect(await repo.isSampleProjects(kind), isTrue);
      });

      test('${kind.name}：保存した文字をそのまま読み（コメントも残る）、サンプルではなくなる。消すとサンプルに戻る', () async {
        await repo.saveProjectsText(kind, _workYaml);
        expect(SessionStore.read(kind.name), _workYaml);
        expect(await repo.loadProjectsText(kind), _workYaml);
        expect(await repo.isSampleProjects(kind), isFalse);

        await repo.clearProjects(kind);
        expect(SessionStore.read(kind.name), isNull);
        expect(await repo.isSampleProjects(kind), isTrue);
      });

      test('${kind.name}：空文字の保存は無視してサンプルを読む（ただしサンプルとは判定しない）', () async {
        await repo.saveProjectsText(kind, '');
        expect(await repo.loadProjectsText(kind), _asset(kind));
        expect(await repo.isSampleProjects(kind), isFalse);
      });
    }

    test('起動時に一緒に指定したものは、保存したものの次に使う', () async {
      LocalPortfolioRepository.fromArg = true;
      loadAssetText = (path) async {
        if (path == LocalPortfolioRepository.workAssetPath) return 'projects:\n  - title: 起動\n';
        throw Exception('ない');
      };
      expect(await repo.loadProjectsText(ProjectsKind.work), contains('起動'));
      expect(await repo.isSampleProjects(ProjectsKind.work), isFalse);

      await repo.saveProjectsText(ProjectsKind.work, 'projects:\n  - title: 保存\n');
      expect(await repo.loadProjectsText(ProjectsKind.work), contains('保存'));
    });

    test('異常系：起動時の指定もサンプルも読めなければエラー', () async {
      LocalPortfolioRepository.fromArg = true;
      loadAssetText = (_) => Future.error(Exception('読めない'));
      expect(await LocalPortfolioRepository.startupProjects(ProjectsKind.private), isNull);
      await expectLater(repo.loadProjectsText(ProjectsKind.private), throwsException);
    });

    test('起動時に指定していなければ、起動時のファイルは読まない', () async {
      final asked = <String>[];
      loadAssetText = (path) async {
        asked.add(path);
        return 'projects: []\n';
      };
      expect(await LocalPortfolioRepository.startupProjects(ProjectsKind.work), isNull);
      await repo.loadProjectsText(ProjectsKind.work);
      expect(asked, ['assets/data/format_work.yaml']);
    });
  });

  group('LocalPortfolioRepository：Work / Private（構造のデータ）', () {
    test('自分のデータがなければ null、表示するのはサンプルの並び', () async {
      expect(await repo.loadProjectRecords(ProjectsKind.work), isNull);
      expect(await repo.loadProjects(ProjectsKind.work), projectRecordsOfYaml(_asset(ProjectsKind.work)));
    });

    test('保存した文字を並びとして読む。並びで保存すると、読み直しても同じ中身', () async {
      await repo.saveProjectsText(ProjectsKind.private, _workYaml);
      expect((await repo.loadProjectRecords(ProjectsKind.private))!.single['title'], '保存した業務');
      expect((await repo.loadProjects(ProjectsKind.private)).single['title'], '保存した業務');

      final records = [
        {'title': '並びで保存', 'skills': ['Go']},
      ];
      await repo.saveProjectRecords(ProjectsKind.private, records);
      expect(await repo.loadProjectRecords(ProjectsKind.private), records);
      expect(await repo.isSampleProjects(ProjectsKind.private), isFalse);
    });

    test('起動時に一緒に指定したものも並びとして読む', () async {
      LocalPortfolioRepository.fromArg = true;
      loadAssetText = (path) async =>
          path == LocalPortfolioRepository.workAssetPath ? 'projects:\n  - title: 起動\n' : File(path).readAsStringSync();
      expect((await repo.loadProjectRecords(ProjectsKind.work))!.single['title'], '起動');
    });

    test('異常系：保存した文字が壊れていればエラー（画面は空の表示になる）', () async {
      await repo.saveProjectsText(ProjectsKind.work, 'projects: [\n');
      await expectLater(repo.loadProjects(ProjectsKind.work), throwsA(isA<YamlException>()));
      await repo.saveProjectsText(ProjectsKind.work, '- title: A\n');
      await expectLater(repo.loadProjects(ProjectsKind.work), throwsFormatException);
    });
  });

  group('LocalPortfolioRepository：プロフィール', () {
    test('何もなければ null・理由なし（構造のデータも null）', () async {
      final result = await repo.loadProfile();
      expect(result.profile, isNull);
      expect(result.errors, isEmpty);
      expect(await repo.loadProfileRecord(), isNull);
    });

    test('保存したものを読む（構造のデータでも）', () async {
      await repo.saveProfile(_profileYaml);
      expect(SessionStore.read(LocalPortfolioRepository.profileSessionKey), _profileYaml);
      expect((await repo.loadProfile()).profile?.name, 'リポジトリ 太郎');
      expect(await repo.loadProfileRecord(), recordOfYaml(_profileYaml));
    });

    test('構造のデータで保存しても、プロフィールとして読める', () async {
      await repo.saveProfileRecord(recordOfYaml(_profileYaml.replaceFirst('リポジトリ 太郎', '構造 次郎')));
      expect((await repo.loadProfile()).profile?.name, '構造 次郎');
    });

    test('異常系：保存したものが壊れていれば null', () async {
      await repo.saveProfile('home: [');
      expect((await repo.loadProfile()).profile, isNull);
      expect(await repo.loadProfileRecord(), isNull);
    });

    test('起動時に指定：正しければそれを使う（保存したものより先。構造のデータも）', () async {
      LocalPortfolioRepository.fromArg = true;
      await repo.saveProfile(_profileYaml.replaceFirst('リポジトリ 太郎', '保存 花子'));
      loadAssetText = (path) async => path == LocalPortfolioRepository.profileAssetPath ? _profileYaml : '';
      final result = await repo.loadProfile();
      expect(result.profile?.name, 'リポジトリ 太郎');
      expect(result.errors, isEmpty);
      expect(((await repo.loadProfileRecord())!['home'] as Map)['name'], 'リポジトリ 太郎');
    });

    test('起動時に指定：正しくなければ理由を返し、保存したものを使う（構造のデータも保存したもの）', () async {
      LocalPortfolioRepository.fromArg = true;
      await repo.saveProfile(_profileYaml);
      loadAssetText = (_) async => 'home:\n  name: 名前だけ\n';
      final result = await repo.loadProfile();
      expect(result.errors, isNotEmpty);
      expect(result.profile?.name, 'リポジトリ 太郎');
      expect(await repo.loadProfileRecord(), recordOfYaml(_profileYaml));
    });

    test('起動時に指定：ファイルがなく、保存したものもなければ、理由だけ', () async {
      LocalPortfolioRepository.fromArg = true;
      loadAssetText = (_) => Future.error(Exception('ファイルがありません'));
      final result = await repo.loadProfile();
      expect(result.profile, isNull);
      expect(result.errors.single, contains('ファイルがありません'));
    });

    test('ProfileStore.fromArg は LocalPortfolioRepository.fromArg と同じもの', () {
      ProfileStore.fromArg = true;
      expect(LocalPortfolioRepository.fromArg, isTrue);
      LocalPortfolioRepository.fromArg = false;
      expect(ProfileStore.fromArg, isFalse);
    });
  });

  group('構造のデータの 5 つだけの実装に差し替えても、そのまま動く（Firestore の実装の代わり）', () {
    late _RecordsOnlyRepository fake;

    setUp(() {
      fake = _RecordsOnlyRepository();
      PortfolioRepository.instance = fake;
    });

    test('instance を差し替え、reset で元の実装に戻る', () {
      expect(PortfolioRepository.instance, same(fake));
      PortfolioRepository.reset();
      expect(PortfolioRepository.instance, isA<LocalPortfolioRepository>());
    });

    test('自分のデータがなければサンプル（文字・並びとも）', () async {
      expect(await fake.isSampleProjects(ProjectsKind.work), isTrue);
      expect(await fake.loadProjectsText(ProjectsKind.work), _asset(ProjectsKind.work));
      expect(await fake.loadProjects(ProjectsKind.work), projectRecordsOfYaml(_asset(ProjectsKind.work)));
    });

    test('文字で保存すると並びで持ち、文字で読むと同じ中身の YAML', () async {
      await fake.saveProjectsText(ProjectsKind.work, _workYaml);
      expect(fake.projects[ProjectsKind.work]!.single['title'], '保存した業務');
      expect(await fake.isSampleProjects(ProjectsKind.work), isFalse);
      expect(projectRecordsOfYaml(await fake.loadProjectsText(ProjectsKind.work)), projectRecordsOfYaml(_workYaml));
    });

    test('異常系：保存する文字が Work / Private の形でなければ保存しない（エラー）', () async {
      await expectLater(fake.saveProjectsText(ProjectsKind.work, 'just text'), throwsFormatException);
      expect(fake.projects, isEmpty);
    });

    test('ローダーの読み書きは Repository を通る（sessionStorage には書かない）', () async {
      await WorkYamlLoader.setCustomYaml('projects:\n  - title: 偽物\n');
      expect(await WorkYamlLoader.loadYamlString(), contains('偽物'));
      expect((await WorkYamlLoader.loadWorkYamlMap())['projects'], hasLength(1));
      expect(await PrivateYamlLoader.loadYamlString(), _asset(ProjectsKind.private));
      await WorkYamlLoader.clearCustomYaml();
      await PrivateYamlLoader.clearCustomYaml();
      expect(fake.calls, containsAllInOrder(['save:work', 'load:work', 'load:private', 'clear:work', 'clear:private']));
      expect(SessionStore.read('work'), isNull);
    });

    test('プロフィール：構造のデータから Profile を作り、保存は構造のデータで', () async {
      expect((await fake.loadProfile()).profile, isNull);

      fake.profile = recordOfYaml(_profileYaml);
      await ProfileStore.instance.load();
      expect(ProfileStore.instance.value?.name, 'リポジトリ 太郎');

      const updated = 'home:\n  name: 更新 次郎\n  role: r\n  tagline: t\nabout:\n  intro: i\n';
      await ProfileStore.instance.setUploaded(updated, Profile.parse(updated).profile!);
      expect((fake.profile!['home'] as Map)['name'], '更新 次郎');
      expect(ProfileStore.instance.value?.name, '更新 次郎');
      expect(fake.calls, ['loadProfile', 'loadProfile', 'saveProfile']);
      expect(SessionStore.read(ProfileStore.sessionKey), isNull);
    });
  });
}
