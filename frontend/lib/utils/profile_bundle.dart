// lib/utils/profile_bundle.dart
//
// 最初の入力画面・起動時（tool/run.dart）に読むプロフィールのファイルを、まとめて確かめる
// - プロフィール（home / about）は必須
// - work / private が一緒に書かれていれば、それぞれ Work / Private として確かめる
//   （1 回のアップロードで Home / About と Skills / Projects をまとめて切り替えられる）
//
// Flutter に依存しない（dart run tool/run.dart からも使う）。
import 'package:yaml/yaml.dart';

import '../constants/app_texts.dart';
import '../models/profile.dart';
import 'data_format.dart';
import 'projects_yaml_validator.dart';

class ProfileBundle {
  final DataFormat format;

  /// プロフィール（YAML として読めるテキスト）と、その中身
  final String? profileText;
  final Profile? profile;

  /// 一緒に書かれていたときだけ入る（{"projects": [...]}。YAML として読める）
  final String? workText;
  final String? privateText;

  /// 読み込めない理由（空なら読み込める）
  final List<String> errors;

  const ProfileBundle({
    required this.format,
    required this.errors,
    this.profileText,
    this.profile,
    this.workText,
    this.privateText,
  });

  bool get isOk => errors.isEmpty && profile != null;

  int? get workCount => _count(workText);
  int? get privateCount => _count(privateText);

  static int? _count(String? text) {
    if (text == null) return null;
    final doc = loadYaml(text);
    return doc is YamlMap && doc['projects'] is YamlList ? (doc['projects'] as YamlList).length : 0;
  }
}

/// プロフィールのファイル（YAML / Markdown）を読み、プロフィールと Work / Private を確かめる
ProfileBundle readProfileBundle(String raw, {String? fileName}) {
  final data = normalizeProfileBundle(raw, fileName: fileName);
  final errors = [...data.profile.errors];

  Profile? profile;
  final text = data.profile.text;
  if (text != null) {
    final result = Profile.parse(text);
    profile = result.profile;
    errors.addAll(result.errors);
  }
  if (data.work != null && !isValidProjectsYaml(data.work!, 'work')) {
    errors.add(BundleTexts.workInvalid);
  }
  if (data.private != null && !isValidProjectsYaml(data.private!, 'private')) {
    errors.add(BundleTexts.privateInvalid);
  }

  return ProfileBundle(
    format: data.profile.format,
    errors: errors,
    profileText: text,
    profile: errors.isEmpty ? profile : null,
    workText: data.work,
    privateText: data.private,
  );
}
