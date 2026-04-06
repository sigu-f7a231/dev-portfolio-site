class LanguageUtils {
  // 言語キー: ja, enなど
  static String currentLang = 'ja';

  // workflow の英語キー → 各言語での表示名
  static Map<String, Map<String, String>> workflowLabels = {
    'ja': {
      'requirements': '要件定義',
      'basic_design': '基本設計',
      'detailed_design': '詳細設計',
      'implementation_unit_test': '実装・単体テスト',
      'integration_test': '結合テスト',
      'system_test': '総合テスト',
      'maintenance_operation': '保守・運用',
    },
    'en': {
      'requirements': 'Requirements',
      'basic_design': 'Basic Design',
      'detailed_design': 'Detailed Design',
      'implementation_unit_test': 'Implementation / Unit Test',
      'integration_test': 'Integration Test',
      'system_test': 'System Test',
      'maintenance_operation': 'Maintenance / Operation',
    },
  };

  // 英語キー → 現在言語の表示名に変換
  static String getWorkflowLabel(String key) {
    return workflowLabels[currentLang]?[key] ?? key;
  }

  // Mapをまとめて変換
  static Map<String, double> translateWorkflowData(Map<String, double> data) {
    return data.map((key, value) => MapEntry(getWorkflowLabel(key), value));
  }
}