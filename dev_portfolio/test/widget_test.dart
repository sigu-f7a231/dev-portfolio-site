// テーマ（lib/theme/）の基本動作テスト
//
// ※ main.dart は Web 専用の機能（package:web / dart:js_interop）を間接的に読み込むため、
//   VM 上で動く flutter test からは import しない。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/theme/app_colors.dart';
import 'package:dev_portfolio/theme/app_theme.dart';

void main() {
  test('ThemeController でライト/ダークを切り替えられる', () {
    final controller = ThemeController.instance;
    controller.toggle(true);
    expect(controller.value, ThemeMode.dark);
    controller.toggle(false);
    expect(controller.value, ThemeMode.light);
  });

  testWidgets('context.colors がテーマに応じた色を返す', (tester) async {
    late AppColors lightColors;
    late AppColors darkColors;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(builder: (context) {
        lightColors = context.colors;
        return const SizedBox();
      }),
    ));

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Builder(builder: (context) {
        darkColors = context.colors;
        return const SizedBox();
      }),
    ));
    // MaterialApp はテーマを切り替えるときにアニメーションする（直後はまだライト）ので、終わるまで待つ
    await tester.pumpAndSettle();

    expect(lightColors, same(AppColors.light));
    expect(darkColors, same(AppColors.dark));
  });

  group('非推奨 API の置き換え', () {
    test('withOpacity → withValues(alpha:)：透明度が同じ値になっている', () {
      for (final c in [AppColors.light, AppColors.dark]) {
        expect(c.heroForegroundMuted.a, closeTo(0.8, 0.001));
        expect(c.heroCodeBackground.a, closeTo(0.08, 0.001));
        expect(c.heroCodeBorder.a, closeTo(0.24, 0.001));
        expect(c.heroSecondaryButtonBorder.a, closeTo(0.6, 0.001));
      }
      // ライトのカードの影は 12%、ダークは影なし（透明）
      expect(AppColors.light.cardShadow.a, closeTo(0.12, 0.001));
      expect(AppColors.dark.cardShadow.a, 0);
    });

    test('Progress indicator / Slider は M3 の 2024 年版（year2023: false）', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        // ignore: deprecated_member_use
        expect(theme.progressIndicatorTheme.year2023, isFalse);
        // ignore: deprecated_member_use
        expect(theme.sliderTheme.year2023, isFalse);
        expect(theme.useMaterial3, isTrue);
      }
    });
  });
}
