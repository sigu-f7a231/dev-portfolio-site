import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';

/// フィルターの 1 グループ（見出し＋選べるチップ）
/// Projects のフィルター（複数選択）と Skills のカテゴリ（1 つだけ選択）で共通に使う。
/// 選択の仕方（複数 / 1 つ）は呼び出し側の onSelected で決める。
/// チップは Material 3 の FilterChip（色・形はテーマから自動）。
class FilterChipsSection extends StatelessWidget {
  final String? title;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<String> onSelected;

  /// 表示名（省略時は items の値をそのまま表示）
  final String Function(String item)? labelOf;

  const FilterChipsSection({
    super.key,
    this.title,
    required this.items,
    required this.selectedItems,
    required this.onSelected,
    this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: Text(title!, style: AppStyles.filterGroupLabel(context)),
          ),
        Wrap(
          spacing: AppSizes.space8,
          runSpacing: AppSizes.space8,
          children: items.map((item) {
            return FilterChip(
              label: Text(labelOf?.call(item) ?? item),
              selected: selectedItems.contains(item),
              onSelected: (_) => onSelected(item),
              showCheckmark: true,
            );
          }).toList(),
        ),
      ],
    );
  }
}
