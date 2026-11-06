import 'package:flutter/material.dart';
import 'data/projects_work.dart';
import 'data/projects_private.dart';
import 'models/projects_model.dart';
import 'views/projects_tab_view.dart';
import 'projects_header.dart';
import 'projects_toolbar.dart';
import 'filters/ui/project_filter_panel.dart';
import 'filters/ui/project_active_filters.dart';
import 'filters/state/project_filter_state.dart';
import 'sort/project_sort.dart';
import '../config/projects/projects_section_config.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/app_filter_modal.dart';

/// Projects セクション
/// 状態（Work/Private・表示形式・フィルター・並び替え）はここで持ち、ツールバー・パネル・一覧に渡す
/// 並び替えは Work / Private を切り替えてもそのまま
class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  /// [0] = Work、[1] = Private
  late final Future<List<List<Project>>> _projectsFuture;

  bool _isWork = true;
  bool _showCollection = false;
  bool _filterOpen = false;
  ProjectFilterState _filterState = ProjectFilterState.initial();
  ProjectSort _sort = ProjectSort.initial;

  @override
  void initState() {
    super.initState();
    _projectsFuture = Future.wait([loadWorkProjects(), loadPrivateProjects()]);
  }

  /// タブを切り替えたら、候補が変わるのでフィルターはリセットする
  void _selectTab(bool isWork) {
    if (_isWork == isWork) return;
    setState(() {
      _isWork = isWork;
      _filterState = ProjectFilterState.initial();
      _filterOpen = false;
    });
  }

  /// フィルターをポップアップで開く（「反映」で一覧に反映、閉じる・キャンセルでは変えない）
  Future<void> _openFilter(List<Project> current) async {
    setState(() => _filterOpen = true);
    await showAppFilterModal<void>(
      context,
      builder: (ctx) => ProjectsFilter(
        projects: current,
        isWork: _isWork,
        initialState: _filterState,
        onApply: (state) {
          Navigator.of(ctx).pop();
          setState(() => _filterState = state);
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
    if (mounted) setState(() => _filterOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    // 高さは中身なり。スクロールはページ全体（HomePage）で 1 つにまとめる
    //（スマホで内側だけがスクロールしてページが動かなくなるのを防ぐ）
    return Container(
      width: double.infinity,
      color: context.colors.projectsBackground,
      padding: ProjectsSectionConfig.padding,
      child: FutureBuilder<List<List<Project>>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            final work = snapshot.data?[0] ?? const <Project>[];
            final private = snapshot.data?[1] ?? const <Project>[];
            final current = _isWork ? work : private;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProjectsHeader(),
                ProjectsSectionConfig.headerSpacing,

                // Work/Private ・ フィルター ・ List/Collection
                ProjectsToolbar(
                  isWork: _isWork,
                  workCount: snapshot.hasData ? work.length : null,
                  privateCount: snapshot.hasData ? private.length : null,
                  onTabChanged: _selectTab,
                  filterOpen: _filterOpen,
                  activeFilterCount: _filterState.activeCount,
                  onFilterPressed: () => _openFilter(current),
                  showCollection: _showCollection,
                  onViewChanged: (v) => setState(() => _showCollection = v),
                  sort: _sort,
                  onSortChanged: (s) => setState(() => _sort = s),
                ),

                // 適用中のフィルター
                if (_filterState.activeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.space12),
                    child: ProjectActiveFilters(
                      filterState: _filterState,
                      onChanged: (state) => setState(() => _filterState = state),
                      onClearAll: () => setState(() {
                        _filterState = ProjectFilterState.initial();
                      }),
                    ),
                  ),

                ProjectsSectionConfig.toolbarSpacing,

                // 一覧
                snapshot.hasData
                    ? ProjectsTabView(
                        projects: current,
                        filterState: _filterState,
                        showCollection: _showCollection,
                        sort: _sort,
                      )
                    : const SizedBox(
                        height: ProjectsSectionConfig.loadingHeight,
                        child: Center(child: AppLoadingIndicator()),
                      ),
              ],
            );
          },
      ),
    );
  }
}
