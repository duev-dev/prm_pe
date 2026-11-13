import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../ui.dart';
import 'product_list_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final total = ref.read(cartProvider.notifier).total;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.payment_rounded, size: 40),
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Tổng tiền: ${money(total)}\nThanh toán qua PayOS (chuyển khoản QR).',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thanh toán')),
        ],
      ),
    );
    // The order is recorded by PaymentScreen once PayOS confirms the payment.
    if (ok == true && context.mounted) context.push('/payment');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: items.isEmpty
          ? Center(
              child: FadeSlideIn(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: brandGradient),
                      child: const Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text('Giỏ hàng trống', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Hãy chọn vài món bạn thích nhé!'),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Tiếp tục mua sắm'),
                      onPressed: () => context.go('/products'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final c = items[i];
                final id = c.product.id!;
                return FadeSlideIn(
                  key: ValueKey(id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Dismissible(
                      key: ValueKey('dismiss-$id'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                      ),
                      onDismissed: (_) {
                        cart.remove(id);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text('Đã xoá "${c.product.name}"')));
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: ProductImage(c.product.imageUrl, size: 72),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '${money(c.product.price)} / sp',
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            money(c.total),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Xoá khỏi giỏ',
                                          color: Colors.redAccent,
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () {
                                            cart.remove(id);
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(SnackBar(content: Text('Đã xoá "${c.product.name}"')));
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Column(
                                  children: [
                                    IconButton(
                                      tooltip: 'Tăng',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => cart.setQuantity(id, c.quantity + 1),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                                      child: Text(
                                        '${c.quantity}',
                                        key: ValueKey(c.quantity),
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Giảm',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () => cart.setQuantity(id, c.quantity - 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20)],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tổng cộng', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                            Text(
                              money(cart.total),
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      GradientButton(
                        icon: Icons.payment_rounded,
                        label: 'Checkout',
                        onPressed: () => _checkout(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
