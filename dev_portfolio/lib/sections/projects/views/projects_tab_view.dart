import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../pagination/projects_pagination_logic.dart';
import '../pagination/projects_pagination_ui.dart';
import '../views/project_list/project_list_ui.dart';
import '../views/projects_collection_view.dart';
import '../views/project_list/project_list_modal_function.dart';
import '../filters/state/project_filter_state.dart';
import '../filters/logic/project_filter_logic.dart';
import '../../config/projects/projects_views_list_config.dart';
import '../../config/projects/projects_views_collection_config.dart';
import '../../config/projects/projects_section_config.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_styles.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_texts.dart';
import '../../../widgets/settled_reveal.dart';

/// 一覧エリア（フィルター適用 → 並べ替え → ページ分割 → List / Collection）
/// Work / Private の切替は親（ProjectsSection）のツールバーで行う
class ProjectsTabView extends StatefulWidget {
  /// いま選んでいるタブ（Work / Private）のプロジェクト
  final List<Project> projects;
  final ProjectFilterState filterState;
  final bool showCollection;

  const ProjectsTabView({
    super.key,
    required this.projects,
    required this.filterState,
    required this.showCollection,
  });

  @override
  State<ProjectsTabView> createState() => _ProjectsTabViewState();
}

class _ProjectsTabViewState extends State<ProjectsTabView> {
  int currentPage = 1;

  @override
  void didUpdateWidget(covariant ProjectsTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // タブ・フィルター・表示形式が変わったら 1 ページ目に戻す
    if (oldWidget.projects != widget.projects ||
        oldWidget.filterState != widget.filterState ||
        oldWidget.showCollection != widget.showCollection) {
      currentPage = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects =
        ProjectFilterLogic.apply(widget.projects, widget.filterState)
          ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

    if (filteredProjects.isEmpty) {
      return SizedBox(
        height: ProjectsSectionConfig.loadingHeight,
        child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: ProjectsListConfig.emptyIconSize,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: AppSizes.space12),
            Text(AppTexts.noResults, style: AppStyles.cardTitle(context)),
            const SizedBox(height: AppSizes.space4),
            Text(AppTexts.noResultsHint, style: AppStyles.cardDescription(context)),
          ],
        ),
        ),
      );
    }

    void openDetail(Project p) => showProjectDetailModal(
          context,
          p,
          showWorkflow: p.workflow.isNotEmpty,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Collection：列数 × 行数（どちらも画面幅で決まる＝行がそろう）
        // List：従来どおり ProjectsPaginationConfig.itemsPerPage
        final perPage = widget.showCollection
            ? ProjectsCollectionConfig.itemsPerPage(constraints.maxWidth)
            : null;

        final totalPages = ProjectsPaginationLogic.getTotalPages(
          filteredProjects,
          perPage: perPage,
        );
        // 画面サイズが変わって件数が増え、ページ数が減ったときは最終ページに合わせる
        final page = currentPage > totalPages ? totalPages : currentPage;
        final paginatedProjects = ProjectsPaginationLogic.getPaginatedProjects(
          filteredProjects,
          page,
          perPage: perPage,
        );

        return Column(
          children: [
            // List / Collection を切り替えたときは、描画が落ち着くまで Progress indicator を出してから表示する
            SettledReveal(
                key: ValueKey(widget.showCollection),
                child: widget.showCollection
                    ? ProjectCollectionView(
                        projects: paginatedProjects,
                        onProjectTap: openDetail,
                      )
                    : ProjectListUI(
                        projects: paginatedProjects,
                        onProjectTap: openDetail,
                      ),
            ),
            SizedBox(
              height: AppSizes.paginationBarHeight,
              child: ProjectsPaginationUI(
                currentPage: page,
                totalPages: totalPages,
                onPageChanged: (p) {
                  setState(() => currentPage = p);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
