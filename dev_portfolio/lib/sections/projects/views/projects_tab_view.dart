import 'package:flutter/material.dart';
import '../models/projects_model.dart';
import '../pagination/projects_pagination_logic.dart';
import '../pagination/projects_pagination_ui.dart';
import '../views/project_list/project_list_ui.dart';
import '../views/projects_collection_view.dart';
import '../views/project_list/project_list_modal_function.dart';
import '../filters/state/project_filter_state.dart';
import '../filters/logic/project_filter_logic.dart';

class ProjectsTabView extends StatefulWidget {
  final Future<List<Project>> workFuture;
  final Future<List<Project>> privateFuture;
  final ValueNotifier<bool> showCollectionNotifier;
  final bool isDark;
  final ProjectFilterState? filterState;

  const ProjectsTabView({
    super.key,
    required this.workFuture,
    required this.privateFuture,
    required this.showCollectionNotifier,
    required this.isDark,
    this.filterState,
  });

  @override
  State<ProjectsTabView> createState() => _ProjectsTabViewState();
}

class _ProjectsTabViewState extends State<ProjectsTabView> {
  bool _isWork = true;
  int currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final future = _isWork ? widget.workFuture : widget.privateFuture;

    final bool hasFilter = widget.filterState != null;

    return Column(
      children: [
        /// =========================
        /// WORK / PRIVATE（フィルター時だけ少し下げる）
        /// =========================
        AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.only(top: hasFilter ? 8 : 0),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text("Work")),
                    ButtonSegment(value: false, label: Text("Private")),
                  ],
                  selected: {_isWork},
                  onSelectionChanged: (v) {
                    setState(() {
                      _isWork = v.first;
                      currentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        /// =========================
        /// CONTENT
        /// =========================
        Expanded(
          child: FutureBuilder<List<Project>>(
            future: future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredProjects =
                  widget.filterState != null
                      ? ProjectFilterLogic.apply(
                          snapshot.data!, widget.filterState!)
                      : snapshot.data!;

              if (filteredProjects.isEmpty) {
                return const Center(child: Text('ヒットしませんでした'));
              }

              filteredProjects.sort(
                (a, b) => a.periodStart.compareTo(b.periodStart),
              );

              final totalPages =
                  ProjectsPaginationLogic.getTotalPages(filteredProjects);

              final paginatedProjects =
                  ProjectsPaginationLogic.getPaginatedProjects(
                filteredProjects,
                currentPage,
              );

              return ValueListenableBuilder<bool>(
                valueListenable: widget.showCollectionNotifier,
                builder: (_, showCollection, __) {
                  return Column(
                    children: [
                      Expanded(
                        child: showCollection
                            ? ProjectCollectionView(
                                projects: paginatedProjects,
                                isDark: widget.isDark,
                                onProjectTap: (p) =>
                                    showProjectDetailModal(
                                  context,
                                  p,
                                  isDark: widget.isDark,
                                  showWorkflow: true,
                                ),
                              )
                            : ProjectListUI(
                                projects: paginatedProjects,
                                isDark: widget.isDark,
                                onProjectTap: (p) =>
                                    showProjectDetailModal(
                                  context,
                                  p,
                                  isDark: widget.isDark,
                                  showWorkflow: true,
                                ),
                              ),
                      ),

                      SizedBox(
                        height: 60,
                        child: ProjectsPaginationUI(
                          currentPage: currentPage,
                          totalPages: totalPages,
                          onPageChanged: (page) {
                            setState(() => currentPage = page);
                          },
                          isDark: widget.isDark,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}