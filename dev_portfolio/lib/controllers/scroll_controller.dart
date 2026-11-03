import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../constants/app_sizes.dart';
import '../sections/config/header_config.dart';

class SectionScrollController {
  final ScrollController controller = ScrollController();
  final Map<String, GlobalKey> keys = {
    'home': GlobalKey(),
    'about': GlobalKey(),
    'skills': GlobalKey(),
    'projects': GlobalKey(),
  };

  /// いま表示中のセクション（ヘッダーのナビ・Drawer の選択表示に使う）
  final ValueNotifier<String> active = ValueNotifier('home');

  /// ボタンでスクロール中は、途中のセクションで表示が揺れないようにする
  bool _jumping = false;

  SectionScrollController() {
    controller.addListener(_updateActive);
  }

  Future<void> scrollTo(String section) async {
    final context = keys[section]?.currentContext;
    if (context == null) return;
    active.value = section;
    _jumping = true;
    await Scrollable.ensureVisible(context, duration: AppSizes.scrollDuration);
    _jumping = false;
  }

  void _updateActive() {
    if (_jumping || !controller.hasClients) return;
    final pos = controller.position;

    // いちばん下まで来たら最後のセクション
    if (pos.pixels >= pos.maxScrollExtent - 1) {
      active.value = keys.keys.last;
      return;
    }

    final line = pos.pixels + pos.viewportDimension * HeaderConfig.activeSectionLine;
    var current = keys.keys.first;
    for (final entry in keys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box == null || !box.attached) continue;
      final top = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
      if (top <= line) current = entry.key;
    }
    active.value = current;
  }

  void dispose() {
    controller.dispose();
    active.dispose();
  }
}
