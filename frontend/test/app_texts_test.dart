// 画面の文言を作る関数のテスト（値を差し込む・条件で変わるもの）
// 対象：lib/constants/app_texts.dart
//
// 実行：flutter test test/app_texts_test.dart（frontend/ で）
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_texts.dart';

void main() {
  group('durationLabel（期間の長さ）', () {
    // （月数, 表示）
    const cases = [
      (1, '1か月'),
      (11, '11か月'), // 1 年未満
      (12, '1年'), // ちょうど
      (13, '1年1か月'),
      (24, '2年'),
      (87, '7年3か月'),
      (0, '0か月'), // 0 でもエラーにしない
    ];
    for (final (months, label) in cases) {
      test('$months → $label', () => expect(AppTexts.durationLabel(months), label));
    }
  });

  group('periodRange / periodSingleYear（フィルターの期間）', () {
    test('同じ年なら 1 つ、違えば範囲', () {
      expect(AppTexts.periodRange(2024, 2024), '2024年');
      expect(AppTexts.periodRange(2020, 2024), '2020年〜2024年');
    });

    test('すべて同じ年のとき', () {
      expect(AppTexts.periodSingleYear(2024), contains('2024'));
    });
  });

  group('値を差し込む文言', () {
    test('Work / Private で見出しが変わる', () {
      expect(AppTexts.formatHelpTitle(true), startsWith(AppTexts.work));
      expect(AppTexts.formatHelpTitle(false), startsWith(AppTexts.private));
      expect(AppTexts.formatHelpTitle(true), isNot(AppTexts.formatHelpTitle(false)));
    });

    test('ファイル名・件数・エラーを差し込む', () {
      expect(AppTexts.formatSaved('format_work.yaml'), contains('format_work.yaml'));
      expect(AppTexts.helpSampleTitle('format_work.md'), contains('format_work.md'));
      expect(AppTexts.fileReadFailed(Exception('壊れています')), contains('壊れています'));
      expect(AppTexts.moreTags(3), '+3');
      expect(OverwriteTexts.more(5), contains('5'));
      expect(DataTexts.duplicates('A、B'), contains('A、B'));
    });

    test('件数が 0 でも文言を作れる', () {
      expect(AppTexts.moreTags(0), '+0');
      expect(OverwriteTexts.more(0), contains('0'));
    });
  });
}
