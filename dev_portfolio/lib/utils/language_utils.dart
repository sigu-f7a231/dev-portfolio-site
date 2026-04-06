
class LanguageUtils {
  // workflow の日本語ラベル
  static const Map<String, Map<String, String>> workflowLabels = {
    'ja': {
      'requirements': '要件定義',
      'basic_design': '基本設計',
      'detailed_design': '詳細設計',
      'implementation_unit_test': '実装・単体テスト',
      'integration_test': '結合テスト',
      'system_test': 'システムテスト',
      'maintenance_operation': '保守・運用',
    },
  };

  /// workflow データを日本語化＆100%正規化
  static Map<String, double> translateWorkflowData(Map<String, double> data,
      {String locale = 'ja'}) {
    if (!workflowLabels.containsKey(locale)) return data;

    final labels = workflowLabels[locale]!;

    // 日本語化
    final translated = <String, double>{};
    data.forEach((key, value) {
      translated[labels[key] ?? key] = value;
    });

    // 正規化
    final total = translated.values.fold<double>(0, (sum, v) => sum + v);
    if (total == 0) return translated;

    return translated.map((k, v) => MapEntry(k, (v / total) * 100));
  }
}