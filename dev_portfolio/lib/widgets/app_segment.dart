// lib/widgets/app_segment.dart
//
// セグメント（外枠＋選択中だけ浮き上がる切替ボタン）
// Projects の Work/Private・List/Collection、Skills の Work/Private・Bar/Pie で共通に使う。
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
    return Container(
      padding: AppSizes.segmentTrackPadding,
      decoration: AppStyles.segmentTrack(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final selected = item.value == value;
          final child = Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppStyles.radiusMd),
              onTap: selected ? null : () => onChanged(item.value),
              child: Container(
                padding: item.icon != null
                    ? AppSizes.iconSegmentItemPadding
                    : AppSizes.segmentItemPadding,
                decoration: AppStyles.segmentItem(context, selected: selected),
                child: item.icon != null
                    ? Icon(
                        item.icon,
                        size: AppSizes.iconSegmentSize,
                        color: AppStyles.segmentIcon(context, selected: selected),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.label ?? '',
                              style: AppStyles.segmentLabel(context, selected: selected)),
                          if (item.count != null) ...[
                            const SizedBox(width: AppSizes.space6),
                            Text('${item.count}', style: AppStyles.segmentCount(context)),
                          ],
                        ],
                      ),
              ),
            ),
          );
          return Semantics(
            button: true,
            selected: selected,
            label: item.tooltip ?? item.label,
            child: item.tooltip != null
                ? Tooltip(message: item.tooltip!, child: child)
                : child,
          );
        }).toList(),
      ),
    );
  }
}

/// セグメントの 1 項目（label か icon のどちらかを指定）
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
