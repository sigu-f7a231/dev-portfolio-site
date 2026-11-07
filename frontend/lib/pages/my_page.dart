// lib/pages/my_page.dart
//
// マイページ（画面設計の M-01・M-07・M-08 の一部）
// - 公開ページの名前（slug）を決める、公開する・公開を止める、ログアウト、退会
// - 中身（MyPagePanel）は、/me の画面と、公開ページの上のバー（lib/widgets/account_bar.dart）の［マイページ］の
//   ダイアログの両方で使う
// - 内容の編集は、公開ページ（/）の［データ］から（ログイン中はアカウントに保存される）。編集・表示設定の画面は段階 5-2
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/json_client.dart';
import '../api/portfolio_api.dart';
import '../auth/auth_controller.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../router/app_router.dart';

/// /me の画面
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider) != null;
    return Scaffold(
      appBar: AppBar(title: const Text(RouteTexts.myPage)),
      body: loggedIn ? const MyPagePanel() : const _NeedLogIn(),
    );
  }
}

class _NeedLogIn extends StatelessWidget {
  const _NeedLogIn();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AccountTexts.needLogIn),
            const SizedBox(height: AppSizes.space16),
            FilledButton(onPressed: () => context.go(AppRoutes.login), child: const Text(AccountTexts.logIn)),
          ],
        ),
      );
}

/// マイページの中身。[inDialog] なら公開ページの上のダイアログの中（［公開ページで編集する］は出さず、終わったら閉じる）
class MyPagePanel extends ConsumerStatefulWidget {
  const MyPagePanel({super.key, this.inDialog = false});

  final bool inDialog;

  @override
  ConsumerState<MyPagePanel> createState() => _MyPagePanelState();
}

class _MyPagePanelState extends ConsumerState<MyPagePanel> {
  final _slug = TextEditingController();
  MeInfo? _me;
  String? _email;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 最初の build の後に読む（initState の中では setState できないため）
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _slug.dispose();
    super.dispose();
  }

  Future<void> _load() => _run(() async {
        final auth = ref.read(authControllerProvider.notifier);
        final me = await ref.read(portfolioApiProvider).me();
        final user = await ref.read(authApiProvider).me(await auth.idToken());
        if (!mounted) return;
        setState(() {
          _me = me;
          _email = user.email;
          _slug.text = me.slug ?? '';
        });
      });

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted && done != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(Future<MeInfo> Function(PortfolioApi api) action, String done) => _run(() async {
        final me = await action(ref.read(portfolioApiProvider));
        if (mounted) setState(() => _me = me);
      }, done: done);

  /// 終わったら：ダイアログなら閉じる、画面ならその URL へ（ログインを使うビルドでは、ログアウトしたら自動でログインに移る）
  void _leave(String location) {
    if (!mounted) return;
    if (widget.inDialog) {
      Navigator.of(context).pop();
    } else {
      context.go(location);
    }
  }

  Future<void> _logOut() async {
    await ref.read(authControllerProvider.notifier).logOut();
    _leave(AppRoutes.login);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AccountTexts.deleteConfirmTitle),
        content: const Text(AccountTexts.deleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(AppTexts.cancel)),
          FilledButton(
            key: const Key('delete-confirm'),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AccountTexts.deleteConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      _leave(AppRoutes.home);
    }, done: AccountTexts.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final textTheme = Theme.of(context).textTheme;
    final published = me?.publishedVersion;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.space24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (_email != null) Text(_email!, style: textTheme.titleMedium),
              if (_error != null) ...[
                const SizedBox(height: AppSizes.space12),
                Text(_error!, key: const Key('my-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSizes.space24),
              Text(AccountTexts.slug, style: textTheme.titleSmall),
              const SizedBox(height: AppSizes.space8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('my-slug'),
                      controller: _slug,
                      decoration: const InputDecoration(helperText: AccountTexts.slugHint, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  FilledButton.tonal(
                    key: const Key('my-slug-save'),
                    onPressed: _busy ? null : () => _change((api) => api.setSlug(_slug.text.trim()), AccountTexts.slugSaved),
                    child: const Text(AccountTexts.save),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space24),
              Text(
                published == null ? AccountTexts.notPublished : AccountTexts.published(published),
                key: const Key('my-status'),
                style: textTheme.titleSmall,
              ),
              if (me != null && me.latestVersion > 0) Text(AccountTexts.latest(me.latestVersion), style: textTheme.bodySmall),
              const SizedBox(height: AppSizes.space12),
              Wrap(
                spacing: AppSizes.space12,
                runSpacing: AppSizes.space8,
                children: [
                  FilledButton(
                    key: const Key('my-publish'),
                    onPressed: _busy ? null : () => _change((api) => api.publish(), AccountTexts.publishedDone),
                    child: const Text(AccountTexts.publish),
                  ),
                  if (published != null)
                    OutlinedButton(
                      key: const Key('my-unpublish'),
                      onPressed: _busy ? null : () => _change((api) => api.unpublish(), AccountTexts.unpublishedDone),
                      child: const Text(AccountTexts.unpublish),
                    ),
                ],
              ),
              if (!widget.inDialog) ...[
                const SizedBox(height: AppSizes.space24),
                Text(AccountTexts.editHint, style: textTheme.bodyMedium),
                const SizedBox(height: AppSizes.space8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(onPressed: () => context.go(AppRoutes.home), child: const Text(AccountTexts.openEditor)),
                ),
              ],
              const SizedBox(height: AppSizes.space36),
              const Divider(),
              Wrap(
                spacing: AppSizes.space12,
                children: [
                  TextButton(key: const Key('my-logout'), onPressed: _busy ? null : _logOut, child: const Text(AccountTexts.logOut)),
                  TextButton(
                    key: const Key('my-delete'),
                    onPressed: _busy ? null : _delete,
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text(AccountTexts.deleteAccount),
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
