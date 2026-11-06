// lib/sections/skills/widgets/skills_header.dart
import 'package:flutter/material.dart';
import '../../config/skills/skills_widgets_header_config.dart';
import '../../../theme/app_styles.dart';
import '../../../constants/app_texts.dart';

/// Skills セクションのタイトル（Bar/Pie の切替はツールバーに移動）
class SkillsHeader extends StatelessWidget {
  const SkillsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SkillsHeaderConfig.titlePadding,
      child: Text(
        AppTexts.navSkills,
        style: AppStyles.title(context, fontSize: SkillsHeaderConfig.titleFontSize),
      ),
    );
  }
}
