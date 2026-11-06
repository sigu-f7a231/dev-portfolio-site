// プロジェクトのモデル（YAML の 1 件 → Project）のテスト
// 対象：lib/sections/projects/models/projects_model.dart
// 役割・規模は project_role_scale_test.dart、並び替えは project_sort_test.dart にある
//
// 実行：flutter test test/projects_model_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/sections/projects/models/projects_model.dart';

Project _p(Map<String, dynamic> fields) => Project.fromMap({'title': 'T', ...fields});

Project _period(Object? period) => _p({'period': period});

void main() {
  group('fromMap：値の形', () {
    test('項目がなければ空（エラーにしない）', () {
      final p = Project.fromMap({});
      expect(p.title, '');
      expect(p.description, '');
      expect(p.details, '');
      expect(p.period, '');
      expect(p.link, '');
      expect(p.skills, '');
      expect(p.workflow, isEmpty);
      expect(p.skillsList, isEmpty);
    });

    test('並びは「, 」でつなぐ。文字はそのまま。数はそのまま文字に', () {
      expect(_p({'db': ['MySQL', 'Redis']}).db, 'MySQL, Redis');
      expect(_p({'db': 'MySQL, Redis'}).db, 'MySQL, Redis');
      expect(_p({'db': 2019}).db, '2019');
      expect(_p({'db': null}).db, '');
    });

    test('tools がなければ tools_fw を使う（古い書き方）。両方あれば tools', () {
      expect(_p({'tools_fw': ['Git']}).tools, 'Git');
      expect(_p({'tools': ['GitHub'], 'tools_fw': ['Git']}).tools, 'GitHub');
    });

    test('YAML のキーと項目の対応', () {
      final p = _p({
        'server_os': ['Linux'],
        'backend_frameworks': ['Django'],
        'frontend_frameworks': ['React'],
        'ui_frameworks': ['Bootstrap'],
        'testing_frameworks': ['Jest'],
        'cloud_platforms': ['AWS'],
        'aws_services': ['Lambda'],
        'azure_services': ['Functions'],
        'gcp_services': ['BigQuery'],
        'container': ['Docker'],
        'container_orchestration': ['Kubernetes'],
        'ai_services': ['Claude'],
      });
      expect(p.serverOSList, ['Linux']);
      expect(p.backendList, ['Django']);
      expect(p.frontendList, ['React']);
      expect(p.uiList, ['Bootstrap']);
      expect(p.testingList, ['Jest']);
      expect(p.cloudList, ['AWS']);
      expect(p.awsList, ['Lambda']);
      expect(p.azureList, ['Functions']);
      expect(p.gcpList, ['BigQuery']);
      expect(p.containerList, ['Docker']);
      expect(p.orchestrationList, ['Kubernetes']);
      expect(p.aiList, ['Claude']);
    });

    test('Skills に書いたフロントエンドなどは本来の分類に移す（tech_catalog の振り分け）', () {
      final p = _p({'skills': ['Dart', 'React']});
      expect(p.skillsList, ['Dart']);
      expect(p.frontendList, contains('React'));
    });

    test('元の Map は変えない', () {
      final raw = <String, dynamic>{'title': 'T', 'skills': ['Dart', 'React']};
      Project.fromMap(raw);
      expect(raw['skills'], ['Dart', 'React']);
    });
  });

  group('一覧（〜List）：表記ゆれを 1 つにまとめる', () {
    test('大文字・小文字・全角の違いは 1 つ（よく知られた名前は正式な書き方）', () {
      expect(_p({'skills': ['python', 'PYTHON', 'Ｐｙｔｈｏｎ']}).skillsList, ['Python']);
    });

    test('数字は区別する（Python と Python3 は別）', () {
      expect(_p({'skills': ['Python', 'Python3']}).skillsList, ['Python', 'Python3']);
    });

    test('クラウドのサービスは先頭の AWS などを外してまとめる', () {
      expect(_p({'aws_services': ['AWS Lambda', 'Lambda', 'Amazon S3']}).awsList, ['Lambda', 'S3']);
    });

    test('前後の空白・空の項目は入れない', () {
      expect(_p({'db': ' MySQL ,  , Redis '}).dbList, ['MySQL', 'Redis']);
    });

    test('書かれた順を保つ', () {
      expect(_p({'db': ['Redis', 'MySQL', 'redis']}).dbList, ['Redis', 'MySQL']);
    });
  });

  group('工程（workflow）', () {
    test('true の工程だけを書かれた順に', () {
      final p = _p({
        'workflow': {'requirements': true, 'basic_design': false, 'detailed_design': true},
      });
      expect(p.workflowList, ['requirements', 'detailed_design']);
    });

    test('すべて false なら空', () {
      expect(_p({'workflow': {'requirements': false}}).workflowList, isEmpty);
    });
  });

  group('期間の書き方', () {
    test('並び（2 つ）は「開始 ~ 終了」の文字にする。2 つでなければ空', () {
      expect(_period(['2020-03', '2020-10']).period, '2020-03 ~ 2020-10');
      expect(_period(['2020-03']).period, '');
      expect(_period(['2020-03', '2020-10', '2021-01']).period, '');
      expect(_period('2020-03 ~ 2020-10').period, '2020-03 ~ 2020-10');
      expect(_period(null).period, '');
      expect(_period(2020).period, '');
    });

    // （書き方, 開始, 終了）
    final readable = [
      ('2020-03 ~ 2020-10', DateTime(2020, 3), DateTime(2020, 10)),
      ('2020/03 から 2020/10', DateTime(2020, 3), DateTime(2020, 10)),
      ('2020.3 - 2020.10', DateTime(2020, 3), DateTime(2020, 10)),
      ('2020年3月〜2020年10月', DateTime(2020, 3), DateTime(2020, 10)),
      ('２０２０／０３ ~ ２０２０／１０', DateTime(2020, 3), DateTime(2020, 10)), // 全角
      ('2020 - 3 ~ 2020 - 10', DateTime(2020, 3), DateTime(2020, 10)), // 空白入り
      ('2019-12 ~ 2020-01', DateTime(2019, 12), DateTime(2020, 1)), // 年をまたぐ
    ];
    for (final (text, start, end) in readable) {
      test('「$text」を読める', () {
        final p = _period(text);
        expect(p.periodStart, start);
        expect(p.periodEnd, end);
        expect(p.hasValidPeriod, isTrue);
        expect(p.isOngoing, isFalse);
      });
    }

    test('1〜12 以外の月は年月として読まない', () {
      expect(_period('2020-13 ~ 2021-01').hasValidPeriod, isFalse); // 読めるのは 2021-01 だけ
      expect(_period('2020-00 ~ 2020-05').hasValidPeriod, isFalse);
      expect(_period('2020-13 ~ 2021-01').periodStart, DateTime(2021, 1));
    });

    test('開始だけ（終わりがない）は期間として不完全。終わりは開始と同じ月', () {
      final p = _period('2023-04');
      expect(p.hasValidPeriod, isFalse);
      expect(p.periodStart, DateTime(2023, 4));
      expect(p.periodEnd, DateTime(2023, 4));
      expect(p.durationMonths, 1);
    });

    test('期間がない・読めない：開始は 1970 年 1 月とみなし、期間として扱わない', () {
      for (final text in ['', '未定', 'いつか']) {
        final p = _period(text);
        expect(p.hasValidPeriod, isFalse, reason: text);
        expect(p.periodStart, DateTime(1970, 1), reason: text);
      }
    });
  });

  group('進行中', () {
    // 「現在」「present」（大文字・小文字は問わない）
    for (final text in ['2023-04 ~ 現在', '2023-04 ~ present', '2023-04 ~ Present', '2023-04 ~ PRESENT']) {
      test('「$text」は進行中。終わりは今日', () {
        final p = _period(text);
        final now = DateTime.now();
        expect(p.isOngoing, isTrue);
        expect(p.hasValidPeriod, isTrue);
        expect(p.periodStart, DateTime(2023, 4));
        expect((p.periodEnd.year, p.periodEnd.month), (now.year, now.month));
      });
    }

    test('並びの書き方（[開始, 現在]）でも進行中', () {
      expect(_period(['2023-04', '現在']).isOngoing, isTrue);
    });

    test('「現在」がなければ進行中ではない', () {
      expect(_period('2023-04 ~ 2024-03').isOngoing, isFalse);
      expect(_period('').isOngoing, isFalse);
    });
  });

  group('期間の長さ（月数）：開始月と終了月を両方数える', () {
    // （期間, 月数）
    const cases = [
      ('2023-04 ~ 2023-04', 1), // 同じ月
      ('2023-04 ~ 2023-09', 6),
      ('2022-11 ~ 2023-02', 4), // 年をまたぐ
      ('2020-01 ~ 2021-12', 24),
      ('2023-09 ~ 2023-04', 1), // 終わりが開始より前でも 1 か月より短くしない
    ];
    for (final (period, months) in cases) {
      test('$period → $months か月', () => expect(_period(period).durationMonths, months));
    }

    test('進行中は今月までの長さ', () {
      final now = DateTime.now();
      final start = DateTime(now.year - 1, now.month); // ちょうど 1 年前の月から
      final text = '${start.year}-${start.month.toString().padLeft(2, '0')} ~ 現在';
      expect(_period(text).durationMonths, 13);
    });
  });
}
