// lib/widgets/account_bar.dart
//
// ログイン中に、公開ページ（/）の一番上に出すバー。公開ページを見ながら、ここからマイページの操作をする
// - ログイン中のメールアドレスと公開の状態（版 N を公開中・まだ公開していません）
// - ［公開する］／［公開を止める］、［マイページ］（名前・退会などをダイアログで。中身は lib/pages/my_page.dart の MyPagePanel）、
//   ［ログアウト］
// - ログインしていなければ出さない（HomePage が出し分ける）。幅が狭ければ折り返す
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/json_client.dart';
import '../api/portfolio_api.dart';
import '../auth/auth_controller.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../pages/my_page.dart';
import '../router/app_router.dart';

class AccountBar extends ConsumerStatefulWidget {
  const AccountBar({super.key});

  @override
  ConsumerState<AccountBar> createState() => _AccountBarState();
}

class _AccountBarState extends ConsumerState<AccountBar> {
  MeInfo? _me;
  String? _email;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // 最初の build の後に読む（initState の中では setState できないため）
    Future.microtask(_load);
  }

  Future<void> _load() => _run(() async {
        final me = await ref.read(portfolioApiProvider).me();
        final user = await ref.read(authApiProvider).me(await ref.read(authControllerProvider.notifier).idToken());
        if (mounted) {
          setState(() {
            _me = me;
            _email = user.email;
          });
        }
      });

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    if (!mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(Future<MeInfo> Function(PortfolioApi api) action, String done) => _run(() async {
        final me = await action(ref.read(portfolioApiProvider));
        if (mounted) setState(() => _me = me);
      }, done: done);

  Future<void> _openMyPage() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.space24, AppSizes.space16, AppSizes.space8, 0),
                child: Row(
                  children: [
                    Expanded(child: Text(RouteTexts.myPage, style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(
                      key: const Key('bar-mypage-close'),
                      tooltip: AccountTexts.close,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Flexible(child: MyPagePanel(inDialog: true)),
            ],
          ),
        ),
      ),
    );
    // ダイアログで名前・公開を変えたかもしれないので読み直す（ログアウト・退会していればもう出ていない）
    if (mounted && ref.read(authControllerProvider) != null) await _load();
  }

  Future<void> _logOut() async {
    await ref.read(authControllerProvider.notifier).logOut();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final published = _me?.publishedVersion;
    final status = _me == null ? '' : (published == null ? AccountTexts.notPublished : AccountTexts.published(published));
    // 画面の幅いっぱいに敷く（中身の Wrap の幅に縮まないように）
    return Material(
      color: colors.surfaceContainerHigh,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space16, vertical: AppSizes.space8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSizes.space12,
            runSpacing: AppSizes.space8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle_outlined, size: 20, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppSizes.space8),
                  Text(_email ?? AccountTexts.loggedIn, key: const Key('bar-email'), style: textTheme.bodyMedium),
                  if (status.isNotEmpty) ...[
                    const SizedBox(width: AppSizes.space12),
                    Text(status, key: const Key('bar-status'), style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ],
              ),
              Wrap(
                spacing: AppSizes.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (published == null)
                    FilledButton.tonal(
                      key: const Key('bar-publish'),
                      onPressed: _busy || _me == null ? null : () => _change((api) => api.publish(), AccountTexts.publishedDone),
                      child: const Text(AccountTexts.publish),
                    )
                  else
                    OutlinedButton(
                      key: const Key('bar-unpublish'),
                      onPressed: _busy ? null : () => _change((api) => api.unpublish(), AccountTexts.unpublishedDone),
                      child: const Text(AccountTexts.unpublish),
                    ),
                  TextButton.icon(
                    key: const Key('bar-mypage'),
                    onPressed: _busy ? null : _openMyPage,
                    icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                    label: const Text(RouteTexts.myPage),
                  ),
                  TextButton(
                    key: const Key('bar-logout'),
                    onPressed: _busy ? null : _logOut,
                    child: const Text(AccountTexts.logOutShort),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
