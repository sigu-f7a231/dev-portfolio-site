// lib/sections/projects/views/project_card_parts.dart
//
// List / Collection のカードで共通に使う部品
import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../../config/projects/projects_views_list_config.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_styles.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_texts.dart';

/// スキルタグ。maxTags を超えた分は「+N」にまとめる（null なら全部出す）
class ProjectSkillTags extends StatelessWidget {
  final Project project;
  final int? maxTags;

  /// true なら 1 行に収め、はみ出す分は切る（高さが決まっている Collection のカード用）
  final bool singleLine;

  const ProjectSkillTags({
    super.key,
    required this.project,
    this.maxTags,
    this.singleLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final skills = project.skillsList;
    if (skills.isEmpty) return const SizedBox.shrink();

    final shown = maxTags == null ? skills : skills.take(maxTags!).toList();
    final rest = skills.length - shown.length;

    Widget tag(String text) => Container(
          padding: AppStyles.skillTagPadding,
          decoration: AppStyles.skillTag(context),
          child: Text(text, style: AppStyles.skillTagText(context)),
        );

    final children = [
      ...shown.map(tag),
      if (rest > 0) tag(AppTexts.moreTags(rest)),
    ];

    if (singleLine) {
      return ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: AppStyles.skillTagSpacing),
                children[i],
              ],
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppStyles.skillTagSpacing,
      runSpacing: AppStyles.skillTagRunSpacing,
      children: children,
    );
  }
}

/// プロジェクトごとに決まる色の番号（タイトルから計算するので、ページを変えても同じ色）
int projectColorSeed(Project p) =>
    p.title.codeUnits.fold<int>(0, (sum, c) => (sum * 31 + c) & 0x7fffffff);

/// 「進行中」ラベル
class OngoingTag extends StatelessWidget {
  const OngoingTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppStyles.ongoingTagPadding,
      decoration: AppStyles.ongoingTag(context),
      child: Text(AppTexts.ongoing, style: AppStyles.ongoingTagText(context)),
    );
  }
}

/// 期間：［📅 2023年4月 → 2023年9月］ 6か月
/// - 枠線だけの枠（下に並ぶスキルタグの塗りと見分けがつくように）
/// - 進行中は終わりを「現在」にし、今日までの長さを出す
/// - 「YYYY-MM ~ YYYY-MM」の形でない期間は、文字のまま出す
class ProjectPeriod extends StatelessWidget {
  final Project project;

  /// 長さ（6か月など）を横に出すか（Collection はカバーに出すので false）
  final bool showDuration;

  /// true なら長さを塗りの札で目立たせる（List 用）
  final bool emphasizeDuration;

  const ProjectPeriod({
    super.key,
    required this.project,
    this.showDuration = true,
    this.emphasizeDuration = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!project.hasValidPeriod) {
      return Text(project.period, style: AppStyles.cardMeta(context));
    }

    final from = AppTexts.yearMonth(project.periodStart);
    final to = project.isOngoing ? AppTexts.periodNow : AppTexts.yearMonth(project.periodEnd);
    final duration = AppTexts.durationLabel(project.durationMonths);

    return Semantics(
      label: AppTexts.periodSemantics(from, to, duration),
      excludeSemantics: true,
      child: Wrap(
        spacing: ProjectsListConfig.cardPeriodSpacing,
        runSpacing: AppSizes.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: ProjectsListConfig.cardPeriodPadding,
            decoration: AppStyles.cardPeriod(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: ProjectsListConfig.scheduleIconSize,
                  color: context.colors.textTertiary,
                ),
                const SizedBox(width: ProjectsListConfig.cardPeriodIconGap),
                Text(AppTexts.periodSpan(from, to), style: AppStyles.cardPeriodText(context)),
              ],
            ),
          ),
          if (showDuration)
            emphasizeDuration
                ? Container(
                    padding: ProjectsListConfig.cardPeriodPadding,
                    decoration: AppStyles.countBadge(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: ProjectsListConfig.scheduleIconSize,
                          color: AppStyles.countBadgeText(context).color,
                        ),
                        const SizedBox(width: ProjectsListConfig.cardPeriodIconGap),
                        Text(duration, style: AppStyles.countBadgeText(context)),
                      ],
                    ),
                  )
                : Text(duration, style: AppStyles.cardPeriodDuration(context)),
        ],
      ),
    );
  }
}
