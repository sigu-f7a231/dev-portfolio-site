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
import 'app_styles.dart';

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

  /// Material 3 の ThemeData。色はすべて AppColors（＝ seed から作った ColorScheme）から取る。
  /// 文字は M3 のタイプスケール（Typography 2021）、角丸は M3 のシェイプスケールが既定で使われる。
  static ThemeData _build(AppColors c, Brightness brightness) {
    final s = c.scheme;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: s,
      scaffoldBackgroundColor: c.scaffoldBackground,
      // 角丸の大きいダイアログ（M3: extra large = 28）は既定値のまま
      dialogTheme: DialogThemeData(backgroundColor: c.dialogBackground),
      // 進捗インジケータは最新の M3 仕様（トラックとの隙間・丸い端）を使う
      progressIndicatorTheme: const ProgressIndicatorThemeData(year2023: false),
      sliderTheme: const SliderThemeData(year2023: false),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: s.inverseSurface,
          borderRadius: BorderRadius.circular(AppStyles.radiusSm), // M3: extra small
        ),
        textStyle: TextStyle(color: s.onInverseSurface),
      ),
    );
  }
}

/// どのウィジェットからでも色とモードを取れるようにする拡張
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  AppColors get colors => isDark ? AppColors.dark : AppColors.light;
}
