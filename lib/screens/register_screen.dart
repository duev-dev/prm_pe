import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_database.dart';
import '../ui.dart';
import 'validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await AppDatabase.instance.register(_name.text.trim(), _email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email đã được đăng ký')));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng ký thành công'),
        content: const Text('Bạn có thể đăng nhập ngay bây giờ.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: AuthShell(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Tạo tài khoản',
        subtitle: 'Chỉ mất vài giây ✨',
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => notEmpty(v, 'Họ và tên'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline)),
            validator: validatePassword,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu', prefixIcon: Icon(Icons.lock_reset)),
            validator: (v) => v != _password.text ? 'Mật khẩu xác nhận không khớp' : null,
          ),
          const SizedBox(height: 24),
          GradientButton(onPressed: _submit, busy: _busy, label: 'Đăng ký', icon: Icons.check_rounded),
          const SizedBox(height: 8),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Đã có tài khoản? Đăng nhập')),
        ],
      ),
    );
  }
}
