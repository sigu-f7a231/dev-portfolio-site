// lib/theme/app_styles.dart
//
// ============================================================
// UI 共通スタイル（CSS に相当する部分）— Material 3 準拠
// ============================================================
// - 文字は M3 のタイプスケール（Theme.of(context).textTheme の display / headline / title / body / label）を土台にする。
// - 角丸は M3 のシェイプスケール（extra small 4 / small 8 / medium 12 / large 16 / extra large 28 / full）。
// - 色は app_colors.dart から取る（このファイルでは Colors.xxx を直接書かない）。
// - セクション固有のサイズ（カード幅、グラフ半径など）は sections/config/ に置く。
import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppStyles {
  AppStyles._();

  // ----------------------------------------------------------
  // 角丸（M3 シェイプスケール）
  // ----------------------------------------------------------
  /// extra small：ツールチップ・小さなラベル
  static const double radiusSm = 4;

  /// small：チップ・タグ
  static const double radiusMd = 8;

  /// medium：カード
  static const double radiusLg = 12;

  /// large：パネル・大きめのカード
  static const double radiusXl = 16;

  /// extra large：ダイアログ
  static const double radiusXxl = 28;

  /// full：ボタン・バッジ（両端が丸い）
  static const double radiusFull = 999;

  static TextTheme _text(BuildContext context) => Theme.of(context).textTheme;

  // ----------------------------------------------------------
  // テキスト（M3 タイプスケール）
  // ----------------------------------------------------------
  /// 見出し（headline / title）。fontSize を渡すと大きさだけ変える
  static TextStyle title(BuildContext context, {double? fontSize}) =>
      _text(context).headlineSmall!.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: context.colors.textStrong,
          );

  /// 本文（body large）
  static TextStyle body(
    BuildContext context, {
    double? fontSize,
    FontStyle? fontStyle,
  }) =>
      _text(context).bodyLarge!.copyWith(
            fontSize: fontSize,
            fontStyle: fontStyle,
            color: context.colors.textPrimary,
          );

  /// サブテキスト（body medium / onSurfaceVariant）
  static TextStyle secondary(BuildContext context, {double? fontSize}) =>
      _text(context).bodyMedium!.copyWith(
            fontSize: fontSize,
            color: context.colors.textSecondary,
          );

  /// 補足テキスト（body small / outline）
  static TextStyle tertiary(BuildContext context, {double? fontSize}) =>
      _text(context).bodySmall!.copyWith(
            fontSize: fontSize,
            color: context.colors.textTertiary,
          );

  // ----------------------------------------------------------
  // カード（M3 Elevated card：影はライトのみ）
  // ----------------------------------------------------------
  static BoxDecoration card(
    BuildContext context, {
    double radius = radiusLg,
    double shadowBlur = 8,
    Offset shadowOffset = const Offset(0, 2),
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
  // スキルタグ（M3 Assist chip 風：small の角丸）
  // ----------------------------------------------------------
  static const EdgeInsets skillTagPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const double skillTagSpacing = 6;
  static const double skillTagRunSpacing = 6;

  static BoxDecoration skillTag(BuildContext context) => BoxDecoration(
        color: context.colors.skillTagBackground,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  static TextStyle skillTagText(BuildContext context) =>
      _text(context).labelMedium!.copyWith(color: context.colors.skillTagForeground);

  // ----------------------------------------------------------
  // 進行中タグ（tertiary container）
  // ----------------------------------------------------------
  static const EdgeInsets ongoingTagPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 2);

  static BoxDecoration ongoingTag(BuildContext context) => BoxDecoration(
        color: context.colors.ongoingTagBackground,
        borderRadius: BorderRadius.circular(radiusSm),
      );

  static TextStyle ongoingTagText(BuildContext context) =>
      _text(context).labelSmall!.copyWith(color: context.colors.ongoingTagForeground);

  // ----------------------------------------------------------
  // グラフ（凡例のラベル・％値）
  // ----------------------------------------------------------
  static TextStyle chartLabel(BuildContext context, {required bool isActive}) =>
      _text(context).bodyMedium!.copyWith(
            color: isActive ? context.colors.chartHighlight : context.colors.chartLabel,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          );

  static TextStyle chartValue(BuildContext context, {required bool isActive}) =>
      _text(context).bodyMedium!.copyWith(
            color: isActive ? context.colors.chartHighlight : context.colors.chartValue,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          );

  // ----------------------------------------------------------
  // プロジェクト詳細モーダル
  // ----------------------------------------------------------
  static TextStyle modalLabel(BuildContext context, double fontSize) =>
      _text(context).titleSmall!.copyWith(
            fontSize: fontSize,
            color: context.colors.modalLabel,
          );

  static TextStyle modalValue(BuildContext context, bool isBold) =>
      _text(context).bodyMedium!.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: context.colors.modalValue,
          );

  /// 「公開ページを見る」（M3 Filled button）
  static ButtonStyle linkButton(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: context.colors.linkButtonBackground,
        foregroundColor: context.colors.linkButtonForeground,
      );

  // ----------------------------------------------------------
  // ダイアログ（YAML アップロード）
  // ----------------------------------------------------------
  static TextStyle dialogTitle(BuildContext context) =>
      _text(context).headlineSmall!.copyWith(color: context.colors.textStrong);

  static TextStyle dialogBody(BuildContext context) =>
      _text(context).bodyMedium!.copyWith(color: context.colors.textSoft);

  static TextStyle dialogSuccess(BuildContext context) =>
      _text(context).bodySmall!.copyWith(color: context.colors.success);

  static TextStyle dialogError(BuildContext context) =>
      _text(context).bodySmall!.copyWith(color: context.colors.error);

  // ----------------------------------------------------------
  // フォーマット説明（ⓘ ボタンで開くヘルプ）
  // ----------------------------------------------------------
  static TextStyle helpHeading(BuildContext context) =>
      _text(context).titleSmall!.copyWith(color: context.colors.textStrong);

  static TextStyle helpBody(BuildContext context) =>
      _text(context).bodyMedium!.copyWith(height: 1.5, color: context.colors.textSoft);

  /// 必須項目などの強調
  static TextStyle helpEmphasis(BuildContext context) =>
      _text(context).bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.error,
          );

  static BoxDecoration codeBlock(BuildContext context) => BoxDecoration(
        color: context.colors.codeBackground,
        border: Border.all(color: context.colors.codeBorder),
        borderRadius: BorderRadius.circular(radiusLg),
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
  /// 名前（display）
  static TextStyle heroName(BuildContext context, double fontSize) =>
      _text(context).displayLarge!.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: context.colors.heroForeground,
          );

  /// 職種（title large）
  static TextStyle heroRole(BuildContext context, double fontSize) =>
      _text(context).titleLarge!.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: context.colors.heroForeground,
          );

  /// 紹介文（body large）
  static TextStyle heroTagline(BuildContext context, double fontSize) =>
      _text(context).bodyLarge!.copyWith(
            fontSize: fontSize,
            height: 1.7,
            color: context.colors.heroForegroundMuted,
          );

  /// 「スキルを見る」（M3 Filled button。形は M3 既定の full）
  static ButtonStyle heroPrimaryButton(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: context.colors.heroPrimaryButtonBackground,
        foregroundColor: context.colors.heroPrimaryButtonForeground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _text(context).labelLarge,
      );

  /// 「プロジェクトを見る」（M3 Outlined button）
  static ButtonStyle heroSecondaryButton(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: context.colors.heroForeground,
        side: BorderSide(color: context.colors.heroSecondaryButtonBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _text(context).labelLarge,
      );

  static BoxDecoration heroCodeCard(BuildContext context) => BoxDecoration(
        color: context.colors.heroCodeBackground,
        border: Border.all(color: context.colors.heroCodeBorder),
        borderRadius: BorderRadius.circular(radiusXl),
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
  static TextStyle aboutHeading(BuildContext context, double fontSize) =>
      _text(context).displaySmall!.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: context.colors.textStrong,
          );

  /// 自己紹介の段落
  static TextStyle aboutLead(BuildContext context, double fontSize) =>
      _text(context).bodyLarge!.copyWith(
            fontSize: fontSize,
            height: 1.8,
            color: context.colors.textPrimary,
          );

  /// 定義リストの見出し（強み・得意な領域…）
  static TextStyle aboutTerm(BuildContext context) =>
      _text(context).titleSmall!.copyWith(color: context.colors.textStrong);

  static TextStyle aboutDescription(BuildContext context) =>
      _text(context).bodyLarge!.copyWith(height: 1.7, color: context.colors.textPrimary);

  static TextStyle aboutClosing(BuildContext context) =>
      _text(context).titleMedium!.copyWith(height: 1.7, color: context.colors.textStrong);

  // ----------------------------------------------------------
  // セグメント（M3 SegmentedButton の中の件数表示）
  // ----------------------------------------------------------
  static TextStyle segmentCount(BuildContext context) =>
      _text(context).labelSmall!.copyWith(color: context.colors.textTertiary);

  // ----------------------------------------------------------
  // ツールバーのボタン（フィルター・カテゴリ）
  // 開いている間は secondary container で塗る（M3 の選択状態）
  // ----------------------------------------------------------
  static ButtonStyle toolbarButton(BuildContext context, {required bool active}) =>
      OutlinedButton.styleFrom(
        foregroundColor:
            active ? context.colors.activeFilterForeground : context.colors.textStrong,
        backgroundColor: active ? context.colors.activeFilterBackground : null,
        side: BorderSide(
          color: active ? context.colors.activeFilterBackground : context.colors.surfaceBorder,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: _text(context).labelLarge,
      );

  /// 件数・現在値のバッジ（full の角丸）
  static BoxDecoration countBadge(BuildContext context) => BoxDecoration(
        color: context.colors.countBadgeBackground,
        borderRadius: BorderRadius.circular(radiusFull),
      );

  static TextStyle countBadgeText(BuildContext context) =>
      _text(context).labelSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.countBadgeForeground,
          );

  // ----------------------------------------------------------
  // フィルター / カテゴリのパネル（large の角丸）
  // ----------------------------------------------------------
  static BoxDecoration filterPanel(BuildContext context) => BoxDecoration(
        color: context.colors.filterPanelBackground,
        border: Border.all(color: context.colors.surfaceBorder),
        borderRadius: BorderRadius.circular(radiusXl),
      );

  /// グループ名（Server OS / DB …）
  static TextStyle filterGroupLabel(BuildContext context) =>
      _text(context).titleSmall!.copyWith(color: context.colors.textSecondary);

  /// 適用中のフィルター（M3 Input chip 風）
  static BoxDecoration activeFilter(BuildContext context) => BoxDecoration(
        color: context.colors.activeFilterBackground,
        borderRadius: BorderRadius.circular(radiusMd),
      );

  static TextStyle activeFilterText(BuildContext context) =>
      _text(context).labelLarge!.copyWith(color: context.colors.activeFilterForeground);

  // ----------------------------------------------------------
  // Projects：カード（M3 Outlined card、medium の角丸）
  // ----------------------------------------------------------
  static BoxDecoration projectCard(BuildContext context) => BoxDecoration(
        color: context.colors.cardBackground,
        border: Border.all(color: context.colors.surfaceBorder),
        borderRadius: BorderRadius.circular(radiusLg),
      );

  static TextStyle cardTitle(BuildContext context) =>
      _text(context).titleMedium!.copyWith(
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: context.colors.textStrong,
          );

  static TextStyle cardDescription(BuildContext context) =>
      _text(context).bodyMedium!.copyWith(
            height: 1.5,
            color: context.colors.textSecondary,
          );

  static TextStyle cardMeta(BuildContext context) =>
      _text(context).bodySmall!.copyWith(color: context.colors.textTertiary);
}
