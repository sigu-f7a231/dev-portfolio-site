// lib/theme/app_theme.dart
//
// ============================================================
// ライト / ダークの切り替えと ThemeData
// ============================================================
// - 切り替え: `ThemeController.instance.toggle(isDark)` を呼ぶだけ。
//   MaterialApp が再構築され、配下のウィジェットはすべて自動で色が変わる。
// - 色の参照: `context.colors.xxx` / ダーク判定: `context.isDark`
//   → ウィジェットに isDark を引数で渡して回す必要はない。
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 現在のテーマモードを保持するコントローラ（アプリ全体で 1 つ）
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);

  static final ThemeController instance = ThemeController._();

  bool get isDark => value == ThemeMode.dark;

  void toggle(bool isDark) {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

/// MaterialApp に渡す ThemeData
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      primarySwatch: c.primarySwatch,
      scaffoldBackgroundColor: c.scaffoldBackground,
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: c.textStrong),
      ),
    );
  }
}

/// どのウィジェットからでも色とモードを取れるようにする拡張
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  AppColors get colors => isDark ? AppColors.dark : AppColors.light;
}
