// lib/utils/profile_store.dart
//
// 表示中のプロフィール（Home / About）を持つ
// 読み込む順番：
//   1. `dart run tool/run.dart xxx.yaml` で起動した場合 → assets/profile/profile.yaml
//   2. この画面でアップロード済み（同じタブ内）        → sessionStorage['profile']
//   3. どちらもない                                  → null（入力画面を出す）
import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import 'browser/browser.dart'; // sessionStorage（Web は package:web、テストはメモリ）
import 'asset_text.dart';

class ProfileStore extends ValueNotifier<Profile?> {
  ProfileStore._() : super(null);
  static final ProfileStore instance = ProfileStore._();

  /// tool/run.dart が YAML を指定して起動したときだけ true
  static const bool fromArg = bool.fromEnvironment('PROFILE_FROM_ARG');
  static const String assetPath = 'assets/profile/profile.yaml';

  /// 起動時のプロフィールに work / private も書かれていたとき、tool/run.dart がここに書き出す
  static const String workAssetPath = 'assets/profile/work.yaml';
  static const String privateAssetPath = 'assets/profile/private.yaml';

  /// 起動時に一緒に指定された Work / Private（なければ null）。ローダーが使う
  static Future<String?> startupProjects(String dataType) async {
    if (!fromArg) return null;
    try {
      return await loadAssetText(
        dataType == 'work' ? workAssetPath : privateAssetPath,
      );
    } catch (_) {
      return null; // 一緒に指定されていない
    }
  }
  static const String sessionKey = 'profile';

  /// 起動時に指定した YAML が読めなかったときの理由（入力画面に出す）
  List<String> startupErrors = const [];

  Future<void> load() async {
    if (fromArg) {
      try {
        final result = Profile.parse(await loadAssetText(assetPath));
        if (result.isOk) {
          value = result.profile;
          return;
        }
        startupErrors = result.errors;
      } catch (e) {
        startupErrors = ['$e'];
      }
    }

    final saved = SessionStore.read(sessionKey);
    if (saved != null) {
      final result = Profile.parse(saved);
      if (result.isOk) value = result.profile;
    }
  }

  /// 入力画面でアップロードした YAML を使う（再読み込みしても同じタブなら残る）
  void setUploaded(String yamlText, Profile profile) {
    SessionStore.write(sessionKey, yamlText);
    startupErrors = const [];
    value = profile;
  }
}
