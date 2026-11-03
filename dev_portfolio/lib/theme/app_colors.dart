// lib/theme/app_colors.dart
//
// ============================================================
// 色の定義（アプリ内で色を指定してよいのはこのファイルだけ）
// ============================================================
// Material 3 に合わせ、1 つのブランド色（seed）から ColorScheme を作り、
// 各トークンは M3 のカラーロール（surface / primaryContainer / outlineVariant など）から割り当てる。
// - ブランド色を変えたいときは [seedColor] だけを変えればライト・ダーク両方が追従する。
// - 個別に調整したいときは、下の _fromScheme の割り当てを書き換える。
// - ウィジェットからは `context.colors.xxx`（app_theme.dart の拡張）で参照する。
import 'package:flutter/material.dart';

class AppColors {

  // ----------------------------------------------------------
  // ベース（ThemeData の元になる色）
  // ----------------------------------------------------------
  /// Material 3 のカラースキーム（ThemeData にそのまま渡す）
  final ColorScheme scheme;
  final Color scaffoldBackground;

  /// アクセント（Skills のハイライト、Bar/Pie 切替など）
  final Color accent;

  /// メイン（List/Collection 切替など）
  final Color primary;

  final Color success;
  final Color error;

  // ----------------------------------------------------------
  // テキスト
  // ----------------------------------------------------------
  /// 見出し・タイトル
  final Color textStrong;

  /// 本文
  final Color textPrimary;

  /// サブテキスト（説明・期間・％値）
  final Color textSecondary;

  /// さらに控えめなテキスト（補足）
  final Color textTertiary;

  /// ライトでは濃く、ダークでは控えめにしたいテキスト（ダイアログ本文、チップ）
  final Color textSoft;

  // ----------------------------------------------------------
  // ヘッダー / Drawer
  // ----------------------------------------------------------
  final Color headerBackground;
  final Color headerForeground;
  final Color headerForegroundMuted;
  final Color drawerHeaderBackground;
  final Color drawerHeaderForeground;

  /// ナビの「選択中」インジケーター（M3 の Navigation の active indicator）
  final Color navIndicator;
  final Color navSelectedForeground;

  /// ヘッダー下の区切り線
  final Color headerDivider;

  // ----------------------------------------------------------
  // ダイアログ（YAML アップロード）
  // ----------------------------------------------------------
  final Color dialogBackground;

  /// フォーマット説明内のコード（YAML サンプル）表示エリア
  final Color codeBackground;
  final Color codeBorder;

  // ----------------------------------------------------------
  // セクション背景
  // ----------------------------------------------------------
  final Color heroBackground;
  final Color heroForeground;
  final Color heroForegroundMuted;

  /// Home 右側の「プロフィール YAML」カード
  final Color heroCodeBackground;
  final Color heroCodeBorder;
  final Color heroCodeKey;
  final Color heroCodeValue;

  /// Home のボタン（スキルを見る / プロジェクトを見る）
  final Color heroPrimaryButtonBackground;
  final Color heroPrimaryButtonForeground;
  final Color heroSecondaryButtonBorder;

  /// About の区切り線・アクセント（締めの一文の縦線）
  final Color aboutDivider;
  final Color aboutAccent;
  final Color aboutBackground;
  final Color projectsBackground;

  // ----------------------------------------------------------
  // カード
  // ----------------------------------------------------------
  /// List 表示 / Skills のカード
  final Color cardBackground;

  /// Collection（グリッド）表示のカード
  final Color collectionCardBackground;

  /// カード・パネルの枠線
  final Color surfaceBorder;
  final Color cardShadow;

  // ----------------------------------------------------------
  // タグ
  // ----------------------------------------------------------
  final Color skillTagBackground;
  final Color skillTagForeground;
  final Color ongoingTagBackground;
  final Color ongoingTagForeground;

  // ----------------------------------------------------------
  // プロジェクト詳細モーダル
  // ----------------------------------------------------------
  final Color modalLabel;
  final Color modalValue;
  final Color modalClose;
  final Color linkButtonBackground;
  final Color linkButtonForeground;

  /// 詳細ダイアログの Workflow（担当した工程＝塗り／担当外＝枠線のみ）
  final Color workflowDoneBackground;
  final Color workflowDoneForeground;
  final Color workflowPendingBorder;
  final Color workflowPendingForeground;

  // ----------------------------------------------------------
  // 切替ボタン（List/Collection・Bar/Pie）
  // ----------------------------------------------------------
  final Color projectsToggleActive;
  final Color skillsToggleActive;
  final Color toggleInactiveBackground;
  final Color toggleActiveText;
  final Color toggleInactiveText;

  // ----------------------------------------------------------
  // フィルターチップ
  // ----------------------------------------------------------
  // ----------------------------------------------------------
  // Projects ツールバー（Work/Private・表示切替のセグメント）
  // ----------------------------------------------------------
  final Color segmentBackground;
  final Color segmentSelectedBackground;
  final Color segmentSelectedShadow;

  /// フィルターパネル・適用中フィルター・件数バッジ
  final Color filterPanelBackground;
  final Color activeFilterBackground;
  final Color activeFilterForeground;
  final Color countBadgeBackground;
  final Color countBadgeForeground;

  final Color chipSelected;
  final Color chipBackground;
  final Color chipSelectedText;
  final Color chipText;

  // ----------------------------------------------------------
  // ページネーション
  // ----------------------------------------------------------
  final Color paginationActive;
  final Color paginationInactive;
  final Color paginationActiveText;
  final Color paginationInactiveText;
  final Color paginationIcon;

  // ----------------------------------------------------------
  // グラフ（Skills）
  // ----------------------------------------------------------
  /// 系列ごとの色（Bar / Pie 共通。足りなければ先頭に戻って繰り返す）
  final List<Color> chartSeries;
  final Color chartHighlight;

  /// Bar グラフの背景バー
  final Color chartTrack;
  final Color chartLabel;
  final Color chartValue;

  AppColors._({
    required this.scheme,
    required this.scaffoldBackground,
    required this.accent,
    required this.primary,
    required this.success,
    required this.error,
    required this.textStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textSoft,
    required this.headerBackground,
    required this.headerForeground,
    required this.headerForegroundMuted,
    required this.drawerHeaderBackground,
    required this.drawerHeaderForeground,
    required this.navIndicator,
    required this.navSelectedForeground,
    required this.headerDivider,
    required this.dialogBackground,
    required this.codeBackground,
    required this.codeBorder,
    required this.heroBackground,
    required this.heroForeground,
    required this.heroForegroundMuted,
    required this.heroCodeBackground,
    required this.heroCodeBorder,
    required this.heroCodeKey,
    required this.heroCodeValue,
    required this.heroPrimaryButtonBackground,
    required this.heroPrimaryButtonForeground,
    required this.heroSecondaryButtonBorder,
    required this.aboutDivider,
    required this.aboutAccent,
    required this.aboutBackground,
    required this.projectsBackground,
    required this.cardBackground,
    required this.collectionCardBackground,
    required this.surfaceBorder,
    required this.cardShadow,
    required this.skillTagBackground,
    required this.skillTagForeground,
    required this.ongoingTagBackground,
    required this.ongoingTagForeground,
    required this.modalLabel,
    required this.modalValue,
    required this.modalClose,
    required this.linkButtonBackground,
    required this.linkButtonForeground,
    required this.workflowDoneBackground,
    required this.workflowDoneForeground,
    required this.workflowPendingBorder,
    required this.workflowPendingForeground,
    required this.projectsToggleActive,
    required this.skillsToggleActive,
    required this.toggleInactiveBackground,
    required this.toggleActiveText,
    required this.toggleInactiveText,
    required this.segmentBackground,
    required this.segmentSelectedBackground,
    required this.segmentSelectedShadow,
    required this.filterPanelBackground,
    required this.activeFilterBackground,
    required this.activeFilterForeground,
    required this.countBadgeBackground,
    required this.countBadgeForeground,
    required this.chipSelected,
    required this.chipBackground,
    required this.chipSelectedText,
    required this.chipText,
    required this.paginationActive,
    required this.paginationInactive,
    required this.paginationActiveText,
    required this.paginationInactiveText,
    required this.paginationIcon,
    required this.chartSeries,
    required this.chartHighlight,
    required this.chartTrack,
    required this.chartLabel,
    required this.chartValue,
  });

  // ==========================================================
  // ブランド色（Material 3 の seed color）
  // ==========================================================
  static const Color seedColor = Colors.blueAccent;

  // ==========================================================
  // M3 のカラーロールにない色（ライトとダークで共通）
  // ==========================================================
  /// グラフの系列色（M3 にグラフ用のロールはないため、見分けやすいアクセント色を固定で使う）
  static const List<Color> _chartSeries = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.yellowAccent,
    Colors.pinkAccent,
  ];

  // ==========================================================
  // ライト / ダーク
  // ==========================================================
  static final AppColors light = _fromScheme(
    ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
    isDark: false,
  );

  static final AppColors dark = _fromScheme(
    ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
    isDark: true,
  );

  /// M3 のカラーロール → アプリのトークン
  static AppColors _fromScheme(ColorScheme s, {required bool isDark}) {
    // Hero はライトでは primary、ダークでは primaryContainer の上に置く（M3 の推奨に合わせた濃さ）
    final heroBg = isDark ? s.primaryContainer : s.primary;
    final heroFg = isDark ? s.onPrimaryContainer : s.onPrimary;

    return AppColors._(
      scheme: s,
      scaffoldBackground: s.surface,
      accent: s.tertiary,
      primary: s.primary,
      success: isDark ? Colors.green[300]! : Colors.green[700]!, // M3 に success ロールはない
      error: s.error,
      // テキスト
      textStrong: s.onSurface,
      textPrimary: s.onSurface,
      textSecondary: s.onSurfaceVariant,
      textTertiary: s.outline,
      textSoft: s.onSurfaceVariant,
      // ヘッダー（M3 の Top app bar）
      headerBackground: s.surfaceContainer,
      headerForeground: s.onSurface,
      headerForegroundMuted: s.onSurfaceVariant,
      drawerHeaderBackground: s.primaryContainer,
      drawerHeaderForeground: s.onPrimaryContainer,
      navIndicator: s.secondaryContainer,
      navSelectedForeground: s.onSecondaryContainer,
      headerDivider: s.outlineVariant,
      // ダイアログ
      dialogBackground: s.surfaceContainerHigh,
      codeBackground: s.surfaceContainerHighest,
      codeBorder: s.outlineVariant,
      // Hero
      heroBackground: heroBg,
      heroForeground: heroFg,
      heroForegroundMuted: heroFg.withOpacity(0.8),
      heroCodeBackground: heroFg.withOpacity(0.08),
      heroCodeBorder: heroFg.withOpacity(0.24),
      heroCodeKey: isDark ? s.tertiary : s.tertiaryContainer,
      heroCodeValue: heroFg,
      heroPrimaryButtonBackground: isDark ? s.primary : s.onPrimary,
      heroPrimaryButtonForeground: isDark ? s.onPrimary : s.primary,
      heroSecondaryButtonBorder: heroFg.withOpacity(0.6),
      // About
      aboutDivider: s.outlineVariant,
      aboutAccent: s.primary,
      aboutBackground: s.surfaceContainerLow,
      // Projects
      projectsBackground: s.surface,
      // カード（M3 の Outlined card / Elevated card）
      cardBackground: s.surfaceContainerLow,
      collectionCardBackground: s.surfaceContainerLow,
      surfaceBorder: s.outlineVariant,
      cardShadow: isDark ? Colors.transparent : s.shadow.withOpacity(0.12),
      // タグ
      skillTagBackground: s.surfaceContainerHighest,
      skillTagForeground: s.onSurfaceVariant,
      ongoingTagBackground: s.tertiaryContainer,
      ongoingTagForeground: s.onTertiaryContainer,
      // モーダル
      modalLabel: s.primary,
      modalValue: s.onSurface,
      modalClose: s.onSurfaceVariant,
      linkButtonBackground: s.primary,
      linkButtonForeground: s.onPrimary,
      workflowDoneBackground: s.secondaryContainer,
      workflowDoneForeground: s.onSecondaryContainer,
      workflowPendingBorder: s.outlineVariant,
      workflowPendingForeground: s.outline,
      // 切替（旧スタイル用。現在は SegmentedButton がテーマから色を取る）
      projectsToggleActive: s.secondaryContainer,
      skillsToggleActive: s.secondaryContainer,
      toggleInactiveBackground: s.surfaceContainerHighest,
      toggleActiveText: s.onSecondaryContainer,
      toggleInactiveText: s.onSurfaceVariant,
      segmentBackground: s.surfaceContainerHighest,
      segmentSelectedBackground: s.secondaryContainer,
      segmentSelectedShadow: Colors.transparent,
      // フィルター
      filterPanelBackground: s.surfaceContainerLow,
      activeFilterBackground: s.secondaryContainer,
      activeFilterForeground: s.onSecondaryContainer,
      countBadgeBackground: s.primary,
      countBadgeForeground: s.onPrimary,
      // チップ（M3 の Filter chip）
      chipSelected: s.secondaryContainer,
      chipBackground: s.surface,
      chipSelectedText: s.onSecondaryContainer,
      chipText: s.onSurfaceVariant,
      // ページネーション
      paginationActive: s.primary,
      paginationInactive: Colors.transparent,
      paginationActiveText: s.onPrimary,
      paginationInactiveText: s.onSurfaceVariant,
      paginationIcon: s.onSurfaceVariant,
      // グラフ
      chartSeries: _chartSeries,
      chartHighlight: s.tertiary,
      chartTrack: s.surfaceContainerHighest,
      chartLabel: s.onSurface,
      chartValue: s.onSurfaceVariant,
    );
  }

  /// 系列 index に対応するグラフの色
  Color seriesColor(int index) => chartSeries[index % chartSeries.length];
}
