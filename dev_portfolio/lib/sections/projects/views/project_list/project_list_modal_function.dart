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
import '../../../../utils/platform_keys.dart';
import '../../../../utils/browser/browser.dart';
import '../../../../utils/tech_catalog.dart';

/// 案件の詳細ダイアログを開く
/// - PC（幅 1024 以上）はダイアログ、タブレット・スマホは全画面（文字も一回り大きく）
/// - [projects] を渡すと、ダイアログの左右（全画面では下）の ‹ › で前後の案件に移れる
///   （キーボードの ← → でも移れる）。前・次がないときはそのボタンを押せない
/// - 閉じたときに最後に表示していた案件の [projects] 内の位置を返す（一覧のページを合わせるため）
/// - 画面共有（Google Meet・Teams・Slack ハドルなど）で見やすいように、ヘッダーの
///   ［A−］［100%］［A＋］で文字の大きさを変えられ、PC では［大きく表示］で画面いっぱいに広げられる
///   （キーボードは − ＋ 0 F。⌘ / Ctrl ＋ 0 で大きく表示も含めて元に戻す、⌘ / Ctrl ＋ ＋ − でも拡大・縮小）。選んだ大きさは、ページを開いている間は次に開いたときも引き継ぐ
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

/// 詳細の表示の大きさ（次に開いたときも引き継ぐ。ページを読み込み直すと元に戻る）
class ProjectDetailView {
  ProjectDetailView._();

  /// 選んだ文字の倍率（null なら既定：ダイアログ 1.0、全画面 fullscreenTextScale）
  static double? zoom;

  /// PC で「大きく表示」（画面いっぱい）にしているか
  static bool large = false;

  /// テスト用：元に戻す
  static void reset() {
    zoom = null;
    large = false;
  }
}

class _ProjectDetailDialogState extends State<_ProjectDetailDialog> {
  late int _index = widget.initialIndex;

  /// 開いている間は、ブラウザの拡大・縮小（⌘ / Ctrl ＋ ＋ − 0）を止めてアプリ側だけ効かせる
  late final void Function() _unblockBrowserZoom;

  @override
  void initState() {
    super.initState();
    _unblockBrowserZoom = blockBrowserZoomKeys();
  }

  @override
  void dispose() {
    _unblockBrowserZoom();
    super.dispose();
  }

  /// 今の文字の倍率（[fullscreen] は今の表示が全画面か）
  double _zoomFor(bool fullscreen) =>
      ProjectDetailView.zoom ?? (fullscreen ? ProjectsListConfig.fullscreenTextScale : 1.0);

  /// 文字の大きさを 1 段階変える（[step] は +1 / -1）
  void _zoomBy(int step, bool fullscreen) {
    const levels = ProjectsListConfig.modalZoomLevels;
    final current = _zoomFor(fullscreen);
    const eps = 0.001;
    final next = step > 0
        ? levels.firstWhere((l) => l > current + eps, orElse: () => levels.last)
        : levels.lastWhere((l) => l < current - eps, orElse: () => levels.first);
    setState(() => ProjectDetailView.zoom = next);
  }

  void _resetZoom() => setState(() => ProjectDetailView.zoom = null);

  /// 元の大きさに戻す（文字の大きさ・大きく表示の両方）
  void _resetView() => setState(ProjectDetailView.reset);

  void _toggleLarge() => setState(() => ProjectDetailView.large = !ProjectDetailView.large);

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
    // タブレット・スマホは全画面。PC でも「大きく表示」なら全画面
    final small = mq.size.width < ProjectsListConfig.modalFullscreenBreakpoint;
    final fullscreen = small || ProjectDetailView.large;
    final sideNav = canNavigate && !fullscreen;
    final zoom = _zoomFor(fullscreen);
    const levels = ProjectsListConfig.modalZoomLevels;

    // ヘッダーの［A−］［100%］［A＋］［大きく表示］
    final viewControls = _ViewControls(
      percent: (zoom * 100).round(),
      onZoomOut: zoom > levels.first + 0.001 ? () => _zoomBy(-1, fullscreen) : null,
      onZoomIn: zoom < levels.last - 0.001 ? () => _zoomBy(1, fullscreen) : null,
      onReset: _resetView,
      // タブレット・スマホはいつも全画面なので出さない
      large: small ? null : ProjectDetailView.large,
      onToggleLarge: small ? null : _toggleLarge,
    );

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
      zoom: zoom,
      viewControls: viewControls,
      // 全画面では ‹ › を下に置く
      bottomNav: canNavigate && fullscreen
          ? _BottomNav(
              onPrev: _hasPrev ? () => _go(-1) : null,
              onNext: _hasNext ? () => _go(1) : null,
            )
          : null,
    );

    // 文字の倍率（端末の文字サイズ設定は保ったまま掛ける）。全画面の既定は一回り大きく
    final scaledCard = MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1) * zoom)),
      child: card,
    );

    final Widget body = fullscreen
        // 全画面：画面いっぱいに広げる
        ? scaledCard
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
                          Flexible(child: scaledCard),
                          const SizedBox(width: ProjectsListConfig.modalNavGap),
                          sideButton(isPrev: false),
                        ],
                      )
                    : scaledCard,
              ),
            ),
          );

    // ⌘（Mac）/ Ctrl（Windows など）との組み合わせ
    final apple = isApplePlatform;
    SingleActivator withMod(LogicalKeyboardKey key, {bool shift = false}) =>
        SingleActivator(key, meta: apple, control: !apple, shift: shift);

    // ← → キーでも前後に移れる。− ＋ 0 で文字の大きさ、F で大きく表示、⌘ / Ctrl ＋ 0 で元の大きさ
    // （⌘ / Ctrl ＋ 0 ＋ − はブラウザの拡大・縮小と同じキー。ダイアログを開いている間は
    //   blockBrowserZoomKeys でブラウザ側を止め、こちらだけ効かせる）
    return CallbackShortcuts(
      bindings: {
        withMod(LogicalKeyboardKey.digit0): _resetView,
        withMod(LogicalKeyboardKey.numpad0): _resetView,
        withMod(LogicalKeyboardKey.equal): () => _zoomBy(1, fullscreen),
        withMod(LogicalKeyboardKey.equal, shift: true): () => _zoomBy(1, fullscreen),
        withMod(LogicalKeyboardKey.add): () => _zoomBy(1, fullscreen),
        withMod(LogicalKeyboardKey.numpadAdd): () => _zoomBy(1, fullscreen),
        // 日本語（JIS）キーボードの「＋」は Shift ＋「;」
        withMod(LogicalKeyboardKey.semicolon): () => _zoomBy(1, fullscreen),
        withMod(LogicalKeyboardKey.semicolon, shift: true): () => _zoomBy(1, fullscreen),
        withMod(LogicalKeyboardKey.minus): () => _zoomBy(-1, fullscreen),
        withMod(LogicalKeyboardKey.numpadSubtract): () => _zoomBy(-1, fullscreen),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
        const CharacterActivator('+'): () => _zoomBy(1, fullscreen),
        const CharacterActivator('='): () => _zoomBy(1, fullscreen),
        const CharacterActivator('-'): () => _zoomBy(-1, fullscreen),
        const CharacterActivator('0'): _resetZoom,
        if (!small) const CharacterActivator('f'): _toggleLarge,
        if (!small) const CharacterActivator('F'): _toggleLarge,
      },
      child: Focus(autofocus: true, child: body),
    );
  }
}

/// ヘッダーの表示の大きさのボタン：［A−］［100%］（押すと元の大きさ。大きく表示も戻す）［A＋］［大きく表示 / 戻す］
class _ViewControls extends StatelessWidget {
  final int percent;
  final VoidCallback? onZoomOut; // これ以上小さくできないときは null（押せない）
  final VoidCallback? onZoomIn; // これ以上大きくできないときは null（押せない）
  final VoidCallback onReset;

  /// PC だけ：今「大きく表示」か（タブレット・スマホは null でボタンを出さない）
  final bool? large;
  final VoidCallback? onToggleLarge;

  const _ViewControls({
    required this.percent,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onReset,
    required this.large,
    required this.onToggleLarge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: AppTexts.zoomOut(shortcutModifierLabel),
          icon: const Icon(Icons.text_decrease),
          onPressed: onZoomOut,
        ),
        Tooltip(
          message: AppTexts.zoomReset(shortcutModifierLabel),
          child: TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
              minimumSize: Size.zero,
            ),
            onPressed: onReset,
            // 倍率の表示自体は大きくしない（ヘッダーの幅が変わらないように）
            child: Text(
              AppTexts.zoomPercent(percent),
              textScaler: TextScaler.noScaling,
              style: AppStyles.cardMeta(context),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: AppTexts.zoomIn(shortcutModifierLabel),
          icon: const Icon(Icons.text_increase),
          onPressed: onZoomIn,
        ),
        if (large != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: large! ? AppTexts.normalView(shortcutModifierLabel) : AppTexts.largeView,
            icon: Icon(large! ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: onToggleLarge,
          ),
      ],
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

  /// 文字の倍率（ダイアログの最大の幅・高さもこの倍率で広げる）
  final double zoom;

  /// ヘッダーの表示の大きさのボタン
  final Widget viewControls;

  const _DetailCard({
    super.key,
    required this.project,
    required this.fullscreen,
    required this.showWorkflow,
    required this.position,
    required this.bottomNav,
    required this.zoom,
    required this.viewControls,
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
                  viewControls,
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
      // 文字を大きくしたら、ダイアログも同じ倍率で広げる（画面より大きくはならない）
      constraints: BoxConstraints(
        maxWidth: ProjectsListConfig.modalMaxWidth * zoom,
        maxHeight: ProjectsListConfig.modalMaxHeight * zoom,
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

    // Skills・Tools は、Skills のグラフ・フィルターと同じグループごとの見出しに分ける（名前から推測。tech_catalog.dart）
    final groups = field.label == AppTexts.fieldSkills
        ? [for (final g in SkillGroup.values) (g.key, [for (final v in values) if (skillGroupOf(v) == g) v])]
        : field.label == AppTexts.fieldTools
            ? [for (final g in ToolGroup.values) (g.key, [for (final v in values) if (toolGroupOf(v) == g) v])]
            : null;
    if (groups != null) {
      for (final (key, items) in groups) {
        if (items.isEmpty) continue;
        sections.add(ProjectDetailSection(
          label: AppTexts.skillCategoryLabels[key] ?? field.label,
          child: ProjectDetailChips(values: items),
        ));
      }
      continue;
    }
    sections.add(ProjectDetailSection(label: field.label, child: ProjectDetailChips(values: values)));
  }
  return sections;
}
