import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:html' as html; // ★ ブラウザのsessionStorageを使うため
import 'package:yaml/yaml.dart'; // YAMLパース用
import '../config/header_config.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import 'yaml_format_help.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';

class DesktopHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;

  // 外部へのコールバックが不要な場合は削除可能ですが、
  // 保存後に画面の再描画などをトリガーしたい場合はオプショナルに残しておけます
  final VoidCallback? onYamlStateChanged;

  const DesktopHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    this.onYamlStateChanged,
  });

  /// Work用・Private用を厳密に区別して検証するバリデーション関数
  Future<bool> _validateAgainstTemplate(String uploadedYamlString, String dataType) async {
    try {
      final uploadedDecoded = loadYaml(uploadedYamlString);

      if (uploadedDecoded is! YamlMap || !uploadedDecoded.containsKey('projects')) {
        return false;
      }

      final uploadedProjects = uploadedDecoded['projects'];

      if (uploadedProjects is! YamlList || uploadedProjects.isEmpty) {
        return false;
      }

      for (var uploadedItem in uploadedProjects) {
        if (uploadedItem is! YamlMap) {
          return false;
        }

        if (!uploadedItem.containsKey('title')) {
          return false;
        }

        if (dataType == 'work') {
          if (!uploadedItem.containsKey('workflow')) {
            return false; 
          }
        } else if (dataType == 'private') {
          if (uploadedItem.containsKey('workflow')) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // 共通のダイアログ
  void _showUploadDialog(
    BuildContext context, {
    required String title,
    required String description,
    required String dataType,
  }) {
    final dialogBgColor = context.colors.dialogBackground;

    String? selectedFileName;
    String? loadedYamlString;
    String? errorMessage;
    bool isChecking = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: dialogBgColor,
              title: Text(title, style: AppStyles.dialogTitle(context)),
              content: SizedBox(
                width: AppSizes.uploadDialogWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: AppStyles.dialogBody(context),
                    ),
                    const SizedBox(height: AppSizes.space8),
                    // フォーマットのダウンロード + ⓘ（書き方の説明）
                    YamlFormatTools(dataType: dataType),
                    const SizedBox(height: AppSizes.space8),
                    OutlinedButton.icon(
                      onPressed: isChecking
                          ? null
                          : () async {
                              try {
                                FilePickerResult? result = await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['yaml', 'yml'],
                                );

                                if (result != null && result.files.single.bytes != null) {
                                  final file = result.files.single;
                                  final bytes = file.bytes!;
                                  final yamlStr = utf8.decode(bytes);

                                  setStateModal(() {
                                    selectedFileName = file.name;
                                    loadedYamlString = yamlStr;
                                    errorMessage = null;
                                  });
                                }
                              } catch (e) {
                                setStateModal(() {
                                  errorMessage = AppTexts.fileReadFailed(e);
                                });
                              }
                            },
                      icon: const Icon(Icons.attach_file),
                      label: Text(selectedFileName ?? AppTexts.selectYamlFile),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: AppSizes.space8),
                      Text(
                        AppTexts.selectedFile(selectedFileName!),
                        style: AppStyles.dialogSuccess(context),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppSizes.space8),
                      Text(
                        errorMessage!,
                        style: AppStyles.dialogError(context),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChecking ? null : () => Navigator.of(context).pop(),
                  child: const Text(AppTexts.cancel),
                ),
                ElevatedButton(
                  onPressed: loadedYamlString == null || isChecking
                      ? null
                      : () async {
                          setStateModal(() {
                            isChecking = true;
                            errorMessage = null;
                          });

                          // バリデーション実行
                          final isValid = await _validateAgainstTemplate(loadedYamlString!, dataType);

                          if (isValid) {
                            // ★ ここでセッションストレージに直接保存する！
                            // dataType ('work' または 'private') をキーにして文字列を保持
                            html.window.sessionStorage[dataType] = loadedYamlString!;

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppTexts.uploadSaved(dataType))),
                              );
                              
                              // 必要に応じて親画面に状態変化を通知（画面の再描画用など）
                              onYamlStateChanged?.call();
                            }
                          } else {
                            final templateName = dataType == 'work' ? 'format_work.yaml' : 'format_private.yaml';
                            setStateModal(() {
                              isChecking = false;
                              errorMessage = AppTexts.formatMismatch(dataType, templateName);
                            });
                          }
                        },
                  child: isChecking
                      ? const SizedBox(
                          width: AppSizes.buttonLoadingSize,
                          height: AppSizes.buttonLoadingSize,
                          child: CircularProgressIndicator(
                              strokeWidth: AppSizes.buttonLoadingStrokeWidth),
                        )
                      : const Text(AppTexts.upload),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 1. Work用ボタン
  void _showWorkUploadDialog(BuildContext context) {
    _showUploadDialog(
      context,
      title: AppTexts.workUploadTitle,
      description: AppTexts.workUploadDescription + AppTexts.workUploadNote,
      dataType: 'work',
    );
  }

  // 2. Private用ボタン
  void _showPrivateUploadDialog(BuildContext context) {
    _showUploadDialog(
      context,
      title: AppTexts.privateUploadTitle,
      description: AppTexts.privateUploadDescription + AppTexts.privateUploadNote,
      dataType: 'private',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bgColor = colors.headerBackground;
    final txtColor = colors.headerForeground;

    return Container(
      padding: HeaderConfig.desktopPadding,
      color: bgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: onHomePressed,
                child: Text(AppTexts.navHome, style: TextStyle(color: txtColor)),
              ),
              TextButton(
                onPressed: onAboutPressed,
                child: Text(AppTexts.navAbout, style: TextStyle(color: txtColor)),
              ),
              TextButton(
                onPressed: onSkillsPressed,
                child: Text(AppTexts.navSkills, style: TextStyle(color: txtColor)),
              ),
              TextButton(
                onPressed: onProjectsPressed,
                child: Text(AppTexts.navProjects, style: TextStyle(color: txtColor)),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.work_outline, color: colors.headerForegroundMuted),
                tooltip: AppTexts.workUploadTooltip,
                onPressed: () => _showWorkUploadDialog(context),
              ),
              IconButton(
                icon: Icon(Icons.lock_outline, color: colors.headerForegroundMuted),
                tooltip: AppTexts.privateUploadTooltip,
                onPressed: () => _showPrivateUploadDialog(context),
              ),
              const SizedBox(width: AppSizes.space24),
              Text(AppTexts.darkMode, style: TextStyle(color: colors.headerForegroundMuted)),
              const SizedBox(width: AppSizes.space8),
              Switch(
                value: context.isDark,
                onChanged: ThemeController.instance.toggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}