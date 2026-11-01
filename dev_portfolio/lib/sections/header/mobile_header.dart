import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:html' as html; // ブラウザのsessionStorage用
import 'package:yaml/yaml.dart'; // YAMLパース用
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import 'yaml_format_help.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../widgets/app_loading_indicator.dart';

class MobileHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final VoidCallback? onYamlStateChanged; // ★ 追加

  const MobileHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    this.onYamlStateChanged, // ★ 追加
  });

  /// Work用・Private用を厳密に区別して検証するバリデーション関数（DesktopHeaderと共通）
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
                FilledButton(
                  onPressed: loadedYamlString == null || isChecking
                      ? null
                      : () async {
                          setStateModal(() {
                            isChecking = true;
                            errorMessage = null;
                          });

                          final isValid = await _validateAgainstTemplate(loadedYamlString!, dataType);

                          if (isValid) {
                            html.window.sessionStorage[dataType] = loadedYamlString!;

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppTexts.uploadSaved(dataType))),
                              );
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
                          child: AppLoadingIndicator(size: AppSizes.buttonLoadingSize),
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

  void _showWorkUploadDialog(BuildContext context) {
    _showUploadDialog(
      context,
      title: AppTexts.workUploadTitle,
      description: AppTexts.workUploadDescription,
      dataType: 'work',
    );
  }

  void _showPrivateUploadDialog(BuildContext context) {
    _showUploadDialog(
      context,
      title: AppTexts.privateUploadTitle,
      description: AppTexts.privateUploadDescription,
      dataType: 'private',
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colors.headerForeground;

    return AppBar(
      title: const Text(AppTexts.appTitle),
      backgroundColor: context.colors.headerBackground,
      iconTheme: IconThemeData(color: iconColor),
      actions: [
        // ★ モバイル版でもアップロードできるようにアイコンを追加
        IconButton(
          icon: const Icon(Icons.work_outline),
          tooltip: AppTexts.workUploadTooltip,
          onPressed: () => _showWorkUploadDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.lock_outline),
          tooltip: AppTexts.privateUploadTooltip,
          onPressed: () => _showPrivateUploadDialog(context),
        ),
      ],
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
    );
  }
}