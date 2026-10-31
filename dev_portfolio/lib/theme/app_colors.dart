// lib/theme/app_colors.dart
//
// ============================================================
// 色の定義（アプリ内で色を指定してよいのはこのファイルだけ）
// ============================================================
// - 色を変えたいときは、ここにある light / dark の値だけを書き換える。
// - ウィジェットからは `context.colors.xxx`（app_theme.dart の拡張）で参照する。
// - 新しい色が必要になったら、フィールドを追加して light / dark の両方に値を入れる。
import 'package:flutter/material.dart';

class AppColors {
  // ----------------------------------------------------------
  // ベース（ThemeData の元になる色）
  // ----------------------------------------------------------
  final MaterialColor primarySwatch;
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
    required this.primarySwatch,
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
  // ライトとダークで共通の色
  // ==========================================================
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
  // ライトモード
  // ==========================================================
  static final AppColors light = AppColors._(
    primarySwatch: Colors.blue,
    scaffoldBackground: Colors.white,
    accent: Colors.orangeAccent,
    primary: Colors.blueAccent,
    success: Colors.green[400]!,
    error: Colors.redAccent,
    // テキスト
    textStrong: Colors.black,
    textPrimary: Colors.black87,
    textSecondary: Colors.black54,
    textTertiary: Colors.black45,
    textSoft: Colors.black87,
    // ヘッダー
    headerBackground: Colors.blueAccent,
    headerForeground: Colors.white,
    headerForegroundMuted: Colors.white70,
    drawerHeaderBackground: Colors.black87,
    drawerHeaderForeground: Colors.white,
    // ダイアログ
    dialogBackground: Colors.white,
    codeBackground: Colors.grey[100]!,
    codeBorder: Colors.black12,
    // セクション
    heroBackground: Colors.blueAccent,
    heroForeground: Colors.white,
    heroForegroundMuted: Colors.white70,
    heroCodeBackground: const Color(0x2E000000), // 黒 18%
    heroCodeBorder: Colors.white24,
    heroCodeKey: const Color(0xFFFFE082), // amber 200
    heroCodeValue: Colors.white,
    heroPrimaryButtonBackground: Colors.white,
    heroPrimaryButtonForeground: const Color(0xFF1E4FD8),
    heroSecondaryButtonBorder: Colors.white70,
    aboutBackground: const Color(0xFFF3F6FB), // 青みのある淡いグレー
    aboutDivider: Colors.black12,
    aboutAccent: Colors.blueAccent,
    projectsBackground: Colors.white,
    // カード
    cardBackground: Colors.white,
    collectionCardBackground: Colors.white,
    surfaceBorder: Colors.black12,
    cardShadow: Colors.black.withOpacity(0.1),
    // タグ
    skillTagBackground: Colors.blue[100]!,
    skillTagForeground: Colors.black87,
    ongoingTagBackground: Colors.green,
    ongoingTagForeground: Colors.white,
    // モーダル
    modalLabel: Colors.blueGrey,
    modalValue: Colors.black87,
    modalClose: Colors.black54,
    linkButtonBackground: Colors.blue,
    linkButtonForeground: Colors.white,
    // 切替ボタン
    projectsToggleActive: Colors.blueAccent,
    skillsToggleActive: Colors.orangeAccent,
    toggleInactiveBackground: Colors.black12,
    toggleActiveText: Colors.black87,
    toggleInactiveText: Colors.black45,
    // Projects ツールバー
    segmentBackground: const Color(0x0F000000), // 黒 6%
    segmentSelectedBackground: Colors.white,
    segmentSelectedShadow: const Color(0x24000000), // 黒 14%
    filterPanelBackground: const Color(0xFFF7F9FC),
    activeFilterBackground: Colors.blue[50]!,
    activeFilterForeground: Colors.blue[800]!,
    countBadgeBackground: Colors.blueAccent,
    countBadgeForeground: Colors.white,
    // フィルターチップ
    chipSelected: Colors.blueAccent,
    chipBackground: Colors.grey[300]!,
    chipSelectedText: Colors.white,
    chipText: Colors.black87,
    // ページネーション
    paginationActive: Colors.blue,
    paginationInactive: Colors.transparent,
    paginationActiveText: Colors.white,
    paginationInactiveText: Colors.black87,
    paginationIcon: Colors.grey,
    // グラフ
    chartSeries: _chartSeries,
    chartHighlight: Colors.orangeAccent,
    chartTrack: Colors.black12,
    chartLabel: Colors.black87,
    chartValue: Colors.black54,
  );

  // ==========================================================
  // ダークモード
  // ==========================================================
  static final AppColors dark = AppColors._(
    primarySwatch: Colors.blue,
    scaffoldBackground: Colors.black,
    accent: Colors.orangeAccent,
    primary: Colors.blueAccent,
    success: Colors.green[400]!,
    error: Colors.redAccent,
    // テキスト
    textStrong: Colors.white,
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    textTertiary: Colors.white54,
    textSoft: Colors.white70,
    // ヘッダー
    headerBackground: Colors.black87,
    headerForeground: Colors.white,
    headerForegroundMuted: Colors.white70,
    drawerHeaderBackground: Colors.black87,
    drawerHeaderForeground: Colors.white,
    // ダイアログ
    dialogBackground: const Color(0xFF1E1E1E),
    codeBackground: Colors.black38,
    codeBorder: Colors.white12,
    // セクション
    heroBackground: Colors.grey[900]!,
    heroForeground: Colors.white,
    heroForegroundMuted: Colors.white70,
    heroCodeBackground: const Color(0x0FFFFFFF), // 白 6%
    heroCodeBorder: Colors.white12,
    heroCodeKey: const Color(0xFFFFD180), // orange 100
    heroCodeValue: Colors.white70,
    heroPrimaryButtonBackground: Colors.blueAccent,
    heroPrimaryButtonForeground: Colors.white,
    heroSecondaryButtonBorder: Colors.white38,
    aboutBackground: Colors.grey[900]!,
    aboutDivider: Colors.white12,
    aboutAccent: Colors.lightBlueAccent,
    projectsBackground: Colors.black87,
    // カード
    cardBackground: Colors.grey[850]!,
    collectionCardBackground: Colors.grey[900]!,
    surfaceBorder: Colors.white12,
    cardShadow: Colors.transparent, // ダークでは影なし
    // タグ
    skillTagBackground: Colors.blueGrey[700]!,
    skillTagForeground: Colors.white,
    ongoingTagBackground: Colors.green,
    ongoingTagForeground: Colors.white,
    // モーダル
    modalLabel: Colors.white70,
    modalValue: Colors.white,
    modalClose: Colors.white70,
    linkButtonBackground: Colors.blue,
    linkButtonForeground: Colors.white,
    // 切替ボタン
    projectsToggleActive: Colors.blueAccent,
    skillsToggleActive: Colors.orangeAccent,
    toggleInactiveBackground: Colors.white10,
    toggleActiveText: Colors.black,
    toggleInactiveText: Colors.white60,
    // Projects ツールバー
    segmentBackground: const Color(0x14FFFFFF), // 白 8%
    segmentSelectedBackground: Colors.grey[800]!,
    segmentSelectedShadow: Colors.transparent,
    filterPanelBackground: const Color(0xFF1C1C1C),
    activeFilterBackground: Colors.blueGrey[800]!,
    activeFilterForeground: Colors.lightBlue[100]!,
    countBadgeBackground: Colors.lightBlueAccent,
    countBadgeForeground: Colors.black,
    // フィルターチップ
    chipSelected: Colors.tealAccent,
    chipBackground: Colors.grey[800]!,
    chipSelectedText: Colors.black,
    chipText: Colors.white70,
    // ページネーション
    paginationActive: Colors.lightBlueAccent,
    paginationInactive: Colors.black26,
    paginationActiveText: Colors.black,
    paginationInactiveText: Colors.white70,
    paginationIcon: Colors.grey,
    // グラフ
    chartSeries: _chartSeries,
    chartHighlight: Colors.orangeAccent,
    chartTrack: Colors.white10,
    chartLabel: Colors.white,
    chartValue: Colors.white70,
  );

  /// 系列 index に対応するグラフの色
  Color seriesColor(int index) => chartSeries[index % chartSeries.length];
}
