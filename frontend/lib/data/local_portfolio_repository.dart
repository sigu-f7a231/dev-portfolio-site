// lib/data/local_portfolio_repository.dart
//
// 今の Repository の実装：データはこのタブの中だけ（サーバーには送らない）
//   プロフィール    … 1. 起動時に指定（dart run tool/run.dart xxx.yaml）→ assets/profile/profile.yaml
//                     2. この画面で読み込み済み（同じタブ内）        → sessionStorage['profile']
//                     3. どちらもない                               → null（入力画面を出す）
//   Work / Private … 1. sessionStorage['work' / 'private']（空文字は無視）
//                     2. 起動時にプロフィールと一緒に指定したもの     → assets/profile/work.yaml / private.yaml
//                     3. サンプル                                   → assets/data/format_work.yaml / format_private.yaml
// 置き場所が YAML の文字なので、文字の読み書きは元の文字をそのまま使う（コメント・書き方を保つ）。
// 構造のデータ（DataRecord）での読み書きは、その文字との変換で行う。
import '../models/profile.dart';
import '../utils/asset_text.dart'; // assets の読み込み（テストではファイルを直接読む）
import '../utils/browser/browser.dart'; // sessionStorage（Web は package:web、テストはメモリ）
import 'portfolio_repository.dart';
import 'records.dart';

class LocalPortfolioRepository extends PortfolioRepository {
  /// tool/run.dart が YAML を指定して起動したときだけ true（--dart-define=PROFILE_FROM_ARG=true）
  /// テストでは、起動時に指定したときの読み込み（成功・失敗）を確かめるため書き換える（ProfileStore.fromArg から）
  static bool fromArg = const bool.fromEnvironment('PROFILE_FROM_ARG');

  /// 起動時に指定したプロフィール（tool/run.dart が書き出す。Git 管理外）
  static const String profileAssetPath = 'assets/profile/profile.yaml';

  /// 起動時のプロフィールに work / private も書かれていたとき、tool/run.dart がここに書き出す
  static const String workAssetPath = 'assets/profile/work.yaml';
  static const String privateAssetPath = 'assets/profile/private.yaml';

  /// プロフィールを置く sessionStorage のキー（Work / Private は ProjectsKind の名前）
  static const String profileSessionKey = 'profile';

  /// 起動時に一緒に指定された Work / Private（なければ null）
  static Future<String?> startupProjects(ProjectsKind kind) async {
    if (!fromArg) return null;
    try {
      return await loadAssetText(kind == ProjectsKind.work ? workAssetPath : privateAssetPath);
    } catch (_) {
      return null; // 一緒に指定されていない
    }
  }

  /// 自分の Work / Private の文字（保存したもの → 起動時の指定）。なければ null
  Future<String?> _projectsText(ProjectsKind kind) async {
    final session = SessionStore.read(kind.name);
    if (session != null && session.isNotEmpty) return session;
    final startup = await startupProjects(kind);
    if (startup != null && startup.isNotEmpty) return startup;
    return null;
  }

  // ---------- 構造のデータ ----------

  @override
  Future<DataRecord?> loadProfileRecord() async {
    final profile = (await loadProfile()).profile;
    if (profile == null) return null;
    // 読めたものと同じ文字（起動時の指定、なければ保存したもの）を変換する
    if (fromArg) {
      try {
        final text = await loadAssetText(profileAssetPath);
        if (Profile.parse(text).isOk) return recordOfYaml(text);
      } catch (_) {
        // 起動時の指定が読めなければ、保存したもの
      }
    }
    return recordOfYaml(SessionStore.read(profileSessionKey)!);
  }

  @override
  Future<void> saveProfileRecord(DataRecord record) async =>
      SessionStore.write(profileSessionKey, yamlOfRecord(record));

  @override
  Future<List<DataRecord>?> loadProjectRecords(ProjectsKind kind) async {
    final text = await _projectsText(kind);
    return text == null ? null : projectRecordsOfYaml(text);
  }

  @override
  Future<void> saveProjectRecords(ProjectsKind kind, List<DataRecord> records) async =>
      SessionStore.write(kind.name, yamlOfProjects(records));

  @override
  Future<void> clearProjects(ProjectsKind kind) async => SessionStore.remove(kind.name);

  // ---------- 文字（元の文字をそのまま） ----------

  @override
  Future<ProfileLoadResult> loadProfile() async {
    var errors = const <String>[];
    if (fromArg) {
      try {
        final result = Profile.parse(await loadAssetText(profileAssetPath));
        if (result.isOk) return ProfileLoadResult(profile: result.profile);
        errors = result.errors;
      } catch (e) {
        errors = ['$e'];
      }
    }

    final saved = SessionStore.read(profileSessionKey);
    if (saved != null) {
      final result = Profile.parse(saved);
      if (result.isOk) return ProfileLoadResult(profile: result.profile, errors: errors);
    }
    return ProfileLoadResult(errors: errors);
  }

  @override
  Future<void> saveProfile(String text) async => SessionStore.write(profileSessionKey, text);

  @override
  Future<String> loadProjectsText(ProjectsKind kind) async =>
      await _projectsText(kind) ?? await loadAssetText(PortfolioRepository.sampleAssetPath(kind));

  @override
  Future<void> saveProjectsText(ProjectsKind kind, String text) async => SessionStore.write(kind.name, text);

  @override
  Future<bool> isSampleProjects(ProjectsKind kind) async =>
      SessionStore.read(kind.name) == null && await startupProjects(kind) == null;
}
