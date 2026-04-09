// lib/utils/string_utils.dart

/// 文字列 or List を安全に List<String> に変換
List<String> parseToList(dynamic raw) {
  if (raw == null) return [];

  // YAMLのList対応
  if (raw is List) {
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // String対応（旧形式）
  if (raw is String) {
    return raw
        .split(RegExp(r'[,、\s]+')) // ← ここが超重要
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  return [];
}

/// 既存コード互換（UI側で使ってるやつ）
List<String> splitSkills(String value) {
  return value
      .split(RegExp(r'[,、\s]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}