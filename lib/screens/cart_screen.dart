import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import 'product_list_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider.notifier);
    final total = cart.total;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text('Tổng tiền: ${money(total)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thanh toán')),
        ],
      ),
    );
    if (ok != true) return;
    await cart.checkout();
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Đặt hàng thành công'),
        content: Text('Đơn hàng ${money(total)} đã được ghi nhận.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: items.isEmpty
          ? const Center(child: Text('Giỏ hàng trống'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final c = items[i];
                final id = c.product.id!;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductImage(c.product.imageUrl, size: 56),
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('${money(c.product.price)} × ${c.quantity} = ${money(c.total)}'),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Giảm',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cart.setQuantity(id, c.quantity - 1),
                        ),
                        Text('${c.quantity}', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          tooltip: 'Tăng',
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => cart.setQuantity(id, c.quantity + 1),
                        ),
                        IconButton(
                          tooltip: 'Xoá khỏi giỏ',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            cart.remove(id);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Đã xoá "${c.product.name}"')));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text('Tổng: ${money(cart.total)}', style: Theme.of(context).textTheme.titleLarge)),
                    FilledButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Checkout'),
                      onPressed: () => _checkout(context, ref),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
