import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../ui.dart';
import 'validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _remember = false;
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text, remember: _remember);
    if (!mounted) return;
    setState(() => _busy = false);
    // On success the router redirect moves to /products.
    if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: AuthShell(
        icon: Icons.shopping_bag_rounded,
        title: 'PRM Shop',
        subtitle: 'Chào mừng bạn quay lại 👋',
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _hide,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _hide ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
            validator: (v) => notEmpty(v, 'Mật khẩu'),
          ),
          CheckboxListTile(
            value: _remember,
            onChanged: (v) => setState(() => _remember = v ?? false),
            title: const Text('Ghi nhớ đăng nhập'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          GradientButton(onPressed: _submit, busy: _busy, label: 'Đăng nhập', icon: Icons.login_rounded),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.go('/register'), child: const Text('Chưa có tài khoản? Đăng ký')),
        ],
      ),
    );
  }
}
