import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import 'project_data_dialog.dart';
import 'download_menu.dart';
import 'header_parts.dart';
import '../../constants/app_texts.dart';

class MobileHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final VoidCallback? onYamlStateChanged; // ★ 追加

  const MobileHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    this.onYamlStateChanged, // ★ 追加
  });

  // ［データ］：Work / Private のプロジェクトの追加・更新（中身は project_data_dialog.dart）
  void _showDataDialog(BuildContext context) =>
      showProjectDataDialog(context, onSaved: onYamlStateChanged);

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colors.headerForeground;

    return AppBar(
      title: Text(
        AppTexts.appTitle,
        style: AppStyles.headerTitle(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: context.colors.headerBackground,
      surfaceTintColor: context.colors.headerBackground,
      iconTheme: IconThemeData(color: iconColor),
      actionsIconTheme: IconThemeData(color: context.colors.headerForegroundMuted),
      shape: Border(bottom: BorderSide(color: context.colors.headerDivider)),
      actions: [
        // ★ モバイル版でもアップロードできるようにアイコンを追加
        HeaderUploadButton(
          icon: Icons.dataset_outlined,
          label: DataTexts.button,
          tooltip: DataTexts.buttonTooltip,
          showLabel: false,
          onPressed: () => _showDataDialog(context),
        ),
        // スキルシート（Excel / PDF）のダウンロード
        const HeaderDownloadButton(showLabel: false),
        // ライト / ダーク切替（太陽 ⇄ 月）
        const ThemeModeSwitch(compact: true),
      ],
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
    );
  }
}