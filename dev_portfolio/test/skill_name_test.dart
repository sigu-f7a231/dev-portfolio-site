// 技術名の表記ゆれをそろえる処理のテスト
// 対象：lib/utils/skill_name.dart・lib/sections/skills/data/skills_aggregator.dart（aggregateCategory）
//
// 実行：flutter test test/skill_name_test.dart（dev_portfolio/ で）
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/sections/projects/filters/logic/project_filter_logic.dart';
import 'package:dev_portfolio/sections/projects/filters/state/project_filter_state.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/skills/data/skills_aggregator.dart';
import 'package:dev_portfolio/utils/skill_name.dart';

void main() {
  group('cleanSkillName：前後の余分な記号・全角を直す', () {
    test('末尾の ; : . / などを外す', () {
      expect(cleanSkillName('Git;'), 'Git');
      expect(cleanSkillName('Docker：'), 'Docker');
      expect(cleanSkillName('mac.'), 'mac');
      expect(cleanSkillName('mac/'), 'mac');
      expect(cleanSkillName(' - Python , '), 'Python');
    });

    test('名前の一部の記号は残す', () {
      expect(cleanSkillName('.NET'), '.NET');
      expect(cleanSkillName('C++'), 'C++');
      expect(cleanSkillName('C#'), 'C#');
      expect(cleanSkillName('Node.js'), 'Node.js');
      expect(cleanSkillName('CI/CD'), 'CI/CD');
    });

    test('全角の英数字は半角に', () {
      expect(cleanSkillName('Python３'), 'Python3');
      expect(cleanSkillName('ＰＨＰ'), 'PHP');
    });
  });

  group('skillKey：同じものとみなすか', () {
    test('大文字・小文字・全角・前後の記号・空白は無視する', () {
      for (final s in ['MAC', 'mac', 'Mac', 'mac.', 'mac/', 'ｍａｃ']) {
        expect(skillKey(s), skillKey('Mac'), reason: s);
      }
      expect(skillKey('git'), skillKey('GIT'));
      expect(skillKey('PYTHON3'), skillKey('Python３'));
      expect(skillKey('Python'), skillKey('PYTHON'));
      expect(skillKey('VS Code'), skillKey('VSCode'));
      expect(skillKey('github_actions'), skillKey('GitHubActions'));
      expect(skillKey('Node.js'), skillKey('NodeJS'));
    });

    test('数字の違いは別のもの', () {
      expect(skillKey('Python'), isNot(skillKey('Python3')));
      expect(skillKey('Python2'), isNot(skillKey('Python3')));
    });
  });

  group('表示する名前', () {
    test('よく知られた名前は正式な書き方', () {
      expect(uniqueSkillNames(['git', 'GIT;', 'git']), ['Git']);
      expect(uniqueSkillNames(['MAC', 'mac', 'mac.']), ['Mac']);
      expect(uniqueSkillNames(['github_actions', 'GitHubActions', 'GITHUB-ACTIONS']), ['GitHub Actions']);
      expect(uniqueSkillNames(['nodejs', 'NodeJS', 'node.js']), ['Node.js']);
      expect(uniqueSkillNames(['macos', 'MacOS', 'mac_os']), ['macOS']);
    });

    test('知らない名前は、大文字と小文字が混ざった書き方を優先し、次に多い書き方', () {
      expect(uniqueSkillNames(['PYTHON3', 'Python３', 'PYTHON3']), ['Python3']);
      expect(uniqueSkillNames(['FOO_BAR', 'fooBar', 'foo_bar']), ['fooBar']);
      expect(uniqueSkillNames(['ABC', 'abc', 'ABC']), ['ABC']);
    });

    test('小文字だけ・スネークケースだけなら、単語の頭を大文字にして「_」は空白に', () {
      expect(uniqueSkillNames(['my_tool', 'MY_TOOL']), ['My Tool']);
      expect(uniqueSkillNames(['python4']), ['Python4']);
    });
  });

  group('クラウドのサービス：先頭の AWS / Amazon / Azure / GCP などを外してまとめる', () {
    test('AWS Lambda と Lambda は同じ（表示は外した名前）', () {
      expect(uniqueSkillNames(['AWS Lambda', 'Lambda', 'aws lambda', 'Amazon S3', 'S3'],
          category: 'aws_services'), ['Lambda', 'S3']);
      expect(uniqueSkillNames(['AWS Lamdba', 'Lamdba'], category: 'aws_services'), ['Lamdba']);
      expect(uniqueSkillNames(['Azure Functions', 'Functions', 'Microsoft Azure App Service'],
          category: 'azure_services'), ['Functions', 'App Service']);
      expect(uniqueSkillNames(['GCP Cloud Run', 'Google Cloud Cloud Run', 'Cloud Run'],
          category: 'gcp_services'), ['Cloud Run']);
    });

    test('ほかの分類では外さない・外すと空になるときはそのまま', () {
      expect(uniqueSkillNames(['AWS Lambda', 'Lambda']), ['AWS Lambda', 'Lambda']);
      expect(uniqueSkillNames(['AWS'], category: 'aws_services'), ['AWS']);
    });

    test('Skills の集計でも 1 つにまとまり、1 つのプロジェクトの中で重なっていても 1 回と数える', () {
      final projects = loadYaml('''
- aws_services: [AWS Lambda, Lambda, Amazon S3, Lamdba, AWS Lamdba]
- aws_services: [lambda, S3, S3]
''') as YamlList;
      final result = aggregateCategory(projects, 'aws_services');
      expect(result.keys.toSet(), {'Lambda', 'S3', 'Lamdba'});
      // Lambda：各プロジェクト 1 回ずつ＝2、S3：2、Lamdba：1（合計 5）
      expect(result['Lambda'], closeTo(2 / 5 * 100, 0.001));
      expect(result['S3'], closeTo(2 / 5 * 100, 0.001));
      expect(result['Lamdba'], closeTo(1 / 5 * 100, 0.001));
    });

    test('プロジェクトの一覧・フィルターでも、同じものは 1 つ', () {
      final p = Project.fromMap({
        'title': 'x',
        'aws_services': ['AWS Lambda', 'Lambda', 'Lamdba', 'AWS Lamdba'],
        'tools': ['git', 'Git;', 'GIT'],
      });
      expect(p.awsList, ['Lambda', 'Lamdba']);
      expect(p.toolsList, ['Git']);
    });
  });

  test('Skills の集計：表記ゆれは 1 つにまとめ、1 つのプロジェクトの中で重なっていても 1 回と数える', () {
    final projects = loadYaml('''
- skills: [Python, PYTHON, Python3, "Python３"]
- skills: [python, Python2, 利用なし, "利用なし;"]
''') as YamlList;
    final result = aggregateCategory(projects, 'skills');
    expect(result.keys.toSet(), {'Python', 'Python3', 'Python2'});
    // 1 つのプロジェクトの中で同じものは 1 回：1 件目 Python・Python3、2 件目 Python・Python2（合計 4）
    expect(result['Python'], closeTo(2 / 4 * 100, 0.001));
    expect(result['Python3'], closeTo(1 / 4 * 100, 0.001));
    expect(result['Python2'], closeTo(1 / 4 * 100, 0.001));
  });

  group('Projects のフィルター：AI・クラウドのサービス・コンテナでも絞り込める', () {
    final projects = [
      Project.fromMap({
        'title': 'A',
        'aws_services': ['AWS Lambda'],
        'ai_services': ['ChatGPT'],
        'container': ['docker'],
      }),
      Project.fromMap({
        'title': 'B',
        'gcp_services': ['GCP Cloud Run'],
        'azure_services': ['Azure Functions'],
      }),
    ];
    List<String> titles(String key, List<String> values) {
      final state = ProjectFilterState.initial();
      state.selectedFilters[key] = values;
      return ProjectFilterLogic.apply(projects, state).map((p) => p.title).toList();
    }

    test('AWS / GCP / Azure は先頭の「AWS」などを外して比べる', () {
      expect(titles('awsServices', ['Lambda']), ['A']);
      expect(titles('gcpServices', ['Cloud Run']), ['B']);
      expect(titles('azureServices', ['Functions']), ['B']);
    });

    test('AI・コンテナ（表記ゆれも無視）', () {
      expect(titles('aiServices', ['ChatGPT']), ['A']);
      expect(titles('container', ['Docker']), ['A']);
    });

    test('候補の表示：プロジェクトの一覧の AWS は先頭を外した名前', () {
      expect(projects.first.awsList, ['Lambda']);
    });
  });
}
