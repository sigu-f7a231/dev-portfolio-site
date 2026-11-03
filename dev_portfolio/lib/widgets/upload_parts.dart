// lib/widgets/upload_parts.dart
//
// アップロード画面（Work / Private / プロフィール）で共通に使う部品
// - UploadSteps        … 番号付きの手順
// - SelectedFileStatus … 選んだファイルの状態（未選択 / 読み込める / 読み込めない＋理由）
// - confirmUpload      … アップロード前の確認画面（OK のときだけ true）
// - runReloading       … アップロード後の全画面ローディング（起動時と同じ M3 の Circular progress indicator）
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import 'app_loading_indicator.dart';

/// 番号付きの手順
class UploadSteps extends StatelessWidget {
  final List<String> steps;

  const UploadSteps({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: AppSizes.profileStepRadius,
                  backgroundColor: colors.navIndicator,
                  child: Text(
                    '${i + 1}',
                    style: AppStyles.countBadgeText(context)
                        .copyWith(color: colors.navSelectedForeground),
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(child: Text(steps[i], style: AppStyles.helpBody(context))),
              ],
            ),
          ),
      ],
    );
  }
}

/// 選んだファイルの状態
class SelectedFileStatus extends StatelessWidget {
  final String? fileName;

  /// 読み込めない理由（空なら読み込める）
  final List<String> errors;

  const SelectedFileStatus({super.key, required this.fileName, this.errors = const []});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ok = fileName != null && errors.isEmpty;

    final (icon, color, label) = fileName == null
        ? (Icons.description_outlined, colors.textTertiary, AppTexts.noFileChosen)
        : ok
            ? (Icons.check_circle, colors.success, AppTexts.fileReady(fileName!))
            : (Icons.error, colors.error, AppTexts.fileRejected(fileName!));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space12),
      decoration: AppStyles.cardPeriod(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSizes.space20),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: Text(label,
                    style: AppStyles.helpBody(context).copyWith(color: color)),
              ),
            ],
          ),
          for (final e in errors)
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.space20 + AppSizes.space8, top: AppSizes.space4),
              child: Text('${AppTexts.bullet}$e', style: AppStyles.dialogError(context)),
            ),
        ],
      ),
    );
  }
}

/// 確認画面の「見出し：値」の 1 行
class ConfirmField extends StatelessWidget {
  final String label;
  final String value;

  const ConfirmField(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.filterGroupLabel(context)),
          const SizedBox(height: AppSizes.space2),
          Text(value.trim(), style: AppStyles.helpBody(context)),
        ],
      ),
    );
  }
}

/// アップロード前の確認画面。OK を押したときだけ true
Future<bool> confirmUpload(
  BuildContext context, {
  required String fileName,
  required String replaceTarget, // 例：'Work' / 'プロフィール'
  required Widget summary,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      return AlertDialog(
        backgroundColor: colors.dialogBackground,
        icon: Icon(Icons.fact_check_outlined, color: colors.primary),
        title: Text(AppTexts.confirmTitle,
            textAlign: TextAlign.center, style: AppStyles.dialogTitle(context)),
        content: SizedBox(
          width: AppSizes.helpDialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTexts.confirmFile(fileName), style: AppStyles.helpBody(context)),
              const SizedBox(height: AppSizes.space12),
              // 中身（長いときはここだけスクロール）
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: AppSizes.confirmListMaxHeight),
                child: Container(
                  width: double.infinity,
                  decoration: AppStyles.cardPeriod(context),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.space16),
                    child: summary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space12),
              Text(
                AppTexts.confirmReplace(replaceTarget),
                style: AppStyles.helpBody(context).copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppTexts.confirmBack),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppTexts.confirmOk),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// アップロード後の全画面ローディング（起動時の表示と同じ見た目）
/// [task]（保存・読み直し）が終わり、最低 AppSizes.reloadMinDuration たって、
/// 描画が落ち着いてから消す。読み込みが終わらなくても reloadMaxDuration で打ち切る。
Future<void> runReloading(NavigatorState navigator, Future<void> Function() task) async {
  final done = Future<void>(() async {
    final work = () async {
      try {
        await task();
      } catch (_) {
        // 失敗しても画面は戻す（各セクションが空やエラーの表示になる）
      }
      for (var i = 0; i < AppSizes.settleFrames; i++) {
        await WidgetsBinding.instance.endOfFrame;
      }
    }();
    await Future.wait([
      work.timeout(AppSizes.reloadMaxDuration, onTimeout: () {}),
      Future<void>.delayed(AppSizes.reloadMinDuration),
    ]);
  });

  final route = DialogRoute<void>(
    context: navigator.context,
    barrierDismissible: false,
    useSafeArea: false,
    builder: (_) => const PopScope(canPop: false, child: _ReloadingScreen()),
  );
  // 閉じるまで待たずに（push の Future は閉じたときに完了する）
  navigator.push(route);
  await done;
  if (route.isActive) navigator.removeRoute(route);
}

class _ReloadingScreen extends StatelessWidget {
  const _ReloadingScreen();

  @override
  Widget build(BuildContext context) {
    // 画面全体を背景色で覆い、描き直し中の画面を見せない
    return Material(
      color: context.colors.scaffoldBackground,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingIndicator(),
            const SizedBox(height: AppSizes.space16),
            Text(AppTexts.reloading, style: AppStyles.secondary(context)),
          ],
        ),
      ),
    );
  }
}
