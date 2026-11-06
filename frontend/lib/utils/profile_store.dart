// lib/utils/profile_store.dart
//
// 表示中のプロフィール（Home / About）を持つ（変わったら Home / About に知らせる）
// どこから読むか・どこへ保存するかは Repository（lib/data/portfolio_repository.dart）に任せる
import 'package:flutter/foundation.dart';
import '../data/local_portfolio_repository.dart';
import '../data/portfolio_repository.dart';
import '../models/profile.dart';

class ProfileStore extends ValueNotifier<Profile?> {
  ProfileStore._() : super(null);
  static final ProfileStore instance = ProfileStore._();

  /// tool/run.dart が YAML を指定して起動したか（LocalPortfolioRepository.fromArg と同じもの）
  /// テストでは、起動時に指定したときの読み込み（成功・失敗）を確かめるため書き換える
  @visibleForTesting
  static bool get fromArg => LocalPortfolioRepository.fromArg;
  @visibleForTesting
  static set fromArg(bool value) => LocalPortfolioRepository.fromArg = value;

  static const String assetPath = LocalPortfolioRepository.profileAssetPath;
  static const String workAssetPath = LocalPortfolioRepository.workAssetPath;
  static const String privateAssetPath = LocalPortfolioRepository.privateAssetPath;
  static const String sessionKey = LocalPortfolioRepository.profileSessionKey;

  /// 起動時に一緒に指定された Work / Private（なければ null）
  static Future<String?> startupProjects(String dataType) =>
      LocalPortfolioRepository.startupProjects(ProjectsKind.of(dataType));

  /// 起動時に指定した YAML が読めなかったときの理由（入力画面に出す）
  List<String> startupErrors = const [];

  Future<void> load() async {
    final result = await PortfolioRepository.instance.loadProfile();
    if (result.errors.isNotEmpty) startupErrors = result.errors;
    if (result.profile != null) value = result.profile;
  }

  /// 入力画面でアップロードした YAML を使う（保存は Repository。今は同じタブなら再読み込みしても残る）
  Future<void> setUploaded(String yamlText, Profile profile) async {
    startupErrors = const [];
    value = profile;
    await PortfolioRepository.instance.saveProfile(yamlText);
  }
}
