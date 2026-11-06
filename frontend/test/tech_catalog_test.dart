// Skills・Tools に書かれた技術を本来の分類に振り分けるテスト
// 対象：lib/utils/tech_catalog.dart（classifyTech / redistributeProject）・Project.fromMap・Skills の集計
//
// 実行：flutter test test/tech_catalog_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/skills/data/skills_aggregator.dart';
import 'package:dev_portfolio/utils/tech_catalog.dart';

void main() {
  test('classifyTech：表記ゆれを無視して分類を返す', () {
    expect(classifyTech('React')?.$1, 'frontend_frameworks');
    expect(classifyTech('NodeJS')?.$1, 'backend_frameworks');
    expect(classifyTech('vue_js')?.$1, 'frontend_frameworks');
    expect(classifyTech('Python')?.$1, 'skills');
    expect(classifyTech('AWS Lambda'), ('aws_services', 'AWS'));
    expect(classifyTech('Git')?.$1, 'tools');
    expect(classifyTech('MyTool'), isNull);
  });

  test('k8s・Kubernetes・OpenShift はコンテナオーケストレーション、Red Hat はクラウド、Bitbucket は Tools、Mocha は Testing', () {
    for (final n in ['k8s', 'Kubernetes', 'K8s クラスタ', 'OpenShift', 'Open Shift', 'Red Hat OpenShift']) {
      expect(classifyTech(n)?.$1, 'container_orchestration', reason: n);
    }
    expect(classifyTech('Red Hat')?.$1, 'cloud_platforms');
    expect(classifyTech('RedHat')?.$1, 'cloud_platforms');
    expect(classifyTech('bitBucket')?.$1, 'tools');
    expect(toolGroupOf('bitBucket'), ToolGroup.vcs);
    for (final n in ['Mocha', 'mocha test', 'Mocha Test', 'JUnit5', 'Jest テスト']) {
      expect(classifyTech(n)?.$1, 'testing_frameworks', reason: n);
    }
    // Skills に書いても本来の分類へ
    final m = redistributeProject({
      'title': 'x',
      'skills': ['k8s', 'Red Hat', 'Bitbucket', 'mocha test', 'Python'],
    });
    expect(m['skills'], ['Python']);
    expect(m['container_orchestration'], ['k8s']);
    expect(m['cloud_platforms'], ['Red Hat']);
    expect(m['tools'], ['Bitbucket']);
    expect(m['testing_frameworks'], ['mocha test']);
  });

  group('redistributeProject', () {
    final moved = redistributeProject({
      'title': 'x',
      'skills': ['Python', 'React', 'Django', 'Lambda'],
      'tools': ['Git', 'Docker', 'TypeScript', 'pytest'],
      'frontend_frameworks': ['利用なし'],
      'backend_frameworks': ['django'],
      'cloud_platforms': ['利用なし'],
    });

    test('Skills・Tools のフロントエンド・バックエンドなどを本来の分類に移す', () {
      expect(moved['skills'], ['Python', 'TypeScript']);
      expect(moved['tools'], ['Git']);
      expect(moved['frontend_frameworks'], ['React']); // 「利用なし」は外す
      expect(moved['backend_frameworks'], ['django']); // すでにあるもの（表記ゆれ）は 2 つ入れない
      expect(moved['container'], ['Docker']);
      expect(moved['testing_frameworks'], ['pytest']);
      expect(moved['aws_services'], ['Lambda']);
      expect(moved['cloud_platforms'], ['AWS']);
    });

    test('移して空になった分類は「利用なし」。知らない名前はそのまま', () {
      final m = redistributeProject({
        'title': 'y',
        'skills': ['React'],
        'tools': 'Git, MyTool',
      });
      expect(m['skills'], ['利用なし']);
      expect(m['tools'], 'Git, MyTool'); // 動かすものがなければ元のまま
      expect(m['frontend_frameworks'], ['React']);
    });

    test('元の Map は変えない', () {
      final original = {
        'title': 'z',
        'skills': ['React'],
      };
      redistributeProject(original);
      expect(original['skills'], ['React']);
    });
  });

  test('Project（一覧・フィルター）でも分かれる', () {
    final p = Project.fromMap({
      'title': 'x',
      'skills': ['Python', 'Next.js'],
      'tools': ['Spring Boot', 'GitHub'],
    });
    expect(p.skillsList, ['Python']);
    expect(p.frontendList, ['Next.js']);
    expect(p.backendList, ['Spring Boot']);
    expect(p.toolsList, ['GitHub']);
  });

  test('Skills の集計でも分かれる', () {
    final projects = redistributeProjects(loadYaml('''
- title: a
  skills: [Python, React]
  tools: [Git, Django]
''') as YamlList);
    expect(aggregateCategory(projects, 'skills').keys, ['Python']);
    expect(aggregateCategory(projects, 'frontend_frameworks').keys, ['React']);
    expect(aggregateCategory(projects, 'backend_frameworks').keys, ['Django']);
    expect(aggregateCategory(projects, 'tools').keys, ['Git']);
  });

  group('Tools のグループ分け（名前から推測）', () {
    test('よく知られた名前（表記ゆれは無視）', () {
      expect(toolGroupOf('Git'), ToolGroup.vcs);
      expect(toolGroupOf('gitlab'), ToolGroup.vcs);
      expect(toolGroupOf('VSCode'), ToolGroup.devTool);
      expect(toolGroupOf('Tera Term'), ToolGroup.devTool);
      expect(toolGroupOf('WSL2'), ToolGroup.environment);
      expect(toolGroupOf('Apache'), ToolGroup.environment);
      expect(toolGroupOf('GitHub Actions'), ToolGroup.ciCd);
      expect(toolGroupOf('Backlog'), ToolGroup.projectManagement);
      expect(toolGroupOf('Slack'), ToolGroup.projectManagement);
      expect(toolGroupOf('Figma'), ToolGroup.design);
    });

    test('一覧にない名前は、含まれる言葉で推測し、わからなければその他', () {
      expect(toolGroupOf('GitBucket'), ToolGroup.vcs);
      expect(toolGroupOf('社内 Jira'), ToolGroup.projectManagement);
      expect(toolGroupOf('検証サーバ'), ToolGroup.environment);
      expect(toolGroupOf('MyTool'), ToolGroup.other);
    });

    test('Skills の集計：Tools をグループごとのカテゴリに分ける', () {
      final groups = splitToolGroups([
        {'tools': ['Git', 'GitHub', 'VS Code', 'WSL', 'MyTool', '利用なし']},
        {'tools': 'Git, Jira'},
      ]);
      expect(aggregateCategory(groups, ToolGroup.vcs.key).keys.toSet(), {'Git', 'GitHub'});
      expect(aggregateCategory(groups, ToolGroup.vcs.key)['Git'], closeTo(2 / 3 * 100, 0.001));
      expect(aggregateCategory(groups, ToolGroup.devTool.key).keys, ['VS Code']);
      expect(aggregateCategory(groups, ToolGroup.environment.key).keys, ['WSL']);
      expect(aggregateCategory(groups, ToolGroup.projectManagement.key).keys, ['Jira']);
      expect(aggregateCategory(groups, ToolGroup.other.key).keys, ['MyTool']);
      expect(aggregateCategory(groups, ToolGroup.design.key), isEmpty);
    });
  });

  group('Skills のグループ分け（名前から推測）', () {
    test('よく知られた名前', () {
      expect(skillGroupOf('Python'), SkillGroup.language);
      expect(skillGroupOf('dart'), SkillGroup.language);
      expect(skillGroupOf('HTML'), SkillGroup.markup);
      expect(skillGroupOf('SCSS'), SkillGroup.markup);
      expect(skillGroupOf('SQL'), SkillGroup.data);
      expect(skillGroupOf('YAML'), SkillGroup.data);
      expect(skillGroupOf('REST API'), SkillGroup.architecture);
      expect(skillGroupOf('マイクロサービス'), SkillGroup.architecture);
      expect(skillGroupOf('オニオンモデル'), SkillGroup.architecture);
      expect(skillGroupOf('Onion Architecture'), SkillGroup.architecture);
      expect(skillGroupOf('オニオン構成'), SkillGroup.architecture); // 一覧にない書き方も「オニオン」で推測
      expect(skillGroupOf('pandas'), SkillGroup.library);
      expect(skillGroupOf('fl_chart'), SkillGroup.library);
    });

    test('版の付いた言語・パッケージらしい名前・含まれる言葉で推測し、わからなければその他', () {
      expect(skillGroupOf('Python3'), SkillGroup.language);
      expect(skillGroupOf('PHP7.4'), SkillGroup.language);
      expect(skillGroupOf('url_launcher'), SkillGroup.library);
      expect(skillGroupOf('file_picker'), SkillGroup.library);
      expect(skillGroupOf('Anime.js'), SkillGroup.library);
      expect(skillGroupOf('MySQL 8 のクエリ'), SkillGroup.data);
      expect(skillGroupOf('Web API 設計'), SkillGroup.architecture);
      expect(skillGroupOf('業務知識'), SkillGroup.other);
    });

    test('Skills の集計：Skills をグループごとのカテゴリに分ける', () {
      final groups = splitSkillGroups([
        {'skills': ['Python', 'Dart', 'HTML', 'CSS', 'YAML', 'fl_chart', 'MVC', '業務知識']},
      ]);
      expect(aggregateCategory(groups, SkillGroup.language.key).keys.toSet(), {'Python', 'Dart'});
      expect(aggregateCategory(groups, SkillGroup.markup.key).keys.toSet(), {'HTML', 'CSS'});
      expect(aggregateCategory(groups, SkillGroup.data.key).keys, ['YAML']);
      expect(aggregateCategory(groups, SkillGroup.library.key).keys, ['Fl Chart']);
      expect(aggregateCategory(groups, SkillGroup.architecture.key).keys, ['MVC']);
      expect(aggregateCategory(groups, SkillGroup.other.key).keys, ['業務知識']);
    });
  });
}
