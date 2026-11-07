// lib/api/portfolio_api.dart
//
// API（services/api-hono）の呼び出し。ログインが要るもの（/api/me/...）は、毎回 [token] で ID トークンをもらう
// （期限が近ければ取り直したもの。AuthController.idToken）
import 'json_client.dart';

/// 本人の情報
class MeInfo {
  const MeInfo({required this.slug, required this.latestVersion, required this.publishedVersion});

  factory MeInfo.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    final latest = map['latestVersion'];
    final published = map['publishedVersion'];
    return MeInfo(
      slug: map['slug'] is String ? map['slug'] as String : null,
      latestVersion: latest is int ? latest : 0,
      publishedVersion: published is int ? published : null,
    );
  }

  final String? slug;
  final int latestVersion;
  final int? publishedVersion;
}

/// 編集中のデータ全体
class Draft {
  const Draft({required this.data, required this.updatedAt});

  factory Draft.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    final data = map['data'];
    return Draft(
      data: data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
      updatedAt: map['updatedAt'] is String ? map['updatedAt'] as String : null,
    );
  }

  final Map<String, dynamic> data;

  /// まだ保存していなければ null
  final String? updatedAt;
}

class PortfolioApi {
  PortfolioApi(this._client, this._token);

  final JsonClient _client;
  final Future<String> Function() _token;

  Future<MeInfo> me() async => MeInfo.fromJson(await _client.get('/api/me', token: await _token()));
  Future<MeInfo> setSlug(String slug) async =>
      MeInfo.fromJson(await _client.put('/api/me/slug', body: {'slug': slug}, token: await _token()));
  Future<MeInfo> publish() async => MeInfo.fromJson(await _client.post('/api/me/publish', body: const {}, token: await _token()));
  Future<MeInfo> unpublish() async => MeInfo.fromJson(await _client.delete('/api/me/publish', token: await _token()));

  /// 退会：本人のデータをすべて消す（アカウントは認証で消す）
  Future<void> deleteAll() async => _client.delete('/api/me', token: await _token());

  Future<Draft> draft() async => Draft.fromJson(await _client.get('/api/me/draft', token: await _token()));
  Future<Draft> saveDraft(Map<String, dynamic> data, String? updatedAt) async => Draft.fromJson(
        await _client.put('/api/me/draft', body: {'data': data, 'updatedAt': updatedAt}, token: await _token()),
      );
}
