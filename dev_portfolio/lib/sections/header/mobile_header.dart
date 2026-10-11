import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:html' as html; // ブラウザのsessionStorage用
import 'package:yaml/yaml.dart'; // YAMLパース用
import '../config/header_config.dart';

class MobileHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;
  final ThemeMode themeMode;
  final Function(bool) onThemeChanged;
  final VoidCallback? onYamlStateChanged; // ★ 追加

  const MobileHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    required this.themeMode,
    required this.onThemeChanged,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final titleColor = isDarkMode ? Colors.white : Colors.black;

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
              title: Text(title, style: TextStyle(color: titleColor)),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                    const SizedBox(height: 16),
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
                                  errorMessage = 'ファイルの読み込みに失敗しました: $e';
                                });
                              }
                            },
                      icon: const Icon(Icons.attach_file),
                      label: Text(selectedFileName ?? 'YAMLファイルを選択 (.yaml, .yml)'),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '選択中: $selectedFileName',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade400),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChecking ? null : () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
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
                                SnackBar(content: Text('$dataType用YAMLをセッションに保存しました！')),
                              );
                              onYamlStateChanged?.call();
                            }
                          } else {
                            final templateName = dataType == 'work' ? 'format_work.yaml' : 'format_private.yaml';
                            setStateModal(() {
                              isChecking = false;
                              errorMessage = 'フォーマットが一致しません。\n'
                                  'このファイルは $dataType 用ではありません（$templateName の構造を満たしていません）。';
                            });
                          }
                        },
                  child: isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('アップロード'),
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
      title: 'Work用 YAMLのアップロード',
      description: 'Work用のプロジェクト情報を定義したYAMLファイルをアップロードしてください。',
      dataType: 'work',
    );
  }

  void _showPrivateUploadDialog(BuildContext context) {
    _showUploadDialog(
      context,
      title: 'Private用 YAMLのアップロード',
      description: 'Private用の非公開プロジェクト情報を定義したYAMLファイルをアップロードしてください。',
      dataType: 'private',
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = HeaderConfig.mobileTextColor(context);

    return AppBar(
      title: const Text('DevPortfolio'),
      backgroundColor: HeaderConfig.mobileBackgroundColor(context),
      iconTheme: IconThemeData(color: iconColor),
      actions: [
        // ★ モバイル版でもアップロードできるようにアイコンを追加
        IconButton(
          icon: const Icon(Icons.work_outline),
          tooltip: 'Work用YAMLアップロード',
          onPressed: () => _showWorkUploadDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.lock_outline),
          tooltip: 'Private用YAMLアップロード',
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