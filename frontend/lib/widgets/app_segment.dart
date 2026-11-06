// lib/widgets/app_segment.dart
//
// 切替ボタン（Material 3 の SegmentedButton）
// Projects の Work/Private・List/Collection、Skills の Work/Private・Bar/Pie で共通に使う。
// 色・形は ThemeData（M3 の colorScheme）から自動で決まる。
import 'package:flutter/material.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';

class AppSegment<T> extends StatelessWidget {
  final T value;
  final List<AppSegmentItem<T>> items;
  final ValueChanged<T> onChanged;

  const AppSegment({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // アイコンだけのセグメントは、選択中のチェックマークを出さない（アイコンが置き換わってしまうため）
    final iconOnly = items.every((i) => i.label == null);

    return SegmentedButton<T>(
      segments: items
          .map((item) => ButtonSegment<T>(
                value: item.value,
                tooltip: item.tooltip,
                icon: item.icon != null ? Icon(item.icon) : null,
                label: item.label == null
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 幅が足りないとき（狭い画面・長いラベル）は「…」で切る（はみ出さない）
                          Flexible(
                            child: Text(item.label!, overflow: TextOverflow.ellipsis, softWrap: false),
                          ),
                          if (item.count != null) ...[
                            const SizedBox(width: AppSizes.space6),
                            Text('${item.count}', style: AppStyles.segmentCount(context)),
                          ],
                        ],
                      ),
              ))
          .toList(),
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: !iconOnly,
    );
  }
}

/// セグメントの 1 項目（label か icon の少なくとも一方を指定）
class AppSegmentItem<T> {
  final T value;
  final String? label;
  final IconData? icon;

  /// ラベルの横に出す件数（任意）
  final int? count;
  final String? tooltip;

  const AppSegmentItem({
    required this.value,
    this.label,
    this.icon,
    this.count,
    this.tooltip,
  });
}
