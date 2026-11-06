// スキルシートの書き出し（ダウンロード）のテスト
// 対象：lib/utils/skill_sheet_writer.dart（fillSkillSheet）・lib/utils/skill_sheet_pdf.dart・lib/utils/xlsx_layout.dart
//
// 書き出した Excel を、読み込み（convertSkillSheet）で読み直して同じ中身に戻ることを確かめる
// 実行：flutter test test/skill_sheet_writer_test.dart（frontend/ で）
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/models/profile.dart';
import 'package:dev_portfolio/utils/profile_bundle.dart';
import 'package:dev_portfolio/utils/skill_sheet.dart';
import 'package:dev_portfolio/utils/skill_sheet_pdf.dart';
import 'package:dev_portfolio/utils/skill_sheet_writer.dart';
import 'package:dev_portfolio/utils/xlsx_layout.dart';

Uint8List _template() => File(skillSheetTemplateAsset).readAsBytesSync();

dynamic _plain(String yaml) => jsonDecode(jsonEncode(loadYaml(yaml)));

List<Map<String, dynamic>> _projects(String? text) =>
    text == null ? [] : (_plain(text)['projects'] as List).cast<Map<String, dynamic>>();

/// 比べる項目（details は「概要：」などの見出しを含むので比べない）
Map<String, dynamic> _comparable(Map<String, dynamic> p) => {
      for (final e in p.entries)
        if (e.key != 'details') e.key: e.value is List ? [for (final v in e.value) '$v'] : e.value,
      'link': p['link'] ?? '',
    };

String _sheetXml(Uint8List xlsx) {
  final archive = ZipDecoder().decodeBytes(xlsx);
  final path = firstSheetPath(archive);
  return utf8.decode(archive.findFile(path)!.content);
}

void main() {
  // テンプレートのサンプルを読み込んだ中身（これを書き出して、読み直す）
  late ProfileBundle original;
  late SkillSheetData data;

  setUpAll(() {
    final result = convertSkillSheet(_template(), fileName: skillSheetTemplateFileName);
    expect(result.errors, isEmpty);
    original = readProfileBundle(result.yamlText!, fileName: 'skill_sheet.yaml');
    data = SkillSheetData(
      name: original.profile!.name,
      experience: experienceTextOf(original.profile!),
      work: _projects(original.workText),
      private: _projects(original.privateText),
    );
  });

  ProfileBundle readBack(Uint8List xlsx) {
    final result = convertSkillSheet(xlsx, fileName: 'out.xlsx');
    expect(result.errors, isEmpty);
    return readProfileBundle(result.yamlText!, fileName: 'out.yaml');
  }

  group('Excel', () {
    test('書き出して読み直すと、氏名・経験・Work / Private が同じ', () {
      final back = readBack(fillSkillSheet(_template(), data, today: DateTime(2026, 11, 5)));
      expect(back.errors, isEmpty);
      expect(back.profile!.name, original.profile!.name);
      expect(back.profile!.recent, original.profile!.recent);
      expect(back.profile!.past, original.profile!.past);
      expect([for (final p in _projects(back.workText)) _comparable(p)],
          [for (final p in _projects(original.workText)) _comparable(p)]);
      expect([for (final p in _projects(back.privateText)) _comparable(p)],
          [for (final p in _projects(original.privateText)) _comparable(p)]);
    });

    test('件数が多くても、すべての案件を書き、結合・入力規則・後ろの行がずれない', () {
      final many = SkillSheetData(
        name: data.name,
        experience: data.experience,
        work: [for (var i = 0; i < 4; i++) ...data.work],
        private: [for (var i = 0; i < 3; i++) ...data.private],
      );
      final xlsx = fillSkillSheet(_template(), many);
      final back = readBack(xlsx);
      expect(_projects(back.workText).length, many.work.length);
      expect(_projects(back.privateText).length, many.private.length);

      final xml = _sheetXml(xlsx);
      final blocks = many.work.length + many.private.length;
      // 入力規則（業務の種類）は 1 案件に 1 つ
      final sqref = RegExp(r'<dataValidation [^>]*sqref="([^"]+)"').firstMatch(xml)!.group(1)!;
      expect(sqref.split(' ').length, blocks);
      // mergeCells の count と中身の数が合っている（Excel が「修復」を出さない）
      final count = int.parse(RegExp(r'<mergeCells count="(\d+)"').firstMatch(xml)!.group(1)!);
      expect(RegExp(r'<mergeCell ref=').allMatches(xml).length, count);
      // 行番号が昇順で重複しない
      final rows = [for (final m in RegExp(r'<row r="(\d+)"').allMatches(xml)) int.parse(m.group(1)!)];
      for (var i = 1; i < rows.length; i++) {
        expect(rows[i], greaterThan(rows[i - 1]));
      }
    });

    test('Private の案件名には【個人開発】を付ける（読み込みで Private に戻る印）', () {
      // テンプレートのサンプル「サンプル・プライベートプロジェクト」は、もう「プライベート」で Private とわかるので付けない
      final xlsx = fillSkillSheet(
        _template(),
        SkillSheetData(name: 'a', experience: '', work: const [], private: const [
          {'title': '家計簿アプリ'},
        ]),
      );
      expect(_sheetXml(xlsx), contains('家計簿アプリ${SkillSheetTexts.privateMark}'));
      expect(_sheetXml(fillSkillSheet(_template(), data)), isNot(contains(SkillSheetTexts.privateMark)));
    });

    test('テンプレートの書式（列幅・余白・用紙）はそのまま', () {
      final before = readXlsxLayout(_template());
      final after = readXlsxLayout(fillSkillSheet(_template(), data));
      expect(after.colWidths, before.colWidths);
      expect(after.hiddenCols, before.hiddenCols);
      expect(after.styles.length, before.styles.length);
      expect(after.horizontalCentered, before.horizontalCentered);
      expect(after.footerRight, before.footerRight);
    });

    test('役割・規模と、ふりがな・生年月日などを書き、読み直すと同じ（年齢は出力した日の年齢）', () {
      final custom = SkillSheetData(
        name: data.name,
        experience: data.experience,
        work: [
          {...data.work.first, 'role': ['PL', 'SE'], 'scale': '全体 20名（チーム 5名）'},
        ],
        private: data.private,
        sheet: const {
          'furigana': 'すずき はなこ',
          'gender': '女',
          'birthday': '1995/7/20',
          'nationality': '日本',
          'station': '渋谷駅',
          'education': '○○大学　情報学部',
        },
      );
      final xlsx = fillSkillSheet(_template(), custom, today: DateTime(2026, 11, 5));
      final back = readBack(xlsx);
      final w = _projects(back.workText).first;
      expect(w['role'], ['PL', 'SE']);
      expect(w['scale'], '全体 20名（チーム 5名）');
      expect(back.profile!.sheet, {
        'furigana': 'すずき はなこ',
        'gender': '女',
        'birthday': '1995年07月20日',
        'nationality': '日本',
        'station': '渋谷駅',
        'education': '○○大学　情報学部',
      });

      final xml = _sheetXml(xlsx);
      // 年齢・生年月日はテンプレートと同じ数式（表示は出力した日の値）
      expect(xml, contains('DATEDIF(DATE(1995,7,20),TODAY(),'));
      expect(xml, contains('<v>31</v>'));
      expect(xml, contains('<v>1995年07月20日</v>'));
      // 書かれていない項目（配偶者）は空にする（テンプレートのサンプル「無」は残さない）
      expect(back.profile!.sheet.containsKey('spouse'), isFalse);
    });

    test('日付の数式（YEAR(TODAY()) など）の表示を、出力した日にする', () {
      final xml = _sheetXml(fillSkillSheet(_template(), data, today: DateTime(2026, 11, 5)));
      expect(xml, contains('<v>2026</v>'));
    });
  });

  group('PDF', () {
    test('PDF として出力できる（フォントを埋め込む）', () async {
      final xlsx = fillSkillSheet(_template(), data);
      final font = File(skillSheetPdfFontAsset).readAsBytesSync();
      final pdf = await skillSheetPdf(xlsx, ByteData.sublistView(font));
      expect(ascii.decode(pdf.sublist(0, 5)), '%PDF-');
      expect(pdf.length, greaterThan(10000));
    });

    test('ファイル名：skill_sheet_YYYYMMDD', () {
      expect(SkillSheetTexts.fileName(DateTime(2026, 1, 2), 'pdf'), 'skill_sheet_20260102.pdf');
    });
  });

  // ------------------------------------------------------------
  // 書き込む中身（セルごと）
  // ------------------------------------------------------------
  group('書き込む中身', () {
    // テンプレートの列：A=No.（1）、B=期間（2）、E=プロジェクト名・業務概要（5）、V=役割・規模（22）、
    // Y=サーバ OS（25）、AC=DB（29）、AF=FW・MW ツール等（32）、AJ=使用言語（36）、AN〜AT=作業工程（40〜46）
    // 1 件目は 11〜15 行、2 件目は 16〜20 行（1 件目の枠 5 行を複製）
    final work = <String, dynamic>{
      'title': '案件A',
      'description': '説明A',
      'details': '詳細A',
      'link': 'https://a.example',
      'role': ['PL'],
      'scale': '5名',
      'period': ['2024-04', '2024-09'],
      'server_os': ['Linux', 'Windows'],
      'db': [ExcelTexts.notUsed],
      'tools': ['Git'],
      'cloud_platforms': ['AWS'],
      'aws_services': ['Lambda'],
      'azure_services': [ExcelTexts.notUsed],
      'container': ['Docker'],
      'container_orchestration': ['Kubernetes'],
      'ai_services': ['GitHub Copilot'],
      'skills': ['Python'],
      'backend_frameworks': ['Django'],
      'frontend_frameworks': ['React'],
      'workflow': {'requirements': true, 'basic_design': false, 'maintenance_operation': true},
    };
    final private = <String, dynamic>{
      'title': '個人B',
      'description': '説明B',
      'period': ['2025-01', '現在'],
      'db': ['SQLite'],
      'skills': ['Dart'],
    };
    late XlsxLayout layout;
    late String xml;

    setUpAll(() {
      final xlsx = fillSkillSheet(
        _template(),
        SkillSheetData(name: '鈴木 一郎', experience: '直近の開発経験\n\nWeb開発：テスト', work: [work], private: [private]),
        today: DateTime(2026, 11, 5),
      );
      layout = readXlsxLayout(xlsx);
      xml = _sheetXml(xlsx);
    });

    String v(int r, int c) => layout.cells[(r, c)]?.value ?? '';

    test('氏名・開発経験', () {
      expect(v(5, 5), '鈴木 一郎');
      expect(v(7, 1), '直近の開発経験\n\nWeb開発：テスト');
    });

    test('作成日（数式の表示）を出力した日にする', () {
      expect(v(3, 40), '2026');
      expect(v(3, 43), '11');
      expect(v(3, 45), '5');
    });

    test('No. は Work → Private の通し番号', () {
      expect(v(11, 1), '1');
      expect(v(16, 1), '2');
    });

    test('期間：開始 ／ ↓ ／ 終了 ／（N ヶ月）。進行中は「現在」', () {
      expect([for (var r = 11; r <= 14; r++) v(r, 2)], ['2024/4', '↓', '2024/9', '（6ヶ月）']);
      expect([for (var r = 16; r <= 18; r++) v(r, 2)], ['2025/1', '↓', AppTexts.periodNow]);
      expect(v(19, 2), startsWith('（'));
    });

    test('プロジェクト名と業務概要（概要・内容・URL）。Private は【個人開発】', () {
      expect(v(11, 5), '案件A');
      expect(v(12, 5), '概要：\n説明A\n\n内容：\n詳細A\n\nURL：\nhttps://a.example');
      expect(v(16, 5), '個人B${SkillSheetTexts.privateMark}');
      expect(v(17, 5), '概要：\n説明B');
    });

    test('役割・規模：2 行目のセルに「役割」と「規模：」。1 行目は空', () {
      expect(v(11, 22), '');
      expect(v(12, 22), 'PL\n規模：5名');
      expect(v(17, 22), '', reason: '役割も規模もない');
    });

    test('サーバ OS・DB（「利用なし」は「なし」）', () {
      expect(v(11, 25), 'サーバOS：\nLinux / Windows');
      expect(v(11, 29), 'DB：\nなし');
      expect(v(16, 25), 'サーバOS：\nなし');
      expect(v(16, 29), 'DB：\n- SQLite');
    });

    test('FW・MW ツール等：ツール・クラウド・各サービス・コンテナ・AI の見出しごと（利用なしの見出しは出さない）', () {
      final tools = v(11, 32);
      for (final part in [
        'その他ツール・技術：\n- Git',
        'クラウド：\n- AWS',
        'AWS Service：\n- Lambda',
        'コンテナ：\n- Docker',
        'コンテナオーケストレーション：\n- Kubernetes',
        'AI：\n- GitHub Copilot',
      ]) {
        expect(tools, contains(part));
      }
      expect(tools, isNot(contains('Azure')));
    });

    test('使用言語：言語と、FW・MW・ツール等（バックエンド・フロントエンドなど）', () {
      expect(v(11, 36), '使用言語/ライブラリー：\n- Python\n\nFW・MW・ツール等：\n- Django\n- React');
      expect(v(16, 36), '使用言語/ライブラリー：\n- Dart');
    });

    test('作業工程：Work は担当した工程だけ ●、Private は書かない', () {
      expect(v(11, 40), '●'); // 要件定義
      expect(v(11, 41), ''); // 基本設計
      expect(v(11, 46), '●'); // 保守・運用
      for (var c = 40; c <= 46; c++) {
        expect(v(16, c), '', reason: 'Private の $c 列');
      }
    });

    test('1 件目の枠の結合を、件数分複製する（テンプレートの 2 件目の結合 E17:U23 は残さない）', () {
      bool has(int r1, int c1, int r2, int c2) =>
          layout.merges.any((m) => m.r1 == r1 && m.c1 == c1 && m.r2 == r2 && m.c2 == c2);
      expect(has(12, 5, 15, 21), isTrue);
      expect(has(17, 5, 20, 21), isTrue);
      expect(has(16, 1, 20, 1), isTrue);
      expect(has(17, 5, 23, 21), isFalse);
    });

    test('作業工程の選択肢（入力規則）を各枠の 1 行目に', () {
      final sqref = RegExp(r'<dataValidation [^>]*sqref="([^"]+)"').firstMatch(xml)!.group(1)!;
      expect(sqref, 'AN11:AT11 AN16:AT16');
    });

    test('テンプレートのサンプルのリンク（E17）は外す', () {
      expect(xml, isNot(contains('<hyperlink ')));
    });

    test('行の高さは 1 件目の枠と同じ（入りきるとき）', () {
      for (final base in [11, 16]) {
        expect([for (var k = 0; k < 5; k++) layout.rowHeightPt(base + k)], [16.5, 16.5, 16.5, 16.5, 384]);
      }
    });
  });

  group('書き込み：そのほか', () {
    test('名前にもともと「個人開発」が入っていれば、【個人開発】を重ねない', () {
      final layout = readXlsxLayout(fillSkillSheet(
        _template(),
        SkillSheetData(name: 'a', experience: '', work: const [], private: const [
          {'title': '家計簿（個人開発）'},
        ]),
      ));
      expect(layout.cells[(11, 5)]!.value, '家計簿（個人開発）');
    });

    test('文章が枠に入りきらないときだけ、枠の最後の行を高くする', () {
      final long = List.filled(120, '長い詳細の行').join('\n');
      final layout = readXlsxLayout(fillSkillSheet(
        _template(),
        SkillSheetData(name: 'a', experience: '', work: [
          {'title': '長い', 'details': long, 'workflow': <String, bool>{}},
        ], private: const []),
      ));
      expect(layout.rowHeightPt(15), greaterThan(384));
      expect(layout.rowHeightPt(11), 16.5);
    });

    test('案件が 0 件：枠と選択肢を外し、後ろの行を詰める（Excel が「修復」を出さない形）', () {
      final xlsx = fillSkillSheet(
          _template(), SkillSheetData(name: '鈴木', experience: '', work: const [], private: const []));
      final xml = _sheetXml(xlsx);
      expect(xml, isNot(contains('sqref=""')));
      expect(xml, isNot(contains('<dataValidation ')));
      final count = int.parse(RegExp(r'<mergeCells count="(\d+)"').firstMatch(xml)!.group(1)!);
      expect(RegExp(r'<mergeCell ref=').allMatches(xml).length, count);
      final result = convertSkillSheet(xlsx);
      expect(result.errors, isNot(contains(ExcelTexts.nameMissing)));
    });

    test('シート以外のファイル（書式・テーマ・図形など）はテンプレートのまま', () {
      final before = ZipDecoder().decodeBytes(_template());
      final after = ZipDecoder().decodeBytes(fillSkillSheet(_template(), data));
      final sheet = firstSheetPath(before);
      expect(after.files.map((f) => f.name).toSet(), before.files.map((f) => f.name).toSet());
      for (final f in before.files.where((f) => f.isFile && f.name != sheet)) {
        expect(after.findFile(f.name)!.content, f.content, reason: f.name);
      }
    });

    test('氏名が空なら、テンプレートの氏名は書き換えない', () {
      final layout = readXlsxLayout(fillSkillSheet(
          _template(), const SkillSheetData(name: '', experience: '', work: [], private: [])));
      expect(layout.cells[(5, 5)]!.value, '山田 太郎');
    });
  });

  group('ふりがな・生年月日などの個人の項目', () {
    String v(XlsxLayout l, int r, int c) => l.cells[(r, c)]?.value ?? '';
    XlsxLayout fill(Map<String, String> sheet) => readXlsxLayout(fillSkillSheet(
          _template(),
          SkillSheetData(name: 'a', experience: '', work: const [], private: const [], sheet: sheet),
          today: DateTime(2026, 4, 1),
        ));

    test('見出しの右（結合の右隣）に書く：ふりがな E4・性別 X4・国籍 X5・配偶者 AE5・最寄駅 AM5・学歴 E6', () {
      final l = fill(const {
        'furigana': 'すずき',
        'gender': '女',
        'nationality': '日本',
        'spouse': '有',
        'station': '渋谷駅',
        'education': '○○大学',
      });
      expect(v(l, 4, 5), 'すずき');
      expect(v(l, 4, 24), '女');
      expect(v(l, 5, 24), '日本');
      expect(v(l, 5, 31), '有');
      expect(v(l, 5, 39), '渋谷駅');
      expect(v(l, 6, 5), '○○大学');
    });

    test('生年月日が読めれば、年齢は出力した日の年齢（誕生日の前日・当日）', () {
      expect(v(fill(const {'birthday': '2000-04-02'}), 4, 31), '25');
      expect(v(fill(const {'birthday': '2000-04-01'}), 4, 31), '26');
      expect(v(fill(const {'birthday': '2000-04-01'}), 4, 39), '2000年04月01日');
    });

    test('生年月日が読めなければ、そのまま文字で書き、年齢は持っているものを書く', () {
      final l = fill(const {'birthday': '非公開', 'age': '30代'});
      expect(v(l, 4, 39), '非公開');
      expect(v(l, 4, 31), '30代');
    });

    test('書かれていない項目は空（テンプレートのサンプルは残さない）', () {
      final l = fill(const {});
      for (final (r, c) in [(4, 24), (4, 31), (4, 39), (5, 24), (5, 31), (5, 39), (6, 5)]) {
        expect(v(l, r, c), '', reason: '($r, $c)');
      }
    });
  });

  group('開発経験の文章（experienceTextOf）', () {
    test('過去 → 直近の順。主な技術は「分類：A、B」', () {
      const p = Profile(
        name: 'a',
        role: '',
        tagline: '',
        intro: '',
        past: 'Web開発：店舗検索',
        pastTech: {'言語': ['PHP']},
        recent: 'モバイル開発：アプリ',
        recentTech: {'言語': ['Dart', 'Kotlin']},
      );
      final text = experienceTextOf(p);
      expect(text.indexOf(SkillSheetTexts.pastHeading), lessThan(text.indexOf(SkillSheetTexts.recentHeading)));
      expect(text, contains('Web開発：店舗検索'));
      expect(text, contains('${SkillSheetTexts.techHeading}\n\n言語：Dart、Kotlin'));
    });

    test('直近だけなら直近だけ', () {
      const p = Profile(name: 'a', role: '', tagline: '', intro: '', recent: 'Web開発：テスト');
      expect(experienceTextOf(p), '${SkillSheetTexts.recentHeading}\n\nWeb開発：テスト');
    });

    test('開発経験がないプロフィールは、自己紹介と得意な領域を直近の経験として書く', () {
      const p = Profile(name: 'a', role: '', tagline: '', intro: '自己紹介です', domains: ['Web', 'モバイル']);
      final text = experienceTextOf(p);
      expect(text, startsWith(SkillSheetTexts.recentHeading));
      expect(text, contains('自己紹介です'));
      expect(text, contains('${AboutContent.domainsLabel}：Web、モバイル'));
    });

    test('書いた経験は、読み込み（convertSkillSheet）で同じ経験に戻る', () {
      const p = Profile(
        name: '鈴木',
        role: '',
        tagline: '',
        intro: '',
        past: 'Web開発：店舗検索',
        recent: 'モバイル開発：アプリ',
        recentTech: {'言語': ['Dart']},
      );
      final xlsx = fillSkillSheet(_template(),
          SkillSheetData(name: p.name, experience: experienceTextOf(p), work: const [], private: const []));
      final back = readProfileBundle(convertSkillSheet(xlsx).yamlText!, fileName: 'x.yaml').profile!;
      expect(back.past, p.past);
      expect(back.recent, p.recent);
      expect(back.recentTech, p.recentTech);
    });
  });

  group('業務概要のセル（skillSheetSummary）', () {
    test('ふつうは「概要：」「内容：」「URL：」を付ける', () {
      expect(skillSheetSummary('説明', '詳細', 'https://a.example'),
          '概要：\n説明\n\n内容：\n詳細\n\nURL：\nhttps://a.example');
      expect(skillSheetSummary('説明', '', ''), '概要：\n説明');
    });

    test('Excel から読み込んだ詳細（「概要：」入りのセル全体）は、見出しを重ねずにそのまま', () {
      const details = '概要：\n既存システムの改修\n\n担当業務：\n設計と実装';
      expect(skillSheetSummary('既存システムの改修', details, ''), details);
    });

    test('リンクがすでに詳細に書いてあれば、URL を重ねない', () {
      const details = '概要：\n個人開発\n\nURL：\nhttps://example.com/app';
      expect(skillSheetSummary('個人開発', details, 'https://example.com/app'), details);
      expect(skillSheetSummary('説明', '詳細 https://example.com/app', 'https://example.com/app'),
          '概要：\n説明\n\n内容：\n詳細 https://example.com/app');
    });

    test('詳細にないリンクだけ足す', () {
      expect(skillSheetSummary('a', '概要：\na', 'https://b.example'), '概要：\na\n\nURL：\nhttps://b.example');
    });

    test('Excel → 読み込み → 書き出し → 読み込み で、業務概要が増えない（URL が 1 つ）', () {
      final first = fillSkillSheet(_template(), data);
      final again = readBack(first);
      final second = fillSkillSheet(
        _template(),
        SkillSheetData(
          name: data.name,
          experience: data.experience,
          work: _projects(again.workText),
          private: _projects(again.privateText),
        ),
      );
      final back = readBack(second);
      for (final (a, b) in [
        (_projects(again.workText), _projects(back.workText)),
        (_projects(again.privateText), _projects(back.privateText)),
      ]) {
        for (var i = 0; i < a.length; i++) {
          expect(b[i]['details'], a[i]['details']);
          final details = '${b[i]['details']}';
          final link = '${b[i]['link'] ?? ''}';
          if (link.isNotEmpty) expect(link.allMatches(details).length, 1, reason: details);
          expect(RegExp(r'^概要[：:]', multiLine: true).allMatches(details).length, 1, reason: details);
        }
      }
    });
  });

  group('文章の高さの見積もり（estimateTextHeight）', () {
    test('幅がなければ 0。1 行＝文字の大きさ × 1.3 ＋ 4', () {
      expect(estimateTextHeight('abc', 0, 10), 0);
      expect(estimateTextHeight('abc', 100, 10), 17);
      expect(estimateTextHeight('a\nb', 100, 10), 30);
    });

    test('幅を超えると折り返す（全角は半角より幅をとる）', () {
      final half = estimateTextHeight('a' * 40, 100, 10);
      final full = estimateTextHeight('あ' * 40, 100, 10);
      expect(half, greaterThan(17));
      expect(full, greaterThan(half));
    });
  });
}
