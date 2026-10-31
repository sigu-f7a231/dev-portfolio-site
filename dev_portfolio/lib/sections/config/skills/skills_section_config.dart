// ※現在どこからも参照されていない
// 色は lib/theme/app_colors.dart で管理
import '../../../constants/app_texts.dart';

/// Skills セクション全体の設定
class SkillsSectionConfig {
  /// カテゴリ一覧
  static const List<String> categories = [
    'skills',
    'server_os',
    'db',
    'tools_fw',
  ];

  /// メインタブ名
  static const List<String> mainTabs = [
    AppTexts.work,
    AppTexts.private,
  ];
}

/// 共通レイアウト設定
class SkillsLayout {
  static const double sectionPadding = 24;
  static const double spacing = 16;
}
