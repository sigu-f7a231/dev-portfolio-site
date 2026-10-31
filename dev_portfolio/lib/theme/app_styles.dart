// lib/theme/app_styles.dart
//
// ============================================================
// UI 共通スタイル（CSS に相当する部分）
// ============================================================
// - 文字スタイル・角丸・影・タグ・ボタンなど、複数の画面で共有する「見た目のルール」をまとめる。
// - 色は app_colors.dart から取る（このファイルでは Colors.xxx を直接書かない）。
// - セクション固有のサイズ（カード幅、グラフ半径など）は従来どおり sections/config/ に置く。
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppStyles {
  AppStyles._();

  // ----------------------------------------------------------
  // 角丸
  // ----------------------------------------------------------
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;

  // ----------------------------------------------------------
  // テキスト
  // ----------------------------------------------------------
  /// 見出し（太字・textStrong）
  static TextStyle title(BuildContext context, {double? fontSize}) => TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: context.colors.textStrong,
      );

  /// 本文（textPrimary）
  static TextStyle body(
    BuildContext context, {
    double? fontSize,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontSize: fontSize,
        fontStyle: fontStyle,
        color: context.colors.textPrimary,
      );

  /// サブテキスト（textSecondary）
  static TextStyle secondary(BuildContext context, {double? fontSize}) =>
      TextStyle(fontSize: fontSize, color: context.colors.textSecondary);

  /// 補足テキスト（textTertiary）
  static TextStyle tertiary(BuildContext context, {double? fontSize}) =>
      TextStyle(fontSize: fontSize, color: context.colors.textTertiary);

  // ----------------------------------------------------------
  // カード
  // ----------------------------------------------------------
  /// 影付きカード（ダークでは影の色が透明になり、影なしになる）
  static BoxDecoration card(
    BuildContext context, {
    double radius = radiusLg,
    double shadowBlur = 8,
    Offset shadowOffset = const Offset(0, 4),
  }) =>
      BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: context.colors.cardShadow,
            blurRadius: shadowBlur,
            offset: shadowOffset,
          ),
        ],
      );

  // ----------------------------------------------------------
  // スキルタグ（プロジェクトカード内）
  // ----------------------------------------------------------
  static const EdgeInsets skillTagPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const double skillTagSpacing = 6;
  static const double skillTagRunSpacing = 4;

  static BoxDecoration skillTag(BuildContext context) => BoxDecoration(
        color: context.colors.skillTagBackground,
        borderRadius: BorderRadius.circular(radiusLg),
      );

  static TextStyle skillTagText(BuildContext context) => TextStyle(
        color: context.colors.skillTagForeground,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

  // ----------------------------------------------------------
  // 進行中タグ
  // ----------------------------------------------------------
  static const EdgeInsets ongoingTagPadding =
      EdgeInsets.symmetric(horizontal: 6, vertical: 2);

  static BoxDecoration ongoingTag(BuildContext context) => BoxDecoration(
        color: context.colors.ongoingTagBackground,
        borderRadius: BorderRadius.circular(radiusSm),
      );

  static TextStyle ongoingTagText(BuildContext context) => TextStyle(
        fontSize: 10,
        color: context.colors.ongoingTagForeground,
      );

  // ----------------------------------------------------------
  // 切替ボタン（List/Collection・Bar/Pie）
  // ----------------------------------------------------------
  static BoxDecoration toggle(
    BuildContext context, {
    required bool active,
    required Color activeColor,
  }) =>
      BoxDecoration(
        color: active ? activeColor : context.colors.toggleInactiveBackground,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  static TextStyle toggleText(BuildContext context, {required bool active}) =>
      TextStyle(
        color: active
            ? context.colors.toggleActiveText
            : context.colors.toggleInactiveText,
        fontWeight: FontWeight.bold,
      );

  // ----------------------------------------------------------
  // グラフ（凡例のラベル・％値）
  // ----------------------------------------------------------
  static TextStyle chartLabel(BuildContext context, {required bool isActive}) =>
      TextStyle(
        color: isActive ? context.colors.chartHighlight : context.colors.chartLabel,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      );

  static TextStyle chartValue(BuildContext context, {required bool isActive}) =>
      TextStyle(
        color: isActive ? context.colors.chartHighlight : context.colors.chartValue,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      );

  // ----------------------------------------------------------
  // プロジェクト詳細モーダル
  // ----------------------------------------------------------
  static TextStyle modalLabel(BuildContext context, double fontSize) => TextStyle(
        fontWeight: FontWeight.bold,
        color: context.colors.modalLabel,
        fontSize: fontSize,
      );

  static TextStyle modalValue(BuildContext context, bool isBold) => TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: context.colors.modalValue,
      );

  static ButtonStyle linkButton(BuildContext context) => ElevatedButton.styleFrom(
        backgroundColor: context.colors.linkButtonBackground,
        foregroundColor: context.colors.linkButtonForeground,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );

  // ----------------------------------------------------------
  // ダイアログ（YAML アップロード）
  // ----------------------------------------------------------
  static TextStyle dialogTitle(BuildContext context) =>
      TextStyle(color: context.colors.textStrong);

  static TextStyle dialogBody(BuildContext context) =>
      TextStyle(fontSize: 13, color: context.colors.textSoft);

  static TextStyle dialogSuccess(BuildContext context) =>
      TextStyle(fontSize: 12, color: context.colors.success);

  static TextStyle dialogError(BuildContext context) =>
      TextStyle(fontSize: 12, color: context.colors.error);

  // ----------------------------------------------------------
  // フォーマット説明（ⓘ ボタンで開くヘルプ）
  // ----------------------------------------------------------
  static TextStyle helpHeading(BuildContext context) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.colors.textStrong,
      );

  static TextStyle helpBody(BuildContext context) =>
      TextStyle(fontSize: 13, height: 1.5, color: context.colors.textSoft);

  /// 必須項目などの強調
  static TextStyle helpEmphasis(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: context.colors.error,
      );

  static BoxDecoration codeBlock(BuildContext context) => BoxDecoration(
        color: context.colors.codeBackground,
        border: Border.all(color: context.colors.codeBorder),
        borderRadius: BorderRadius.circular(radiusMd),
      );

  static TextStyle codeText(BuildContext context) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.4,
        color: context.colors.textPrimary,
      );

  // ----------------------------------------------------------
  // Home（Hero）
  // ----------------------------------------------------------
  static TextStyle heroName(BuildContext context, double fontSize) => TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: context.colors.heroForeground,
      );

  static TextStyle heroRole(BuildContext context, double fontSize) => TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: context.colors.heroForeground,
      );

  static TextStyle heroTagline(BuildContext context, double fontSize) => TextStyle(
        fontSize: fontSize,
        height: 1.7,
        color: context.colors.heroForegroundMuted,
      );

  static ButtonStyle heroPrimaryButton(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: context.colors.heroPrimaryButtonBackground,
        foregroundColor: context.colors.heroPrimaryButtonForeground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      );

  static ButtonStyle heroSecondaryButton(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: context.colors.heroForeground,
        side: BorderSide(color: context.colors.heroSecondaryButtonBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      );

  static BoxDecoration heroCodeCard(BuildContext context) => BoxDecoration(
        color: context.colors.heroCodeBackground,
        border: Border.all(color: context.colors.heroCodeBorder),
        borderRadius: BorderRadius.circular(radiusLg),
      );

  static TextStyle heroCode(BuildContext context, {bool isKey = false}) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 15,
        height: 1.7,
        color: isKey ? context.colors.heroCodeKey : context.colors.heroCodeValue,
      );

  // ----------------------------------------------------------
  // About
  // ----------------------------------------------------------
  static TextStyle aboutHeading(BuildContext context, double fontSize) => TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: context.colors.textStrong,
      );

  /// 自己紹介の段落（本文より一回り大きく）
  static TextStyle aboutLead(BuildContext context, double fontSize) => TextStyle(
        fontSize: fontSize,
        height: 1.8,
        color: context.colors.textPrimary,
      );

  /// 定義リストの見出し（強み・得意な領域…）
  static TextStyle aboutTerm(BuildContext context) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: context.colors.textStrong,
      );

  static TextStyle aboutDescription(BuildContext context) => TextStyle(
        fontSize: 16,
        height: 1.7,
        color: context.colors.textPrimary,
      );

  static TextStyle aboutClosing(BuildContext context) => TextStyle(
        fontSize: 18,
        height: 1.7,
        fontWeight: FontWeight.w600,
        color: context.colors.textStrong,
      );

  // ----------------------------------------------------------
  // Projects：ツールバーのセグメント（Work/Private・List/Collection）
  // ----------------------------------------------------------
  static BoxDecoration segmentTrack(BuildContext context) => BoxDecoration(
        color: context.colors.segmentBackground,
        borderRadius: BorderRadius.circular(radiusLg),
      );

  static BoxDecoration segmentItem(BuildContext context, {required bool selected}) =>
      BoxDecoration(
        color: selected ? context.colors.segmentSelectedBackground : null,
        borderRadius: BorderRadius.circular(radiusMd),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: context.colors.segmentSelectedShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      );

  static TextStyle segmentLabel(BuildContext context, {required bool selected}) =>
      TextStyle(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? context.colors.textStrong : context.colors.textSecondary,
      );

  static Color segmentIcon(BuildContext context, {required bool selected}) =>
      selected ? context.colors.textStrong : context.colors.textSecondary;

  /// セグメント内の件数（Work 3 の「3」）
  static TextStyle segmentCount(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: context.colors.textTertiary,
      );

  /// ツールバーのボタン（フィルター）。開いている間は枠を強調
  static ButtonStyle toolbarButton(BuildContext context, {required bool active}) =>
      OutlinedButton.styleFrom(
        foregroundColor: context.colors.textStrong,
        backgroundColor: active ? context.colors.segmentBackground : null,
        side: BorderSide(
          color: active ? context.colors.textSecondary : context.colors.surfaceBorder,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );

  static BoxDecoration countBadge(BuildContext context) => BoxDecoration(
        color: context.colors.countBadgeBackground,
        borderRadius: BorderRadius.circular(radiusLg),
      );

  static TextStyle countBadgeText(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: context.colors.countBadgeForeground,
      );

  // ----------------------------------------------------------
  // Projects：フィルター
  // ----------------------------------------------------------
  static BoxDecoration filterPanel(BuildContext context) => BoxDecoration(
        color: context.colors.filterPanelBackground,
        border: Border.all(color: context.colors.surfaceBorder),
        borderRadius: BorderRadius.circular(radiusLg),
      );

  /// フィルターのグループ名（Server OS / DB …）
  static TextStyle filterGroupLabel(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
      );

  static BoxDecoration activeFilter(BuildContext context) => BoxDecoration(
        color: context.colors.activeFilterBackground,
        borderRadius: BorderRadius.circular(radiusLg),
      );

  static TextStyle activeFilterText(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.activeFilterForeground,
      );

  // ----------------------------------------------------------
  // Projects：カード（List / Collection 共通）
  // ----------------------------------------------------------
  static BoxDecoration projectCard(BuildContext context) => BoxDecoration(
        color: context.colors.cardBackground,
        border: Border.all(color: context.colors.surfaceBorder),
        borderRadius: BorderRadius.circular(radiusLg),
      );

  static TextStyle cardTitle(BuildContext context) => TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: context.colors.textStrong,
      );

  static TextStyle cardDescription(BuildContext context) => TextStyle(
        fontSize: 14,
        height: 1.5,
        color: context.colors.textSecondary,
      );

  static TextStyle cardMeta(BuildContext context) => TextStyle(
        fontSize: 12,
        color: context.colors.textTertiary,
      );
}
