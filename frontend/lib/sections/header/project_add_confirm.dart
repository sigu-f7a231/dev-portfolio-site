// lib/sections/header/project_add_confirm.dart
//
// Work / Private にプロジェクトを「追加」するときの確認画面と保存（画面上の入力・アップロード画面の追加で共通）
// - 確認画面：追加する先・今の件数・追加するプロジェクトの一覧・同じ名前があるときの注意
//   今サンプルを表示しているときは「サンプルを外す」を選べる（はじめは外す）
// - OK のときだけ、呼び出し元の画面を閉じ、全画面ローディングを出してセッションに保存 → Skills / Projects を作り直す
import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_theme.dart';
import '../../data/portfolio_repository.dart';
import '../../utils/project_append.dart';
import '../../widgets/upload_parts.dart';

/// 今の一覧を読む（セッション → 起動時の指定 → サンプル）
Future<String> _loadCurrent(String dataType) =>
    PortfolioRepository.instance.loadProjectsText(ProjectsKind.of(dataType));

/// 今表示しているのがサンプル（アセット）か
Future<bool> _isSample(String dataType) =>
    PortfolioRepository.instance.isSampleProjects(ProjectsKind.of(dataType));

/// 確認画面を出し、OK なら [context] の画面を閉じて保存する。保存したら true
Future<bool> confirmAndAppendProjects(
  BuildContext context, {
  required String dataType,
  required List<Map<String, dynamic>> adding,
  VoidCallback? onSaved,
}) async {
  final current = await _loadCurrent(dataType);
  final sample = await _isSample(dataType);
  if (!context.mounted) return false;

  final dropSample = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmAppendDialog(
      dataType: dataType,
      current: current,
      adding: adding,
      isSample: sample,
    ),
  );
  if (dropSample == null || !context.mounted) return false; // 戻る

  final merged = appendProjects(current, adding, dataType: dataType, keepCurrent: !dropSample);
  final messenger = ScaffoldMessenger.of(context);
  if (merged == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(AppTexts.formatMismatch(dataType, 'format_$dataType.yaml'))),
    );
    return false;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  navigator.pop(); // 呼び出し元の画面を閉じる
  await runReloading(navigator, () async {
    await PortfolioRepository.instance.saveProjectsText(ProjectsKind.of(dataType), merged);
    onSaved?.call();
    await _loadCurrent(dataType);
  });
  messenger.showSnackBar(SnackBar(
    content: Text(DataTexts.added(dataType == 'work' ? AppTexts.work : AppTexts.private, adding.length)),
  ));
  return true;
}

/// 確認画面。OK なら「サンプルを外すか」を返す（戻るは null）
class _ConfirmAppendDialog extends StatefulWidget {
  final String dataType;
  final String current;
  final List<Map<String, dynamic>> adding;
  final bool isSample;

  const _ConfirmAppendDialog({
    required this.dataType,
    required this.current,
    required this.adding,
    required this.isSample,
  });

  @override
  State<_ConfirmAppendDialog> createState() => _ConfirmAppendDialogState();
}

class _ConfirmAppendDialogState extends State<_ConfirmAppendDialog> {
  // サンプルを表示しているときは、はじめから外す
  late bool _dropSample = widget.isSample;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = widget.dataType == 'work' ? AppTexts.work : AppTexts.private;
    final currentCount = _dropSample ? 0 : projectsOf(widget.current).length;
    final duplicates = _dropSample ? const <String>[] : duplicateTitles(widget.current, widget.adding);

    String period(Object? p) {
      if (p is List) return p.join(' 〜 ');
      return p?.toString() ?? '';
    }

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      icon: Icon(Icons.playlist_add_check, color: colors.primary),
      title: Text(DataTexts.confirmTitle,
          textAlign: TextAlign.center, style: AppStyles.dialogTitle(context)),
      content: SizedBox(
        width: AppSizes.helpDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DataTexts.confirmLead(label, currentCount, widget.adding.length),
                  style: AppStyles.helpBody(context)),
              if (widget.isSample)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _dropSample,
                  onChanged: (v) => setState(() => _dropSample = v ?? false),
                  title: Text(DataTexts.dropSample, style: AppStyles.helpBody(context)),
                ),
              if (duplicates.isNotEmpty) ...[
                const SizedBox(height: AppSizes.space8),
                Text(DataTexts.duplicates(duplicates.join('・')),
                    style: AppStyles.dialogError(context)),
              ],
              const SizedBox(height: AppSizes.space12),
              // 追加するプロジェクト（長いときはここだけスクロール）
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: AppSizes.confirmListMaxHeight),
                child: Container(
                  width: double.infinity,
                  decoration: AppStyles.cardPeriod(context),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < widget.adding.length; i++) ...[
                          if (i > 0) const Divider(height: AppSizes.space16),
                          Text('${i + 1}. ${widget.adding[i]['title']}',
                              style: AppStyles.cardTitle(context)),
                          if (period(widget.adding[i]['period']).isNotEmpty)
                            Text(period(widget.adding[i]['period']),
                                style: AppStyles.cardMeta(context)),
                          if ('${widget.adding[i]['description'] ?? ''}'.trim().isNotEmpty)
                            Text(
                              '${widget.adding[i]['description']}'.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.cardDescription(context),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppTexts.confirmBack),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_dropSample),
          child: const Text(DataTexts.confirmOk),
        ),
      ],
    );
  }
}
