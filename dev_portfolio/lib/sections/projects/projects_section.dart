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
import '../config/projects/projects_section_config.dart';
import '../../theme/app_theme.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/app_loading_indicator.dart';

/// Projects セクション
/// 状態（Work/Private・表示形式・フィルター）はここで持ち、ツールバー・パネル・一覧に渡す
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: context.colors.projectsBackground,
      padding: ProjectsSectionConfig.padding,
      height: screenHeight,
      child: SingleChildScrollView(
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
                  onFilterPressed: () => setState(() => _filterOpen = !_filterOpen),
                  showCollection: _showCollection,
                  onViewChanged: (v) => setState(() => _showCollection = v),
                ),

                // フィルターパネル（開閉はボタン操作への応答としてだけ動かす）
                AnimatedSize(
                  duration: AppSizes.filterPanelDuration,
                  alignment: Alignment.topCenter,
                  child: _filterOpen
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSizes.space12),
                          child: ProjectsFilter(
                            key: ValueKey(_isWork),
                            projects: current,
                            isWork: _isWork,
                            initialFilters: _filterState.selectedFilters,
                            onApply: (filters) => setState(() {
                              _filterState = ProjectFilterState(selectedFilters: filters);
                              _filterOpen = false;
                            }),
                            onClose: () => setState(() => _filterOpen = false),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),

                // 適用中のフィルター
                if (_filterState.activeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.space12),
                    child: ProjectActiveFilters(
                      filterState: _filterState,
                      onRemove: (key, value) => setState(() {
                        _filterState = _filterState.without(key, value);
                      }),
                      onClearAll: () => setState(() {
                        _filterState = ProjectFilterState.initial();
                      }),
                    ),
                  ),

                ProjectsSectionConfig.toolbarSpacing,

                // 一覧
                SizedBox(
                  height: screenHeight * AppSizes.projectsListHeightRatio,
                  child: snapshot.hasData
                      ? ProjectsTabView(
                          projects: current,
                          filterState: _filterState,
                          showCollection: _showCollection,
                        )
                      : const Center(child: AppLoadingIndicator()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
