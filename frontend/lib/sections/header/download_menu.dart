// lib/sections/header/download_menu.dart
//
// ヘッダーの［ダウンロード］：スキルシート（Work / Private を含む）を Excel か PDF で保存する
// - Excel：テンプレート（assets/data/format_skill_sheet.xlsx）の書式のまま、今のプロフィール（ふりがな・生年月日などの
//   スキルシートだけの項目も）と Work / Private（役割・規模も）を書き込む
//   （lib/utils/skill_sheet_writer.dart）
// - PDF：書き込んだ Excel を、Excel の見た目のまま PDF にする（lib/utils/skill_sheet_pdf.dart）
// - どちらも「名前を付けて保存」（先に保存ダイアログを開き、保存先が決まってから作る。ダイアログが使えないブラウザは
//   通常のダウンロード）。作っている間は全画面のローディング。保存したら（やめた・失敗したときも）画面の下に知らせる
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../models/profile.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/asset_text.dart';
import '../../utils/file_saver.dart';
import '../../utils/private_yaml_loader.dart';
import '../../utils/profile_store.dart';
import '../../utils/project_append.dart';
import '../../utils/skill_sheet.dart';
import '../../utils/skill_sheet_pdf.dart';
import '../../utils/skill_sheet_writer.dart';
import '../../utils/tech_catalog.dart';
import '../../utils/work_yaml_loader.dart';
import '../../widgets/app_loading_indicator.dart';
import '../config/header_config.dart';
import '../projects/models/projects_model.dart';

/// ［ダウンロード］のボタン（押すと Excel / PDF を選ぶメニュー）
class HeaderDownloadButton extends StatelessWidget {
  final bool showLabel;

  const HeaderDownloadButton({super.key, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, _) {
        void toggle() => controller.isOpen ? controller.close() : controller.open();
        if (!showLabel) {
          return IconButton.filledTonal(
            icon: const Icon(Icons.download),
            tooltip: SkillSheetTexts.buttonTooltip,
            onPressed: toggle,
          );
        }
        return Tooltip(
          message: SkillSheetTexts.buttonTooltip,
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.download, size: HeaderConfig.navIconSize),
            label: const Text(SkillSheetTexts.button),
            onPressed: toggle,
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.table_view_outlined),
          onPressed: () => downloadSkillSheet(context, pdf: false),
          child: const Text(SkillSheetTexts.excel),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: () => downloadSkillSheet(context, pdf: true),
          child: const Text(SkillSheetTexts.pdf),
        ),
      ],
    );
  }
}

/// 今のプロフィールと Work / Private（それぞれ開始の古い順）
Future<SkillSheetData> currentSkillSheetData() async {
  final profile = ProfileStore.instance.value ?? Profile.empty;
  final texts =
      await Future.wait([WorkYamlLoader.loadYamlString(), PrivateYamlLoader.loadYamlString()]);
  List<Map<String, dynamic>> projects(String text) {
    // Skills・Tools に書かれたフロントエンドなどは本来の分類に移してから書く（画面の表示と同じ）
    final list = redistributeProjects(projectsOf(text));
    list.sort((a, b) => Project.fromMap(a).periodStart.compareTo(Project.fromMap(b).periodStart));
    return list;
  }

  return SkillSheetData(
    name: profile.name,
    experience: profile.name.isEmpty ? '' : experienceTextOf(profile),
    work: projects(texts[0]),
    private: projects(texts[1]),
    // ふりがな・生年月日などは、読み込んだスキルシート（Excel）に書かれていたものをそのまま
    sheet: profile.sheet,
  );
}

/// スキルシートの中身（Excel か PDF のバイト列）を作る
Future<Uint8List> buildSkillSheetBytes({required bool pdf, DateTime? today}) async {
  final template = await loadAssetBytes(skillSheetTemplateAsset);
  final xlsx = fillSkillSheet(template, await currentSkillSheetData(), today: today);
  if (!pdf) return xlsx;
  final font = await loadAssetBytes(skillSheetPdfFontAsset);
  return skillSheetPdf(xlsx, ByteData.sublistView(font));
}

/// スキルシートを「名前を付けて保存」し、画面の下に結果を知らせる
/// 先に保存ダイアログを開き（ボタンを押した直後でないとブラウザが開かせない）、保存先が決まってから作る
Future<void> downloadSkillSheet(BuildContext context, {required bool pdf}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final what = pdf ? SkillSheetTexts.pdfShort : SkillSheetTexts.excelShort;
  final now = DateTime.now();
  final fileName = SkillSheetTexts.fileName(now, pdf ? 'pdf' : 'xlsx');

  // 作っている間の全画面ローディング（閉じるまで待たない）
  DialogRoute<void>? progress;
  void closeProgress() {
    final route = progress;
    if (route != null && route.isActive) navigator.removeRoute(route);
    progress = null;
  }

  try {
    final result = await FileSaver.saveGeneratedBytesAs(
      fileName: fileName,
      description: pdf ? SkillSheetTexts.pdfDescription : SkillSheetTexts.excelDescription,
      mimeType: pdf ? SkillSheetTexts.pdfMimeType : skillSheetMimeType,
      extensions: pdf ? const ['.pdf'] : const ['.xlsx'],
      make: () async {
        final route = DialogRoute<void>(
          context: navigator.context,
          barrierDismissible: false,
          builder: (_) => const PopScope(canPop: false, child: _MakingScreen()),
        );
        progress = route;
        navigator.push(route);
        // ローディングを描いてから、重い処理を始める
        await Future<void>.delayed(AppSizes.downloadStartDelay);
        return buildSkillSheetBytes(pdf: pdf, today: now);
      },
    );
    closeProgress();
    messenger.showSnackBar(SnackBar(
      content: Text(switch (result) {
        FileSaveResult.saved => SkillSheetTexts.saved(what, fileName),
        FileSaveResult.downloaded => SkillSheetTexts.downloaded(what, fileName),
        FileSaveResult.cancelled => SkillSheetTexts.cancelled(what),
      }),
    ));
  } catch (e) {
    closeProgress();
    messenger.showSnackBar(SnackBar(content: Text(SkillSheetTexts.failed(what, e))));
  }
}

class _MakingScreen extends StatelessWidget {
  const _MakingScreen();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.scaffoldBackground,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingIndicator(),
            const SizedBox(height: AppSizes.space16),
            Text(SkillSheetTexts.making, style: AppStyles.secondary(context)),
          ],
        ),
      ),
    );
  }
}
