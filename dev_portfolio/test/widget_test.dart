// テーマ（lib/theme/）の基本動作テスト
//
// ※ main.dart は dart:html（Web 専用）を間接的に読み込むため、
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

    expect(lightColors, same(AppColors.light));
    expect(darkColors, same(AppColors.dark));
  });
}
