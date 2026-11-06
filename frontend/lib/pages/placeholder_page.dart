// lib/pages/placeholder_page.dart
//
// まだ作っていない画面（ログイン・マイページ・編集）の代わり
// URL だけ先に用意し、中身は docs/plan/screens.md の段階 5 で作る。ビルドの設定（ENABLE_ACCOUNT）を付けたときだけ開ける
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../router/app_router.dart';

class PlaceholderPage extends StatelessWidget {
  /// 画面の名前（「ログイン」など）
  final String title;

  /// 画面設計の ID（「A-01」など）
  final String screenId;

  const PlaceholderPage({super.key, required this.title, required this.screenId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(RouteTexts.preparing, style: textTheme.titleMedium),
              const SizedBox(height: AppSizes.space8),
              Text(RouteTexts.planned(screenId), style: textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.space24),
              FilledButton.tonal(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text(RouteTexts.backToPublic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
