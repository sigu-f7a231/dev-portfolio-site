import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import 'yaml_upload_dialog.dart';
import 'header_parts.dart';
import '../config/header_config.dart';
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

  // Work / Private のアップロード画面（中身は yaml_upload_dialog.dart で共通）
  void _showWorkUploadDialog(BuildContext context) =>
      showYamlUploadDialog(context, dataType: 'work', onSaved: onYamlStateChanged);

  void _showPrivateUploadDialog(BuildContext context) =>
      showYamlUploadDialog(context, dataType: 'private', onSaved: onYamlStateChanged);

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colors.headerForeground;

    return AppBar(
      title: Text(AppTexts.appTitle, style: AppStyles.headerTitle(context)),
      backgroundColor: context.colors.headerBackground,
      surfaceTintColor: context.colors.headerBackground,
      iconTheme: IconThemeData(color: iconColor),
      actionsIconTheme: IconThemeData(color: context.colors.headerForegroundMuted),
      shape: Border(bottom: BorderSide(color: context.colors.headerDivider)),
      actions: [
        // ★ モバイル版でもアップロードできるようにアイコンを追加
        HeaderUploadButton(
          icon: Icons.work_outline,
          label: AppTexts.work,
          tooltip: AppTexts.workUploadTooltip,
          showLabel: false,
          onPressed: () => _showWorkUploadDialog(context),
        ),
        const SizedBox(width: HeaderConfig.navGap),
        HeaderUploadButton(
          icon: Icons.lock_outline,
          label: AppTexts.private,
          tooltip: AppTexts.privateUploadTooltip,
          showLabel: false,
          onPressed: () => _showPrivateUploadDialog(context),
        ),
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