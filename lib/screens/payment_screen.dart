import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/payment_api.dart';
import '../providers/providers.dart';
import '../ui.dart';
import 'product_list_screen.dart';

/// Pays the current cart through PayOS. The order is only recorded once PayOS reports PAID.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late final int _amount = ref.read(cartProvider.notifier).total.round();
  int? _orderCode;
  String? _checkoutUrl;
  String? _error;
  bool _done = false;
  bool _checking = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _orderCode = null;
    });
    try {
      final link = await PaymentApi.create(_amount);
      if (!mounted) return;
      setState(() {
        _orderCode = link.orderCode;
        _checkoutUrl = link.checkoutUrl;
      });
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => _check());
      await _open();
    } catch (e) {
      if (mounted) setState(() => _error = 'Không tạo được link thanh toán.\n$e');
    }
  }

  Future<void> _open() async {
    final ok = await launchUrl(Uri.parse(_checkoutUrl!), mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không mở được trang thanh toán')));
    }
  }

  Future<void> _check() async {
    if (_checking || _done || _orderCode == null) return;
    _checking = true;
    try {
      final s = await PaymentApi.status(_orderCode!);
      if (!mounted) return;
      if (s.status == 'PAID') {
        await _paid(s.amountPaid);
      } else if (s.status == 'CANCELLED' || s.status == 'EXPIRED') {
        _poll?.cancel();
        setState(() => _error = s.status == 'CANCELLED' ? 'Thanh toán đã bị huỷ.' : 'Link thanh toán đã hết hạn.');
      }
    } catch (_) {
      // Network blip: the next tick retries.
    } finally {
      _checking = false;
    }
  }

  Future<void> _paid(int amountPaid) async {
    if (_done) return;
    _done = true;
    _poll?.cancel();
    try {
      await closeInAppWebView();
    } catch (_) {} // Not closable on every platform; the user can close it manually.
    // Record what PayOS says was paid, not what the app computed.
    await ref.read(cartProvider.notifier).checkout(total: amountPaid.toDouble());
    if (!mounted) return;
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
          ),
        ),
        title: const Text('Thanh toán thành công 🎉'),
        content: Text(
          'Đã nhận ${money(amountPaid.toDouble())}. Đơn hàng đã được ghi nhận.',
          textAlign: TextAlign.center,
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    if (mounted) context.go('/products');
  }

  /// Leaving a pending payment: check once more (the user may have just paid), otherwise cancel the link
  /// so it cannot be paid later without an order being recorded.
  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ thanh toán?'),
        content: const Text('Link thanh toán sẽ bị huỷ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tiếp tục thanh toán')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Huỷ')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _poll?.cancel();
    try {
      final s = await PaymentApi.status(_orderCode!);
      if (s.status == 'PAID') return await _paid(s.amountPaid);
      await PaymentApi.cancel(_orderCode!);
    } catch (_) {} // Unpaid links also expire on their own.
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = _orderCode != null && _error == null && !_done;

    final Widget status;
    if (_error != null) {
      status = Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GradientButton(onPressed: _start, label: 'Thử lại', icon: Icons.refresh),
          TextButton(onPressed: () => context.pop(), child: const Text('Quay lại giỏ hàng')),
        ],
      );
    } else if (_done) {
      status = const Icon(Icons.check_circle, size: 72, color: Colors.green);
    } else if (_orderCode == null) {
      status = const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang kết nối máy chủ thanh toán...\nLần đầu có thể mất tới 1 phút.', textAlign: TextAlign.center),
        ],
      );
    } else {
      status = Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Đang chờ thanh toán (mã đơn $_orderCode)', textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Quét QR bằng app ngân hàng. Trang này tự cập nhật khi thanh toán xong.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          GradientButton(onPressed: _open, label: 'Mở trang thanh toán', icon: Icons.qr_code_2),
          TextButton(onPressed: _leave, child: const Text('Huỷ thanh toán')),
        ],
      );
    }

    return PopScope(
      canPop: !pending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Thanh toán PayOS', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  Text('Số tiền cần thanh toán', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 6),
                  Text(
                    money(_amount.toDouble()),
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            status,
          ],
        ),
      ),
    );
  }
}
