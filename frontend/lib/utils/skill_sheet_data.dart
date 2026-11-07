// lib/utils/skill_sheet_data.dart
//
// スキルシート（Excel のテンプレート assets/data/format_skill_sheet.xlsx の形）に書く中身を作る
// - 本人の［ダウンロード］（lib/sections/header/download_menu.dart）と、見る人向けのスキルシート
//   （services/excel-fastapi が bin/skill_sheet.dart を呼ぶ）の両方で使う。どちらも同じ形・同じ並びになる
// - 見る人向けは公開ページのデータ（API の形）から作る。スキルシートだけの項目（ふりがな・生年月日・最寄駅など）は
//   公開ページに入っていないので空欄になる。データにあっても使わない
//
// Flutter に依存しない（dart compile exe でサーバーでも動かす）。
import 'dart:typed_data';

import '../data/api_records.dart';
import '../models/profile.dart';
import '../sections/projects/models/projects_model.dart';
import 'skill_sheet_pdf.dart';
import 'skill_sheet_writer.dart';
import 'tech_catalog.dart';

/// プロジェクト（YAML の形）を、スキルシートに書く順（開始の古い順）・分類（Skills・Tools に書かれた
/// フロントエンドなどを本来の分類へ。画面の表示と同じ）にする
List<Map<String, dynamic>> skillSheetProjects(Iterable<Object?> projects) {
  final list = redistributeProjects(projects);
  list.sort((a, b) => Project.fromMap(a).periodStart.compareTo(Project.fromMap(b).periodStart));
  return list;
}

/// プロフィールと Work / Private（YAML の形）→ スキルシートの中身
SkillSheetData skillSheetDataOf(Profile profile, Iterable<Object?> work, Iterable<Object?> private) => SkillSheetData(
      name: profile.name,
      experience: profile.name.isEmpty ? '' : experienceTextOf(profile),
      work: skillSheetProjects(work),
      private: skillSheetProjects(private),
      // ふりがな・生年月日などは、読み込んだスキルシート（Excel）に書かれていたものをそのまま
      sheet: profile.sheet,
    );

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
String _text(Object? v) => v is String ? v : '';
List<String> _list(Object? v) => [if (v is List) for (final e in v) if (e is String) e];
Map<String, List<String>> _groups(Object? v) => {
      for (final e in _map(v).entries)
        if (_list(e.value) case final items when items.isNotEmpty) e.key: items,
    };

/// 公開ページのデータ（API の形。services/api-hono の publicDataOf の結果）→ スキルシートの中身
/// スキルシートだけの項目は使わない（公開ページに入っていないが、念のため）
SkillSheetData publicSkillSheetData(Map<String, dynamic> data) {
  final profile = _map(data['profile']);
  final home = _map(profile['home']);
  final about = _map(profile['about']);
  final skills = _map(data['skills']);
  final person = Profile(
    name: _text(home['name']),
    role: _text(home['role']),
    tagline: _text(home['tagline']),
    intro: _text(about['intro']),
    domains: _list(about['domains']),
    strengths: _text(about['strengths']),
    style: _text(about['style']),
    closing: _text(about['closing']),
    recent: _text(about['recent']),
    past: _text(about['past']),
    recentTech: _groups(skills['recentTech']),
    pastTech: _groups(skills['pastTech']),
  );
  final projects = [for (final p in (data['projects'] is List ? data['projects'] as List : const [])) _map(p)]
    ..sort((a, b) => ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0));
  List<Map<String, dynamic>> of(String kind) => [
        for (final p in projects)
          if (p['kind'] == kind) projectFromApi(p),
      ];
  return skillSheetDataOf(person, of('work'), of('private'));
}

/// スキルシートのバイト列。[font] があれば PDF（Excel の見た目のまま）、なければ Excel
Future<Uint8List> buildSkillSheet(Uint8List template, SkillSheetData data, {ByteData? font, DateTime? today}) async {
  final xlsx = fillSkillSheet(template, data, today: today);
  return font == null ? xlsx : skillSheetPdf(xlsx, font);
}
