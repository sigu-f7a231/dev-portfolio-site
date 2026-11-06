// lib/sections/hero_section.dart
//
// Home：すべて中央寄せで、上から
//   職種 → 名前 → 紹介文 → ［スキルを見る］［プロジェクトを見る］ → まとめ（開発経験・プロジェクトの件数・直近のプロジェクト）
// まとめは Skills・Projects の中身をくり返さず、全体の大きさと、いちばん新しい案件だけを出す（lib/utils/hero_summary.dart）
// - プロジェクトの件数を押す → Projects へ。直近のプロジェクトを押す → その案件の詳細
// - 幅があれば 3 つを横に、狭ければ縦に積む
// 名前などはプロフィール（profileProvider）、まとめは今の Work / Private（projectRecordsProvider）から作る（lib/state/providers.dart）。
// ［データ］で案件を変えると dataRevisionProvider が増え、Work / Private を読み直してまとめも作り直す
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../models/profile.dart';
import '../theme/app_styles.dart';
import '../theme/app_theme.dart';
import '../utils/hero_summary.dart';
import '../state/providers.dart';
import 'config/hero_section_config.dart';
import 'projects/models/projects_model.dart';
import 'projects/views/project_list/project_list_modal_function.dart';

class HeroSection extends ConsumerWidget {
  final VoidCallback? onSkillsPressed;
  final VoidCallback? onProjectsPressed;

  const HeroSection({
    super.key,
    this.onSkillsPressed,
    this.onProjectsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 名前などはプロフィール、まとめは Work / Private から（どちらも Riverpod。［データ］で変えたら作り直す）
    final profile = ref.watch(profileProvider) ?? Profile.empty;
    final records = ref.watch(projectRecordsProvider).value; // 読み込み中は前の値、読めなければ null（まとめを出さない）
    final summary = records == null
        ? null
        : HeroSummary.of(
            [for (final p in records.work) Project.fromMap(p)],
            [for (final p in records.private) Project.fromMap(p)],
          );
    return _build(context, profile, summary);
  }

  Widget _build(BuildContext context, Profile profile, HeroSummary? summary) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: HeroSectionConfig.height(context)),
      color: context.colors.heroBackground,
      padding: HeroSectionConfig.padding,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: HeroSectionConfig.maxContentWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= HeroSectionConfig.wideBreakpoint;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Intro(
                  profile: profile,
                  isWide: isWide,
                  onSkillsPressed: onSkillsPressed,
                  onProjectsPressed: onProjectsPressed,
                ),
                if (summary != null && !summary.isEmpty) ...[
                  const SizedBox(height: HeroSectionConfig.summaryGap),
                  _Summary(summary: summary, onProjectsPressed: onProjectsPressed),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 職種・名前・紹介文・ボタン（中央寄せ）
class _Intro extends StatelessWidget {
  final Profile profile;
  final bool isWide;
  final VoidCallback? onSkillsPressed;
  final VoidCallback? onProjectsPressed;

  const _Intro({
    required this.profile,
    required this.isWide,
    this.onSkillsPressed,
    this.onProjectsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          profile.role,
          textAlign: TextAlign.center,
          style: AppStyles.heroRole(context, HeroSectionConfig.roleFontSize),
        ),
        const SizedBox(height: AppSizes.space12),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: AppStyles.heroName(
            context,
            isWide ? HeroSectionConfig.nameFontSizeWide : HeroSectionConfig.nameFontSizeNarrow,
          ),
        ),
        const SizedBox(height: AppSizes.space24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HeroSectionConfig.taglineMaxWidth),
          child: Text(
            profile.tagline,
            textAlign: TextAlign.center,
            style: AppStyles.heroTagline(context, HeroSectionConfig.taglineFontSize),
          ),
        ),
        const SizedBox(height: AppSizes.space36),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSizes.space12,
          runSpacing: AppSizes.space12,
          children: [
            FilledButton(
              onPressed: onSkillsPressed,
              style: AppStyles.heroPrimaryButton(context),
              child: const Text(HeroContent.skillsButtonLabel),
            ),
            OutlinedButton(
              onPressed: onProjectsPressed,
              style: AppStyles.heroSecondaryButton(context),
              child: const Text(HeroContent.projectsButtonLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// ボタンの下のまとめ：開発経験・プロジェクトの件数・直近のプロジェクト
class _Summary extends StatelessWidget {
  final HeroSummary summary;
  final VoidCallback? onProjectsPressed;

  const _Summary({required this.summary, this.onProjectsPressed});

  @override
  Widget build(BuildContext context) {
    final since = summary.since;
    final latest = summary.latest;
    final cards = <Widget>[
      if (since != null)
        _SummaryCard(
          icon: Icons.timeline,
          label: HeroContent.summaryExperience,
          value: AppTexts.durationLabel(summary.experienceMonths),
          sub: HeroContent.experienceSince(since),
        ),
      _SummaryCard(
        icon: Icons.folder_open_outlined,
        label: HeroContent.summaryProjects,
        value: HeroContent.projectsCount(summary.totalCount),
        sub: HeroContent.projectsBreakdown(summary.workCount, summary.privateCount),
        tooltip: HeroContent.projectsTooltip,
        onTap: onProjectsPressed,
      ),
      if (latest != null)
        _SummaryCard(
          icon: latest.isOngoing ? Icons.play_circle_outline : Icons.history,
          label: HeroContent.summaryLatest,
          value: latest.title,
          smallValue: true,
          sub: [
            HeroContent.latestPeriod(
              AppTexts.yearMonth(latest.periodStart),
              latest.isOngoing ? AppTexts.periodNow : AppTexts.yearMonth(latest.periodEnd),
            ),
            if (summary.latestIsPrivate) HeroContent.latestPrivate,
          ].join('・'),
          tooltip: HeroContent.latestTooltip,
          onTap: () => showProjectDetailModal(context, latest),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= HeroSectionConfig.summaryRowBreakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSizes.space16),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: HeroSectionConfig.summaryColumnMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSizes.space12),
                cards[i],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// まとめの 1 枚（見出し・値・補足。押せるものは右上に › を出す）
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final bool smallValue;
  final String? tooltip;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.smallValue = false,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HeroSectionConfig.summaryCardMinHeight),
      child: Padding(
        padding: HeroSectionConfig.summaryCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: HeroSectionConfig.summaryIconSize, color: AppStyles.heroSummaryIcon(context)),
                const SizedBox(width: AppSizes.space8),
                Expanded(
                  child: Text(label,
                      style: AppStyles.heroSummaryLabel(context, HeroSectionConfig.summaryLabelFontSize)),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right,
                      size: HeroSectionConfig.summaryIconSize, color: AppStyles.heroSummaryIcon(context)),
              ],
            ),
            const SizedBox(height: AppSizes.space12),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.heroSummaryValue(
                context,
                smallValue
                    ? HeroSectionConfig.summaryValueSmallFontSize
                    : HeroSectionConfig.summaryValueFontSize,
              ),
            ),
            const SizedBox(height: AppSizes.space4),
            Text(sub, style: AppStyles.heroSummarySub(context, HeroSectionConfig.summarySubFontSize)),
          ],
        ),
      ),
    );

    final card = Material(
      color: AppStyles.heroSummaryBackground(context),
      shape: AppStyles.heroSummaryShape(context),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}
