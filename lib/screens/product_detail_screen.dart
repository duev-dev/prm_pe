import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../ui.dart';
import 'product_list_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  Future<void> _delete(BuildContext context, WidgetRef ref, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 40),
        title: const Text('Xoá sản phẩm?'),
        content: Text('Bạn chắc chắn muốn xoá "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
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

    final theme = Theme.of(context);
    final circle = IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.9));
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton(style: circle, icon: const BackButtonIcon(), onPressed: () => context.pop()),
            ),
            actions: [
              IconButton(
                style: circle,
                tooltip: 'Sửa',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/products/${p.id}/edit'),
              ),
              const SizedBox(width: 6),
              IconButton(
                style: circle,
                tooltip: 'Xoá',
                color: Colors.redAccent,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref, p),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(tag: 'product-${p.id}', child: ProductImage(p.imageUrl, size: null)),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(30)),
                      child: Text(
                        money(p.price),
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Mô tả', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      p.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButton(
            icon: Icons.add_shopping_cart,
            label: 'Thêm vào giỏ hàng',
            onPressed: () {
              ref.read(cartProvider.notifier).add(p);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('🛒 Đã thêm "${p.name}" vào giỏ')));
            },
          ),
        ),
      ),
    );
  }
}
