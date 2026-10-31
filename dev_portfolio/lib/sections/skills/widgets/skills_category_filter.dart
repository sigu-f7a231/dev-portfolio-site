// lib/sections/skills/widgets/skills_category_filter.dart
//
// Skills のカテゴリ選択（Projects のフィルターと同じ作り）
// - ツールバーの「カテゴリ」ボタン（今のカテゴリ名を表示）
// - ボタンで開くパネル：グループ別のチップから 1 つだけ選び、「反映」でグラフを切り替える
import 'package:flutter/material.dart';
import '../../config/skills/skills_widgets_header_config.dart';
import '../../../widgets/filter_chips_section.dart';
import '../../../theme/app_styles.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_texts.dart';

/// パネルに並べるグループ（見出し＋カテゴリキー）
class SkillsCategoryGroup {
  final String title;
  final List<String> categories;

  const SkillsCategoryGroup(this.title, this.categories);
}

/// ツールバーの「カテゴリ」ボタン
class SkillsCategoryButton extends StatelessWidget {
  final String currentLabel;
  final bool open;
  final VoidCallback onPressed;

  const SkillsCategoryButton({
    super.key,
    required this.currentLabel,
    required this.open,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: AppStyles.toolbarButton(context, active: open),
      icon: const Icon(Icons.tune, size: SkillsHeaderConfig.categoryButtonIconSize),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppTexts.category),
          const SizedBox(width: AppSizes.space8),
          Container(
            padding: SkillsHeaderConfig.currentCategoryPadding,
            decoration: AppStyles.countBadge(context),
            child: Text(currentLabel, style: AppStyles.countBadgeText(context)),
          ),
        ],
      ),
    );
  }
}

/// カテゴリパネル（1 つだけ選択 →「反映」で確定）
class SkillsCategoryPanel extends StatefulWidget {
  /// データがあるカテゴリだけを入れたグループ（空のグループは呼び出し側で除く）
  final List<SkillsCategoryGroup> groups;
  final String current;
  final String Function(String category) labelOf;
  final ValueChanged<String> onApply;
  final VoidCallback onClose;

  const SkillsCategoryPanel({
    super.key,
    required this.groups,
    required this.current,
    required this.labelOf,
    required this.onApply,
    required this.onClose,
  });

  @override
  State<SkillsCategoryPanel> createState() => _SkillsCategoryPanelState();
}

class _SkillsCategoryPanelState extends State<SkillsCategoryPanel> {
  /// パネル内で選んでいるカテゴリ（「反映」を押すまでグラフは変わらない）
  late String _pending = widget.current;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: SkillsHeaderConfig.panelPadding,
      decoration: AppStyles.filterPanel(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 見出し＋閉じる
          Row(
            children: [
              Expanded(
                child: Text(
                  AppTexts.category,
                  style: AppStyles.title(
                    context,
                    fontSize: SkillsHeaderConfig.panelTitleFontSize,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: AppTexts.close,
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.space8),

          // グループ（幅があれば 2 列）
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >=
                  SkillsHeaderConfig.panelTwoColumnBreakpoint;
              const gap = SkillsHeaderConfig.panelGroupGap;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: gap,
                runSpacing: AppSizes.space20,
                children: widget.groups
                    .map((g) => SizedBox(
                          width: itemWidth,
                          child: FilterChipsSection(
                            title: g.title,
                            items: g.categories,
                            labelOf: widget.labelOf,
                            selectedItems: [_pending],
                            // 1 つだけ選択：押したものに置き換える
                            onSelected: (c) => setState(() => _pending = c),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSizes.space20),

          // フッター
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onClose,
                child: const Text(AppTexts.cancel),
              ),
              const SizedBox(width: AppSizes.space8),
              ElevatedButton(
                onPressed: () => widget.onApply(_pending),
                child: const Text(AppTexts.filterApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
