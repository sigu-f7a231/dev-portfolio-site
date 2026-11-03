// lib/sections/projects/views/project_list/project_list_ui.dart
import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../../../config/projects/projects_views_list_config.dart';
import '../project_card_parts.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

/// List 表示：年表（タイムライン）
/// - 1 枚の面に行を並べ、区切り線で分ける（カードを並べる Collection と見た目を分ける）
/// - 左に開始の「年・月」と縦線＋点（進行中は色付きの点）
/// - 説明文は出さず、タイトル・期間・タグだけで流し読みできるようにする
class ProjectListUI extends StatelessWidget {
  final List<Project> projects;
  final void Function(Project) onProjectTap;

  const ProjectListUI({
    super.key,
    required this.projects,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    // スクロールはページ全体で行う（自分ではスクロールしない）
    return Material(
      color: context.colors.cardBackground,
      shape: AppStyles.listSurfaceShape(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < projects.length; i++) ...[
            // 区切り線は年表の線より右から引く（線が途切れて見えないように）
            if (i > 0) const Divider(height: 1, indent: ProjectsListConfig.dividerIndent),
            _ProjectTimelineRow(
              project: projects[i],
              isFirst: i == 0,
              isLast: i == projects.length - 1,
              onTap: () => onProjectTap(projects[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectTimelineRow extends StatelessWidget {
  final Project project;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _ProjectTimelineRow({
    required this.project,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = project;
    final valid = p.hasValidPeriod;

    // 年表の線と点の横位置（年・月の列の右、線の列の中央）
    const railLeft = ProjectsListConfig.dateColumnWidth +
        ProjectsListConfig.railWidth / 2;
    final rowLeft = ProjectsListConfig.rowPadding.left;
    final dotTop = ProjectsListConfig.rowPadding.top + ProjectsListConfig.dotTop;

    return InkWell(
      onTap: onTap,
      // IntrinsicHeight は使わず、行の内容の高さに合わせて Stack で線を重ねる
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 開始の年・月
              Padding(
                padding: EdgeInsets.only(left: rowLeft, top: ProjectsListConfig.rowPadding.top),
                child: SizedBox(
                  width: ProjectsListConfig.dateColumnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        valid ? AppTexts.listYear(p.periodStart) : AppTexts.listNoDate,
                        style: AppStyles.listYear(context),
                      ),
                      if (valid) ...[
                        Text(AppTexts.listMonth(p.periodStart),
                            style: AppStyles.listMonth(context)),
                        Text(AppTexts.listStartLabel,
                            style: AppStyles.cardPeriodDuration(context)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: ProjectsListConfig.railWidth),

              // タイトル・期間・タグ
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: ProjectsListConfig.rowPadding.top,
                    bottom: ProjectsListConfig.rowPadding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.listTitle(context),
                            ),
                          ),
                          if (p.isOngoing) ...[
                            const SizedBox(width: AppSizes.space8),
                            const OngoingTag(),
                          ],
                        ],
                      ),
                      ProjectsListConfig.mediumSpacing,
                      // 期間：［📅 2023年4月 → 2023年9月］［🕒 6か月］
                      ProjectPeriod(project: p, emphasizeDuration: true),
                      if (p.skillsList.isNotEmpty) ...[
                        ProjectsListConfig.mediumSpacing,
                        ProjectSkillTags(project: p, maxTags: ProjectsListConfig.rowMaxTags),
                      ],
                    ],
                  ),
                ),
              ),

              // 詳細へ
              Padding(
                padding: EdgeInsets.only(
                  left: ProjectsListConfig.rowPadding.right,
                  right: ProjectsListConfig.rowPadding.right,
                  top: ProjectsListConfig.rowPadding.top,
                ),
                child: Icon(
                  Icons.chevron_right,
                  size: ProjectsListConfig.chevronSize,
                  color: context.colors.textTertiary,
                  semanticLabel: AppTexts.viewDetails,
                ),
              ),
            ],
          ),

          // 縦線（1 件だけのときは引かない）
          if (!(isFirst && isLast))
            Positioned(
              left: rowLeft + railLeft - ProjectsListConfig.railLineWidth / 2,
              top: isFirst ? dotTop : 0,
              bottom: 0,
              child: isLast
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: ProjectsListConfig.railLineWidth,
                        height: dotTop,
                        child: ColoredBox(color: AppStyles.listRail(context)),
                      ),
                    )
                  : SizedBox(
                      width: ProjectsListConfig.railLineWidth,
                      child: ColoredBox(color: AppStyles.listRail(context)),
                    ),
            ),

          // 点（進行中は色付き）
          Positioned(
            left: rowLeft + railLeft - ProjectsListConfig.dotSize / 2,
            top: dotTop,
            child: Container(
              width: ProjectsListConfig.dotSize,
              height: ProjectsListConfig.dotSize,
              decoration: BoxDecoration(
                color: AppStyles.listDot(context, ongoing: p.isOngoing),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.cardBackground,
                  width: ProjectsListConfig.railLineWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
