import 'package:flutter/material.dart';

class SectionScrollController {
  final ScrollController controller = ScrollController();
  final Map<String, GlobalKey> keys = {
    'home': GlobalKey(),
    'about': GlobalKey(),
    'skills': GlobalKey(),
    'projects': GlobalKey(),
  };

  void scrollTo(String section) {
    final key = keys[section];
    final context = key?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500));
    }
  }
}