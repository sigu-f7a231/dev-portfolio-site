// lib/pages/login_page.dart
//
// ログイン・登録（画面設計の A-01・A-02）。パスワードを忘れたら、再設定のメールを送る（A-03 の入口）
// 成功したら、開こうとしていた URL（/login?from=…）か、マイページ（/me）へ。入力の確認は画面でも行い、最後はサーバー（認証）が確かめる
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/json_client.dart';
import '../auth/auth_controller.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../router/app_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _check({bool passwordToo = true}) {
    if (_email.text.trim().isEmpty) return AccountTexts.emailRequired;
    if (passwordToo && _password.text.length < 8) return AccountTexts.passwordTooShort;
    return null;
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (done != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final error = _check();
    if (error != null) return setState(() => _error = error);
    final auth = ref.read(authControllerProvider.notifier);
    await _run(() async {
      if (_signUp) {
        await auth.signUp(_email.text, _password.text);
      } else {
        await auth.logIn(_email.text, _password.text);
      }
      // 開こうとしていた URL（/login?from=…）へ。なければマイページ
      if (mounted) context.go(AppRoutes.afterLogin(GoRouterState.of(context).uri.queryParameters['from']));
    }, done: _signUp ? AccountTexts.signedUp : null);
  }

  Future<void> _forgot() async {
    final error = _check(passwordToo: false);
    if (error != null) return setState(() => _error = error);
    await _run(() => ref.read(authApiProvider).requestPasswordReset(_email.text.trim()), done: AccountTexts.resetSent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_signUp ? AccountTexts.signUp : AccountTexts.logIn)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('login-email'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: AccountTexts.email, border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: AppSizes.space16),
                  TextField(
                    key: const Key('login-password'),
                    controller: _password,
                    obscureText: !_showPassword,
                    autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: AccountTexts.password,
                      helperText: _signUp ? AccountTexts.passwordHint : null,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSizes.space12),
                    Text(_error!, key: const Key('login-error'), style: TextStyle(color: colors.error)),
                  ],
                  const SizedBox(height: AppSizes.space24),
                  FilledButton(
                    key: const Key('login-submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(_signUp ? AccountTexts.signUp : AccountTexts.logIn),
                  ),
                  const SizedBox(height: AppSizes.space8),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() {
                      _signUp = !_signUp;
                      _error = null;
                    }),
                    child: Text(_signUp ? AccountTexts.toLogIn : AccountTexts.toSignUp),
                  ),
                  if (!_signUp)
                    TextButton(onPressed: _busy ? null : _forgot, child: const Text(AccountTexts.forgotPassword)),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text(RouteTexts.backToPublic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
