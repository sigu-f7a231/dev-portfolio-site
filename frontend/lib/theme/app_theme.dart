// lib/theme/app_theme.dart
//
// ============================================================
// ライト / ダークの切り替えと ThemeData
// ============================================================
// - 切り替え: `ref.read(themeModeProvider.notifier).toggle(isDark)`（Riverpod。lib/state/providers.dart）を呼ぶだけ。
//   MaterialApp が再構築され、配下のウィジェットはすべて自動で色が変わる。
// - 色の参照: `context.colors.xxx` / ダーク判定: `context.isDark`
//   → ウィジェットに isDark を引数で渡して回す必要はない。
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_styles.dart';

/// MaterialApp に渡す ThemeData
class AppTheme {
  AppTheme._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

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
      // M3 の 2024 年版の見た目（隙間のある Progress indicator・新しい Slider）を使う。
      // year2023 は「移行用」のフラグで非推奨扱いだが、既定値がまだ true（旧デザイン）のため、
      // 新しい見た目にする方法はこれしかない。既定値が false になったら、この 2 行を消す。
      // ignore: deprecated_member_use
      progressIndicatorTheme: const ProgressIndicatorThemeData(year2023: false),
      // ignore: deprecated_member_use
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
