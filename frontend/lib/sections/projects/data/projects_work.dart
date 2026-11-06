// lib/sections/projects/data/projects_work.dart
//
// Work のプロジェクト（構造のデータ）→ 画面で使う Project。読み込みは Provider（lib/state/providers.dart）が Repository から行う
import '../../../data/records.dart';
import '../models/projects_model.dart';

List<Project> workProjectsOf(List<DataRecord> records) =>
    [for (final e in records) Project.fromMap(Map<String, dynamic>.from(e))];
