// lib/constants/app_sizes.dart
//
// ============================================================
// 余白・サイズ・時間などの数値（ウィジェットに直接数値を書かず、ここから参照する）
// ============================================================
// - 色は lib/theme/app_colors.dart、文字スタイル・角丸は lib/theme/app_styles.dart。
// - セクション固有のまとまった設定（グラフ半径・カード幅など）は sections/config/ にある。
import 'package:flutter/material.dart';

class AppSizes {
  /// 対応する最小の画面幅（iPhone SE などの 320px）。
  /// これより狭い画面では、この幅のレイアウトを画面幅に合わせて縮小して表示する（はみ出しエラーを防ぐ）
  static const double minSupportedWidth = 320;

  AppSizes._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  // ----------------------------------------------------------
  // 余白のスケール（SizedBox / EdgeInsets / Wrap の spacing などに使う）
  // ----------------------------------------------------------
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space36 = 36;
  static const double space40 = 40;
  static const double space48 = 48;

  // ----------------------------------------------------------
  // アニメーション・時間
  // ----------------------------------------------------------
  /// ナビゲーションでセクションへスクロールする時間
  static const Duration scrollDuration = Duration(milliseconds: 500);

  /// フィルター適用時に Work/Private 切替を少し下げるアニメーション
  static const Duration filterPaddingDuration = Duration(milliseconds: 150);

  /// フィルターパネルの開閉
  /// フィルター / カテゴリのポップアップ：この幅以上は中央のダイアログ、未満は下から出るシート
  static const double filterModalBreakpoint = 600;
  static const double filterModalMaxWidth = 720;

  /// ポップアップの最大の高さ（画面の高さに対する割合）
  static const double filterDialogMaxHeightRatio = 0.85;
  static const double filterSheetMaxHeightRatio = 0.9;

  static const Duration filterPanelDuration = Duration(milliseconds: 200);

  /// ダウンロード用の一時 URL を解放するまでの待ち時間
  static const Duration downloadUrlRevokeDelay = Duration(seconds: 1);

  /// 描画が落ち着くまで Progress を出す部品（SettledReveal）
  /// - 最低表示時間：重い描画でも描き切れるよう余裕を持たせる
  static const Duration revealMinDuration = Duration(milliseconds: 800);
  static const Duration revealFadeDuration = Duration(milliseconds: 200);

  /// 「描画が落ち着いた」とみなすまでに待つフレーム数（SettledReveal・起動時の app-ready 共通）
  static const int settleFrames = 6;

  /// アップロード後の全画面ローディング：最低この時間は出す（読み込み・描き直しが終わるのを待つ）
  static const Duration reloadMinDuration = Duration(seconds: 5);

  /// 読み込みが終わらなくても、この時間で打ち切って画面を出す
  static const Duration reloadMaxDuration = Duration(seconds: 8);

  /// 確認画面の一覧の最大の高さ
  static const double confirmListMaxHeight = 320;

  /// テキスト貼り付け画面の入力欄の行数（最小・最大。超えたら入力欄の中でスクロール）
  static const int pasteMinLines = 8;
  static const int pasteMaxLines = 16;

  /// 上書きの確認で、項目ごとに並べるタイトルの最大数（超えた分は「…ほか n 件」）
  static const int overwriteMaxTitles = 8;

  // ----------------------------------------------------------
  // 読み込み中（M3 Progress indicator・円形）
  // ----------------------------------------------------------
  /// 円の直径（M3 の既定 40dp）
  static const double loadingIndicatorSize = 40;

  /// ボタンの中など小さく使うときの線の太さ（通常は M3 既定の 4dp）
  static const double loadingIndicatorStrokeSmall = 2;

  // ----------------------------------------------------------
  // Drawer
  // ----------------------------------------------------------
  /// NavigationDrawer の見出しの余白（M3 の指定値）
  static const EdgeInsets drawerHeaderPadding = EdgeInsets.fromLTRB(28, 16, 16, 10);

  // ----------------------------------------------------------
  // ダイアログ（YAML アップロード / 書き方の説明）
  // ----------------------------------------------------------
  static const double uploadDialogWidth = 450;

  /// プロジェクトの入力フォームの期間（開始・終了）の欄の幅（狭い画面では縦に並ぶ）
  static const double projectFormPeriodWidth = 180;

  /// スキルシートを作る前に、ローディングを描くための待ち時間
  static const Duration downloadStartDelay = Duration(milliseconds: 80);

  /// 年と月を選ぶ画面（lib/widgets/year_month_picker.dart）
  static const double yearMonthPickerWidth = 360;
  static const double yearMonthPickerGridHeight = 232;
  static const double yearMonthPickerCellAspect = 2.2;
  static const int yearMonthPickerFirstYear = 1980; // 選べるいちばん前の年
  static const int yearMonthPickerYearsAhead = 5; // 今年から何年先まで選べるか

  /// プロフィール入力画面：見出し右の ⓘ ボタンの幅・手順の番号の丸
  static const double profileHelpButtonSize = 48;
  static const double profileStepRadius = 12;
  static const double helpDialogWidth = 560;

  /// ボタン内のローディング表示
  static const double buttonLoadingSize = 16;

  // ----------------------------------------------------------
  // Projects
  // ----------------------------------------------------------
  /// ページネーションバーの高さ
  static const double paginationBarHeight = 60;

  /// 詳細モーダルの項目の文字サイズ
  static const double modalFieldFontSize = 14;
  static const double modalTitleFontSize = 18;

  // ----------------------------------------------------------
  // Skills
  // ----------------------------------------------------------
  /// グラフに出す上位件数（それ以降は「その他」にまとめる）
  static const int chartTopN = 10;

  /// （未使用の SkillsTabs 用）メッセージの文字サイズ
  static const double skillsTabsMessageFontSize = 16;
}
