// lib/data/api_portfolio_repository.dart
//
// ログイン中の Repository：データは API（services/api-hono）＝ Firestore に置く
// - 構造のデータの 5 つ（PortfolioRepository の「実装が用意するもの」）だけを書く。YAML の文字・サンプルは基底の作り方のまま
// - 読み書きは編集中のデータ全体（/api/me/draft）を通す。書くときは読んだときの updatedAt を付け、
//   ほかの場所で先に変わっていたら（409）読み直して 3 回までやり直す（Work だけ変えたら Private は残す、など）
// - データの形の行き来は api_records.dart
import '../api/json_client.dart';
import '../api/portfolio_api.dart';
import 'api_records.dart';
import 'portfolio_repository.dart';

class ApiPortfolioRepository extends PortfolioRepository {
  ApiPortfolioRepository(this._api, {String Function() newId = newProjectId}) : _newId = newId;

  final PortfolioApi _api;
  final String Function() _newId;

  static const int _maxAttempts = 3;

  Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  List<Map<String, dynamic>> _projects(Map<String, dynamic> data) =>
      [for (final p in (data['projects'] is List ? data['projects'] as List : const [])) if (p is Map) Map<String, dynamic>.from(p)];

  /// 読み直して [change] で変え、保存する。ほかの場所と重なったらやり直す
  Future<void> _update(void Function(Map<String, dynamic> data) change) async {
    for (var attempt = 1; ; attempt++) {
      final draft = await _api.draft();
      final data = Map<String, dynamic>.from(draft.data);
      change(data);
      try {
        await _api.saveDraft(data, draft.updatedAt);
        return;
      } on ApiException catch (e) {
        if (e.status != 409 || attempt >= _maxAttempts) rethrow;
      }
    }
  }

  @override
  Future<DataRecord?> loadProfileRecord() async {
    final draft = await _api.draft();
    if (draft.updatedAt == null) return null;
    final profile = _map(draft.data['profile']);
    if (profile.isEmpty) return null;
    return profileFromApi(profile, _map(draft.data['skills']));
  }

  @override
  Future<void> saveProfileRecord(DataRecord record) => _update((data) {
        final converted = profileToApi(record);
        data['profile'] = converted.profile;
        data['skills'] = converted.skills;
      });

  @override
  Future<List<DataRecord>?> loadProjectRecords(ProjectsKind kind) async {
    final draft = await _api.draft();
    if (draft.updatedAt == null) return null; // まだ何も保存していない → サンプルを見せる
    final projects = [for (final p in _projects(draft.data)) if (p['kind'] == kind.name) p]
      ..sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
    return [for (final p in projects) projectFromApi(p)];
  }

  @override
  Future<void> saveProjectRecords(ProjectsKind kind, List<DataRecord> records) => _update((data) {
        final previous = _projects(data);
        data['projects'] = [
          for (final p in previous) if (p['kind'] != kind.name) p,
          ...projectsToApi(records, kind: kind.name, previous: previous, newId: _newId),
        ];
      });

  @override
  Future<void> clearProjects(ProjectsKind kind) => saveProjectRecords(kind, const []);
}
