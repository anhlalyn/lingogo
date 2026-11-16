import 'package:flutter/material.dart';
import 'app.dart';
import 'auth_service.dart';
import 'branding.dart';

enum AuthMode { signIn, register, reset }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.auth});
  final AuthService auth;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  AuthMode mode = AuthMode.signIn;
  bool busy = false, obscure = true, resetSent = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  void switchMode(AuthMode next) {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      mode = next;
      error = null;
      resetSent = false;
      password.clear();
      confirm.clear();
      form.currentState?.reset();
    });
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      error = null;
      resetSent = false;
    });
    try {
      switch (mode) {
        case AuthMode.signIn:
          await widget.auth.signIn(email.text.trim(), password.text);
        case AuthMode.register:
          await widget.auth.register(email.text.trim(), password.text);
        case AuthMode.reset:
          await widget.auth.resetPassword(email.text.trim());
          if (mounted) setState(() => resetSent = true);
      }
    } catch (e) {
      if (mounted) setState(() => error = authError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registering = mode == AuthMode.register;
    final resetting = mode == AuthMode.reset;
    return PopScope(
      canPop: !busy && mode == AuthMode.signIn,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) switchMode(AuthMode.signIn);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AutofillGroup(
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        const Center(
                          child: BrandWordmark(size: 38, fontSize: 32),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FF),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              resetting
                                  ? Icons.mark_email_read_outlined
                                  : registering
                                  ? Icons.person_add_alt_1_rounded
                                  : Icons.waving_hand_rounded,
                              color: purple,
                              size: 45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          resetting
                              ? 'Quên mật khẩu?'
                              : registering
                              ? 'Bắt đầu hành trình mới'
                              : 'Chào mừng trở lại!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          resetting
                              ? 'Nhập email đã đăng ký để nhận liên kết đặt lại mật khẩu.'
                              : registering
                              ? 'Tạo tài khoản để khám phá Anh, Trung, Nhật và Hàn.'
                              : 'Đăng nhập để tiếp tục hành trình ngôn ngữ của bạn.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: muted),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          key: const Key('auth-email'),
                          controller: email,
                          enabled: !busy,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: resetting
                              ? TextInputAction.done
                              : TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'ban@example.com',
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (value) =>
                              RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Vui lòng nhập email hợp lệ.',
                          onFieldSubmitted: (_) {
                            if (resetting) submit();
                          },
                        ),
                        if (!resetting) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('auth-password'),
                            controller: password,
                            enabled: !busy,
                            obscureText: obscure,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: registering
                                ? TextInputAction.next
                                : TextInputAction.done,
                            autofillHints: [
                              registering
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() => obscure = !obscure),
                                tooltip: obscure
                                    ? 'Hiện mật khẩu'
                                    : 'Ẩn mật khẩu',
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu.';
                              }
                              if (registering && value.length < 6) {
                                return 'Mật khẩu cần ít nhất 6 ký tự.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!registering) submit();
                            },
                          ),
                          if (registering) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('auth-confirm'),
                              controller: confirm,
                              enabled: !busy,
                              obscureText: obscure,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Nhập lại mật khẩu',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (value) =>
                                  value == password.text &&
                                      (value?.isNotEmpty ?? false)
                                  ? null
                                  : 'Mật khẩu nhập lại chưa khớp.',
                              onFieldSubmitted: (_) => submit(),
                            ),
                          ] else
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: busy
                                    ? null
                                    : () => switchMode(AuthMode.reset),
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ),
                        ],
                        if (error != null || widget.auth.sessionError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                error ?? widget.auth.sessionError!,
                                style: const TextStyle(
                                  color: Color(0xFFB3261E),
                                ),
                              ),
                            ),
                          ),
                        if (resetSent)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Semantics(
                              liveRegion: true,
                              child: const Panel(
                                color: Color(0xFFE6F7EF),
                                child: Text(
                                  'Nếu email có tài khoản, bạn sẽ nhận được liên kết đặt lại mật khẩu. Hãy kiểm tra cả thư rác.',
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        Primary(
                          busy
                              ? 'Đang xử lý…'
                              : resetting
                              ? (resetSent
                                    ? 'Gửi lại liên kết'
                                    : 'Gửi liên kết đặt lại')
                              : registering
                              ? 'Tạo tài khoản'
                              : 'Đăng nhập',
                          onPressed: busy ? null : submit,
                          icon: resetting
                              ? Icons.send_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        if (busy)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => switchMode(
                                  mode == AuthMode.signIn
                                      ? AuthMode.register
                                      : AuthMode.signIn,
                                ),
                          child: Text(
                            resetting
                                ? 'Quay lại đăng nhập'
                                : registering
                                ? 'Đã có tài khoản? Đăng nhập'
                                : 'Chưa có tài khoản? Đăng ký',
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Một tài khoản, nhiều ngôn ngữ.\nTừng bước nhỏ, chạm ước mơ lớn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
