import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import 'product_list_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  Future<void> _delete(BuildContext context, WidgetRef ref, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá sản phẩm?'),
        content: Text('Bạn chắc chắn muốn xoá "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(productsProvider.notifier).remove(p.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xoá "${p.name}"')));
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider).value;
    final p = products?.where((e) => e.id == productId).firstOrNull;

    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: products == null ? const CircularProgressIndicator() : const Text('Không tìm thấy sản phẩm'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            tooltip: 'Sửa',
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/products/${p.id}/edit'),
          ),
          IconButton(tooltip: 'Xoá', icon: const Icon(Icons.delete), onPressed: () => _delete(context, ref, p)),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: LayoutBuilder(builder: (_, c) => ProductImage(p.imageUrl, size: c.maxWidth)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  money(p.price),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(p.description),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Thêm vào giỏ hàng'),
            onPressed: () {
              ref.read(cartProvider.notifier).add(p);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm "${p.name}" vào giỏ')));
            },
          ),
        ),
      ),
    );
  }
}
