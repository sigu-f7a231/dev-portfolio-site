import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← → キー
import 'package:url_launcher/url_launcher.dart';
import '../../models/projects_model.dart';
import '../../project_modal_format.dart';
import '../../../config/projects/projects_views_list_config.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';
import '../../../../widgets/settled_reveal.dart';
import 'project_workflow_steps.dart';
import 'project_detail_sections.dart';

/// 案件の詳細ダイアログを開く
/// - PC（幅 1024 以上）はダイアログ、タブレット・スマホは全画面（文字も一回り大きく）
/// - [projects] を渡すと、ダイアログの左右（全画面では下）の ‹ › で前後の案件に移れる
///   （キーボードの ← → でも移れる）。前・次がないときはそのボタンを押せない
/// - 閉じたときに最後に表示していた案件の [projects] 内の位置を返す（一覧のページを合わせるため）
Future<int> showProjectDetailModal(
  BuildContext context,
  Project project, {
  List<Project>? projects,
  bool? showWorkflow, // 省略時は workflow があれば出す
}) async {
  final list = projects ?? [project];
  final start = list.indexOf(project);
  var last = start < 0 ? 0 : start;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    useSafeArea: false, // 安全領域はダイアログ側で扱う（全画面のとき背景を端まで塗るため）
    builder: (_) => _ProjectDetailDialog(
      projects: start < 0 ? [project] : list,
      initialIndex: last,
      showWorkflow: showWorkflow,
      onIndexChanged: (i) => last = i,
    ),
  );
  return last;
}

class _ProjectDetailDialog extends StatefulWidget {
  final List<Project> projects;
  final int initialIndex;
  final bool? showWorkflow;
  final ValueChanged<int> onIndexChanged;

  const _ProjectDetailDialog({
    required this.projects,
    required this.initialIndex,
    required this.showWorkflow,
    required this.onIndexChanged,
  });

  @override
  State<_ProjectDetailDialog> createState() => _ProjectDetailDialogState();
}

class _ProjectDetailDialogState extends State<_ProjectDetailDialog> {
  late int _index = widget.initialIndex;

  bool get _hasPrev => _index > 0;
  bool get _hasNext => _index < widget.projects.length - 1;

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.projects.length) return; // 前・次がない
    setState(() => _index = next);
    widget.onIndexChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.projects[_index];
    final total = widget.projects.length;
    final canNavigate = total > 1;
    final mq = MediaQuery.of(context);
    // タブレット・スマホは全画面
    final fullscreen = mq.size.width < ProjectsListConfig.modalFullscreenBreakpoint;
    final sideNav = canNavigate && !fullscreen;

    Widget sideButton({required bool isPrev}) {
      final enabled = isPrev ? _hasPrev : _hasNext;
      return IconButton.filledTonal(
        iconSize: ProjectsListConfig.modalNavIconSize,
        tooltip: enabled
            ? (isPrev ? AppTexts.prevProject : AppTexts.nextProject)
            : (isPrev ? AppTexts.noPrevProject : AppTexts.noNextProject),
        icon: Icon(isPrev ? Icons.chevron_left : Icons.chevron_right),
        onPressed: enabled ? () => _go(isPrev ? -1 : 1) : null, // ないときは押せない（薄い表示）
      );
    }

    final card = _DetailCard(
      key: ValueKey(_index),
      project: project,
      fullscreen: fullscreen,
      showWorkflow: widget.showWorkflow ?? project.workflow.isNotEmpty,
      position: canNavigate ? AppTexts.projectPosition(_index + 1, total) : null,
      // 全画面では ‹ › を下に置く
      bottomNav: canNavigate && fullscreen
          ? _BottomNav(
              onPrev: _hasPrev ? () => _go(-1) : null,
              onNext: _hasNext ? () => _go(1) : null,
            )
          : null,
    );

    final Widget body = fullscreen
        // 全画面：画面いっぱいに広げ、文字を一回り大きくする（端末の文字サイズ設定は保ったまま掛ける）
        ? MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(
                mq.textScaler.scale(1) * ProjectsListConfig.fullscreenTextScale,
              ),
            ),
            child: card,
          )
        // PC：中央のダイアログ＋左右の ‹ ›
        : SafeArea(
            child: Padding(
              padding: ProjectsListConfig.modalPadding,
              child: Center(
                child: sideNav
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          sideButton(isPrev: true),
                          const SizedBox(width: ProjectsListConfig.modalNavGap),
                          Flexible(child: card),
                          const SizedBox(width: ProjectsListConfig.modalNavGap),
                          sideButton(isPrev: false),
                        ],
                      )
                    : card,
              ),
            ),
          );

    // ← → キーでも前後に移れる
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
      },
      child: Focus(autofocus: true, child: body),
    );
  }
}

/// 全画面（タブレット・スマホ）のときに下に出す［‹ 前へ］［次へ ›］
class _BottomNav extends StatelessWidget {
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _BottomNav({required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: onPrev, // 前がないときは押せない
          icon: const Icon(Icons.chevron_left),
          label: const Text(AppTexts.prevShort),
        ),
        // 次へは右側にアイコン
        TextButton.icon(
          onPressed: onNext, // 次がないときは押せない
          icon: const Icon(Icons.chevron_right),
          label: const Text(AppTexts.nextShort),
          style: TextButton.styleFrom(iconAlignment: IconAlignment.end),
        ),
      ],
    );
  }
}

/// ダイアログ本体（1 案件分）。案件が変わると key が変わり、描画が落ち着くまで Progress indicator を出す
/// [fullscreen] のときは画面いっぱい（角丸・影なし、安全領域の内側に中身を置く）
class _DetailCard extends StatelessWidget {
  final Project project;
  final bool fullscreen;
  final bool showWorkflow;

  /// 「3 / 12」（前後に移れないときは null）
  final String? position;
  final Widget? bottomNav;

  const _DetailCard({
    super.key,
    required this.project,
    required this.fullscreen,
    required this.showWorkflow,
    required this.position,
    required this.bottomNav,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final surfaceColor = theme.dialogTheme.backgroundColor ?? context.colors.dialogBackground;

    final content = Column(
          // 全画面は高さいっぱい、ダイアログは中身の高さ
          mainAxisSize: fullscreen ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== 固定ヘッダー：位置（3 / 12）＋プロジェクト名＋×（スクロールしても常に見える） =====
            Padding(
              padding: ProjectsListConfig.modalHeaderPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSizes.space8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (position != null)
                            Text(position!, style: AppStyles.cardMeta(context)),
                          Text(
                            project.title,
                            style: AppStyles.title(
                              context,
                              fontSize: ProjectsListConfig.modalTitleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.colors.modalClose,
                      size: ProjectsListConfig.closeButtonSize,
                    ),
                    tooltip: AppTexts.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ===== 本文：ここだけスクロールする（開いたら・案件を移ったら、落ち着くまで Progress indicator） =====
            Flexible(
              fit: fullscreen ? FlexFit.tight : FlexFit.loose,
              child: SettledReveal(
                child: SingleChildScrollView(
                  padding: ProjectsListConfig.modalBodyPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildDetailSections(project, showWorkflow: showWorkflow),
                      // Workflow：工程を横に並べたステップ表示（Work のみ）
                      if (showWorkflow && project.workflow.isNotEmpty)
                        ProjectWorkflowSteps(project: project),
                    ],
                  ),
                ),
              ),
            ),

            // ===== 固定フッター：公開ページ（リンクがあるときだけ）＋スマホ幅の ‹ › =====
            if (project.link.isNotEmpty || bottomNav != null) ...[
              const Divider(height: 1),
              Padding(
                padding: ProjectsListConfig.modalFooterPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (project.link.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () async {
                            final uri = Uri.tryParse(project.link);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          style: AppStyles.linkButton(context),
                          child: const Text(AppTexts.openPublicPage),
                        ),
                      ),
                    if (project.link.isNotEmpty && bottomNav != null)
                      const SizedBox(height: AppSizes.space8),
                    if (bottomNav != null) bottomNav!,
                  ],
                ),
              ),
            ],
          ],
        );

    // 全画面（タブレット・スマホ）：M3 の Full-screen dialog と同じく画面いっぱい・角丸なし
    if (fullscreen) {
      return Material(
        color: surfaceColor,
        child: SafeArea(child: content),
      );
    }

    // PC：M3 のダイアログと同じ面（色・角丸・影）
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ProjectsListConfig.modalMaxWidth,
        maxHeight: ProjectsListConfig.modalMaxHeight,
      ),
      child: Material(
        color: surfaceColor,
        elevation: theme.dialogTheme.elevation ?? 6,
        shape: theme.dialogTheme.shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusXxl)),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}

/// 本文の各項目（プロジェクト名と Workflow は別に表示するので除く）
/// - 説明・詳細：文章のまま／期間：開始 → 終了・長さ
/// - それ以外（使用技術など）：カンマ区切りの値を 1 つずつ枠に入れて並べる
/// - 中身が空、または「利用なし」だけの項目は出さない
List<Widget> _buildDetailSections(Project project, {required bool showWorkflow}) {
  const textFields = {
    AppTexts.fieldDescription,
    AppTexts.fieldDetails,
  };
  const skipFields = {AppTexts.fieldTitle, AppTexts.fieldWorkflow};

  final sections = <Widget>[];
  for (final field in ProjectModalFormat.fields(showWorkflow: showWorkflow)) {
    if (skipFields.contains(field.label)) continue;
    final raw = field.valueGetter(project).trim();

    if (field.label == AppTexts.fieldPeriod) {
      if (raw.isEmpty) continue;
      sections.add(ProjectDetailSection(label: field.label, child: ProjectDetailPeriod(project: project)));
      continue;
    }

    if (textFields.contains(field.label)) {
      if (raw.isEmpty) continue;
      sections.add(ProjectDetailSection(label: field.label, child: ProjectDetailText(text: raw)));
      continue;
    }

    final values = raw
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty && v != Project.notUsed)
        .toList();
    if (values.isEmpty) continue;
    sections.add(ProjectDetailSection(label: field.label, child: ProjectDetailChips(values: values)));
  }
  return sections;
}
