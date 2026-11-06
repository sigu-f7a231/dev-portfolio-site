// 役割・規模（プロジェクト）と、スキルシートだけの個人の項目（プロフィールの sheet）のテスト
// 対象：lib/utils/skill_sheet.dart（roleAndScaleOf・読み込み）・lib/sections/projects/models/projects_model.dart・
//       lib/sections/projects/filters/logic/project_filter_logic.dart・lib/models/profile.dart
//
// 実行：flutter test test/project_role_scale_test.dart（frontend/ で）
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/sections/header/project_form.dart';
import 'package:dev_portfolio/sections/projects/filters/logic/project_filter_logic.dart';
import 'package:dev_portfolio/sections/projects/filters/state/project_filter_state.dart';
import 'package:dev_portfolio/sections/projects/filters/ui/project_active_filters.dart';
import 'package:dev_portfolio/sections/projects/filters/ui/project_filter_panel.dart';
import 'package:dev_portfolio/sections/projects/models/projects_model.dart';
import 'package:dev_portfolio/sections/projects/views/project_list/project_list_modal_function.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/data_format.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';
import 'package:dev_portfolio/utils/project_append.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/widgets/tag_input_field.dart';

import 'test_xlsx.dart';

Project _p(String title, {Object? role, String scale = ''}) =>
    Project.fromMap({'title': title, 'role': role, 'scale': scale});

ProjectFilterState _filter(Map<String, List<String>> f) {
  final s = ProjectFilterState.initial().copyFilters()..addAll(f);
  return ProjectFilterState(selectedFilters: s);
}

void main() {
  group('Excel の「役割 / 規模」の読み分け（roleAndScaleOf）', () {
    test('見出しのない行：人数があれば規模、それ以外は役割（/ ・ 、 で分ける）', () {
      final r = roleAndScaleOf(['', 'PL / SE\n全体 20名（チーム 5名）']);
      expect(r.role, ['PL', 'SE']);
      expect(r.scale, '全体 20名（チーム 5名）');
    });

    test('「役割：」「規模：」の見出しに従う', () {
      final r = roleAndScaleOf(['役割：PG・テスター', '規模：大規模（３０人）']);
      expect(r.role, ['PG', 'テスター']);
      expect(r.scale, '大規模（３０人）');
    });

    test('テンプレートのサンプル（PG だけ）', () {
      final r = roleAndScaleOf(['PG']);
      expect(r.role, ['PG']);
      expect(r.scale, '');
    });
  });

  group('Project の役割・規模', () {
    test('role は文字でも並びでもよい。規模の人数と区分', () {
      expect(_p('a', role: ['PL', 'SE']).roleList, ['PL', 'SE']);
      expect(_p('a', role: 'PG').roleList, ['PG']);
      final p = _p('a', scale: '全体 20名（チーム 5名）');
      expect(p.scalePeople, 20);
      expect(p.scaleBucket, '11〜30名');
      expect(_p('a', scale: '３人').scaleBucket, '〜5名');
      expect(_p('a', scale: '150名').scaleBucket, '101名〜');
      expect(_p('a', scale: '大規模').scaleBucket, isNull);
      expect(_p('a').scaleBucket, isNull);
    });

    test('フィルター：役割は選んだものをすべて担当、規模は選んだ区分のどれか', () {
      final projects = [
        _p('A', role: ['PL', 'SE'], scale: '20名'),
        _p('B', role: ['SE'], scale: '4名'),
        _p('C', role: ['PG'], scale: '200名'),
      ];
      List<String> titles(Map<String, List<String>> f) =>
          [for (final p in ProjectFilterLogic.apply(projects, _filter(f))) p.title];

      expect(titles({'role': ['SE']}), ['A', 'B']);
      expect(titles({'role': ['SE', 'PL']}), ['A']);
      expect(titles({'scale': ['〜5名', '101名〜']}), ['B', 'C']);
      expect(titles({'role': ['SE'], 'scale': ['11〜30名']}), ['A']);
    });
  });

  group('プロフィールの sheet（スキルシートだけの項目）', () {
    String profile(String sheet) => '''
home:
  name: 山田 太郎
  role: エンジニア
  tagline: 紹介
about:
  intro: 自己紹介
$sheet''';

    test('読める。空の項目は入れない', () {
      final r = Profile.parse(profile('sheet:\n  gender: 男\n  furigana: ""\n  station: ○○駅\n'));
      expect(r.errors, isEmpty);
      expect(r.profile!.sheet, {'gender': '男', 'station': '○○駅'});
    });

    test('知らないキーはエラー', () {
      final r = Profile.parse(profile('sheet:\n  blood: A\n'));
      expect(r.errors.single, contains('sheet.blood'));
    });

    test('テンプレート（YAML / Markdown）にあり、同じ中身', () {
      Map<String, String> sheetOf(String file) =>
          readProfileBundle(File('assets/data/$file').readAsStringSync(), fileName: file)
              .profile!
              .sheet;
      final yaml = sheetOf('format_profile.yaml');
      expect(yaml['birthday'], '1990年04月01日');
      expect(sheetOf('format_profile.md'), yaml);
    });

    test('Excel のテンプレートから読む（年齢は生年月日が読めるので持たない）', () {
      final result = convertSkillSheet(File(skillSheetTemplateAsset).readAsBytesSync());
      final doc = jsonDecode(jsonEncode(loadYaml(result.yamlText!))) as Map<String, dynamic>;
      expect(doc['sheet'], {
        'gender': '男',
        'birthday': '1990年04月01日',
        'nationality': '日本',
        'spouse': '無',
        'station': '○○駅',
        'education': '○○専門学校　○○学科',
      });
      expect(doc['work'][0]['role'], ['PG']);
      expect(doc['work'][0]['scale'], '');
    });

    test('生年月日の書き方', () {
      expect(parseSheetDate('1990年04月01日'), (1990, 4, 1));
      expect(parseSheetDate('１９９０/４/１'), (1990, 4, 1));
      expect(parseSheetDate('1990-13-01'), isNull);
      expect(parseSheetDate('不明'), isNull);
    });
  });

  group('Excel の「役割 / 規模」の読み分け：そのほか', () {
    test('空のセル・空行は無視。同じ役割は 1 つ', () {
      final r = roleAndScaleOf(['', '\n', 'SE\nSE / PG']);
      expect(r.role, ['SE', 'PG']);
      expect(r.scale, '');
    });

    test('規模が複数行なら「 / 」でつなぐ。「体制」「チーム」の言葉でも規模', () {
      final r = roleAndScaleOf(['PL', '全体 30名', 'チーム 5名', '少人数体制']);
      expect(r.role, ['PL']);
      expect(r.scale, '全体 30名 / チーム 5名 / 少人数体制');
    });

    test('「ポジション：」は役割、「人数：」は規模。区切り（、 ， ／）も', () {
      final r = roleAndScaleOf(['ポジション：PM、PMO／PL', '人数：8人']);
      expect(r.role, ['PM', 'PMO', 'PL']);
      expect(r.scale, '8人');
    });

    test('見出しだけで中身が空の「規模：」は入れない', () {
      expect(roleAndScaleOf(['PG', '規模：']).scale, '');
    });
  });

  group('Excel の読み込み（小さなシート）', () {
    const experience = '直近の開発経験\n\nWeb開発：テスト';
    Map<String, String> sheet({Map<String, String> extra = const {}}) => {
          'A1': '氏名', 'C1': '鈴木 花子',
          'A2': 'ふりがな', 'C2': '性別', 'D2': '女', 'E2': '生年月日', 'F2': '1995/7/20', 'G2': '年齢', 'H2': '31',
          'A3': '国籍', 'B3': '日本', 'C3': '最寄り駅', 'D3': '渋谷駅',
          'A4': experience,
          'A6': 'No.', 'B6': '期間', 'C6': 'プロジェクト名\n業務概要', 'D6': '役割\n規模', 'E6': '使用言語',
          'A7': '1', 'B7': '2024/4', 'C7': '案件A', 'D7': 'PL / SE', 'E7': 'Python',
          'C8': '概要：\n説明', 'D8': '全体 20名（チーム 5名）', 'B9': '2024/9',
          'A10': '2', 'B10': '2025/1', 'C10': '案件B', 'E10': 'Dart',
          ...extra,
        };
    Map<String, dynamic> read(Map<String, String> cells) {
      final result = convertSkillSheet(testXlsx(cells), fileName: 'x.xlsx');
      expect(result.errors, isEmpty);
      return jsonDecode(jsonEncode(loadYaml(result.yamlText!))) as Map<String, dynamic>;
    }

    test('役割・規模の列（見出しに「役割」「規模」）を読む。ない案件は [] と ""', () {
      final doc = read(sheet());
      final work = (doc['work'] as List).cast<Map<String, dynamic>>();
      expect(work[0]['role'], ['PL', 'SE']);
      expect(work[0]['scale'], '全体 20名（チーム 5名）');
      expect(work[1]['role'], isEmpty);
      expect(work[1]['scale'], '');
    });

    test('個人の項目：右の値。値がなく次の見出しが来たら入れない（ふりがな）。「最寄り駅」も読む', () {
      final doc = read(sheet());
      expect(doc['sheet'], {
        'gender': '女',
        'birthday': '1995/7/20',
        'nationality': '日本',
        'station': '渋谷駅',
      });
    });

    test('生年月日が読めなければ、年齢を持っておく', () {
      final doc = read(sheet(extra: {'F2': '非公開'}));
      expect(doc['sheet']['birthday'], '非公開');
      expect('${doc['sheet']['age']}', '31');
    });

    test('日付の書式のセル（Excel の日付の数）も生年月日として読む', () {
      final doc = read(sheet(extra: {'F2': '34900'})); // 1995-07-20
      expect(doc['sheet']['birthday'], '1995年07月20日');
    });

    test('作った YAML は、プロフィールとして読める（sheet も入る）', () {
      final result = convertSkillSheet(testXlsx(sheet()), fileName: 'x.xlsx');
      final bundle = readProfileBundle(result.yamlText!, fileName: 'x.yaml');
      expect(bundle.errors, isEmpty);
      expect(bundle.profile!.sheet['gender'], '女');
      expect(bundle.workCount, 2);
    });
  });

  group('規模の区分の境目', () {
    for (final (people, bucket) in [
      (1, '〜5名'),
      (5, '〜5名'),
      (6, '6〜10名'),
      (10, '6〜10名'),
      (11, '11〜30名'),
      (30, '11〜30名'),
      (31, '31〜100名'),
      (100, '31〜100名'),
      (101, '101名〜'),
    ]) {
      test('$people名 → $bucket', () => expect(_p('a', scale: '$people名').scaleBucket, bucket));
    }

    test('「人」「people」でも読む。人数の前の文字は気にしない', () {
      expect(_p('a', scale: 'チーム 8人').scalePeople, 8);
      expect(_p('a', scale: '12 people').scalePeople, 12);
      expect(_p('a', scale: '約２０名').scalePeople, 20);
    });

    test('Project の役割・規模は、YAML になければ空', () {
      final p = Project.fromMap({'title': 'x'});
      expect(p.role, '');
      expect(p.scale, '');
      expect(p.roleList, isEmpty);
    });
  });

  group('Markdown・テンプレート・候補', () {
    test('Markdown：「- role: A, B」は並び、「- scale: 文」は文章', () {
      final n = normalizeInput('# 案件\n- role: PL, SE\n- scale: 全体 20名（チーム 5名）\n- workflow: 要件定義\n',
          kind: DataKind.work, fileName: 'x.md');
      expect(n.errors, isEmpty);
      final p = (loadYaml(n.text!)['projects'] as YamlList).single as YamlMap;
      expect(p['role'], ['PL', 'SE']);
      expect(p['scale'], '全体 20名（チーム 5名）');
    });

    test('テンプレート（Work / Private の YAML・Markdown）に role と scale がある', () {
      for (final file in ['format_work', 'format_private']) {
        for (final ext in ['yaml', 'md']) {
          final raw = File('assets/data/$file.$ext').readAsStringSync();
          final text = normalizeInput(raw, kind: file == 'format_work' ? DataKind.work : DataKind.private,
                  fileName: '$file.$ext')
              .text!;
          final p = (loadYaml(text)['projects'] as YamlList).first as YamlMap;
          expect(p['role'], ['PG'], reason: '$file.$ext');
          expect(p['scale'], '', reason: '$file.$ext');
        }
      }
    });

    test('複数件のサンプルには、役割・規模の入った案件がある（人数で区分できる）', () {
      final text = File('assets/data/sample_work_multi.yaml').readAsStringSync();
      final projects = [
        for (final p in (jsonDecode(jsonEncode(loadYaml(text)))['projects'] as List))
          Project.fromMap(p as Map<String, dynamic>),
      ];
      expect(projects.any((p) => p.roleList.length > 1), isTrue);
      expect(projects.where((p) => p.scaleBucket != null), isNotEmpty);
    });

    test('入力フォームの候補：今の Work / Private の役割', () {
      const yaml = 'projects:\n  - title: a\n    role: [PL, SE]\n  - title: b\n    role: [SE, PG]\n';
      expect(tagSuggestions([yaml])['role'], unorderedEquals(['PL', 'SE', 'PG']));
    });
  });

  group('画面', () {
    final projects = [
      _p('A', role: ['PL', 'SE'], scale: '20名'),
      _p('B', role: ['SE'], scale: '4名'),
    ];

    testWidgets('フィルター：「役割」「規模（人数）」があり、規模は区分の順。選んで反映', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      ProjectFilterState? applied;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 1500,
            child: ProjectsFilter(
              projects: projects,
              isWork: true,
              initialState: ProjectFilterState.initial(),
              onApply: (s) => applied = s,
              onClose: () {},
            ),
          ),
        ),
      ));
      expect(find.text(AppTexts.filterRole), findsOneWidget);
      expect(find.text(AppTexts.filterScale), findsOneWidget);
      expect(find.text('PL'), findsOneWidget);
      expect(find.text('SE'), findsOneWidget);
      // 人数のある区分だけ、区分の順に
      final small = tester.getTopLeft(find.text('〜5名'));
      final mid = tester.getTopLeft(find.text('11〜30名'));
      expect(small.dx < mid.dx || small.dy < mid.dy, isTrue);
      expect(find.text('6〜10名'), findsNothing);

      await tester.tap(find.text('PL'));
      await tester.tap(find.text('〜5名'));
      await tester.pump();
      await tester.tap(find.text(AppTexts.filterApply));
      await tester.pump();
      expect(applied!.selectedFilters['role'], ['PL']);
      expect(applied!.selectedFilters['scale'], ['〜5名']);
    });

    testWidgets('適用中の条件に役割・規模のチップが出て、× で外せる', (tester) async {
      ProjectFilterState? changed;
      final state = _filter({'role': ['PL'], 'scale': ['〜5名']});
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProjectActiveFilters(
            filterState: state,
            onChanged: (s) => changed = s,
            onClearAll: () {},
          ),
        ),
      ));
      expect(find.widgetWithText(InputChip, 'PL'), findsOneWidget);
      expect(find.widgetWithText(InputChip, '〜5名'), findsOneWidget);
      await tester.tap(find.byTooltip(AppTexts.filterRemoveTooltip('〜5名')));
      await tester.pump();
      expect(changed!.selectedFilters['scale'], isEmpty);
      expect(changed!.selectedFilters['role'], ['PL']);
    });

    Future<void> openDetail(WidgetTester tester, Project p) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showProjectDetailModal(context, p),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    testWidgets('セルをクリックした詳細：役割は枠に入れて並べ、規模は文章', (tester) async {
      await openDetail(tester, _p('詳細の案件', role: ['PL', 'SE'], scale: '全体 20名（チーム 5名）'));
      expect(find.text(AppTexts.fieldRole), findsOneWidget);
      expect(find.text('PL'), findsOneWidget);
      expect(find.text('SE'), findsOneWidget);
      expect(find.text(AppTexts.fieldScale), findsOneWidget);
      expect(find.text('全体 20名（チーム 5名）'), findsOneWidget);
    });

    testWidgets('詳細：役割・規模がなければ、その項目は出さない', (tester) async {
      await openDetail(tester, _p('役割なし'));
      expect(find.text(AppTexts.fieldRole), findsNothing);
      expect(find.text(AppTexts.fieldScale), findsNothing);
    });

    Future<GlobalKey<ProjectFormState>> pumpForm(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey<ProjectFormState>();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProjectForm(
              key: key,
              isWork: false,
              suggestions: const {'role': ['テックリード']},
            ),
          ),
        ),
      ));
      await tester.enterText(find.widgetWithText(TextFormField, DataTexts.formTitle), '入力の案件');
      return key;
    }

    testWidgets('入力フォーム（新規追加）：役割は候補から選べ、規模は文章で入れる', (tester) async {
      final key = await pumpForm(tester);
      expect(find.text(DataTexts.formRoleNote), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, DataTexts.formRole));
      await tester.pumpAndSettle();
      // 候補：今の Work / Private にあるもの＋よく使う役割
      expect(find.widgetWithText(FilterChip, 'テックリード'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'PM'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'PM'));
      await tester.pump();
      await tester.enterText(
          find.descendant(of: find.byType(TagInputField), matching: find.byType(TextField)), 'SE');
      await tester.pump();
      await tester.tap(find.text(DataTexts.tagPickerDone));
      await tester.pumpAndSettle();
      expect(find.text('PM, SE'), findsOneWidget); // ボタンの横に入れたもの

      await tester.enterText(
          find.widgetWithText(TextFormField, DataTexts.formScale), ' 全体 10名（チーム 3名） ');
      final p = key.currentState!.collect()!;
      expect(p['role'], ['PM', 'SE']);
      expect(p['scale'], '全体 10名（チーム 3名）');
      // 読み直すと、フィルターの区分にも入る
      expect(Project.fromMap(p).scaleBucket, '6〜10名');
    });

    testWidgets('入力フォーム：役割・規模を入れなければ [] と ""', (tester) async {
      final key = await pumpForm(tester);
      final p = key.currentState!.collect()!;
      expect(p['role'], isEmpty);
      expect(p['scale'], '');
    });
  });

  group('プロフィールの sheet：そのほか', () {
    String profile(String sheet) => 'home:\n  name: a\n  role: b\n  tagline: c\nabout:\n  intro: d\n$sheet';

    test('「キー: 値」の形でなければエラー', () {
      expect(Profile.parse(profile('sheet: abc\n')).errors.single, contains('sheet'));
    });

    test('値が並びや入れ子ならエラー', () {
      expect(Profile.parse(profile('sheet:\n  gender: [a, b]\n')).errors.single, contains('sheet.gender'));
    });

    test('書かなければ空', () {
      expect(Profile.parse(profile('')).profile!.sheet, isEmpty);
    });

    test('Markdown の「# sheet」も読める', () {
      const md = '# home\n- name: a\n- role: b\n- tagline: c\n\n# about\n- intro: d\n\n# sheet\n- gender: 男\n- station: ○○駅\n';
      final b = readProfileBundle(md, fileName: 'p.md');
      expect(b.errors, isEmpty);
      expect(b.profile!.sheet, {'gender': '男', 'station': '○○駅'});
    });
  });
}
