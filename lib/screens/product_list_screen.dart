import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../ui.dart';

enum PriceSort { none, asc, desc }

/// Search by name, then sort by price. Pure function so it is easy to test.
List<Product> filterAndSort(List<Product> all, String query, PriceSort sort) {
  final q = query.trim().toLowerCase();
  final list = all.where((p) => p.name.toLowerCase().contains(q)).toList();
  if (sort == PriceSort.asc) list.sort((a, b) => a.price.compareTo(b.price));
  if (sort == PriceSort.desc) list.sort((a, b) => b.price.compareTo(a.price));
  return list;
}

/// VND, e.g. 1250000 -> "1.250.000 ₫".
String money(double v) => '${v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => '.')} ₫';

class ProductImage extends StatelessWidget {
  final String? url;

  /// null = fill the parent.
  final double? size;
  const ProductImage(this.url, {super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final w = size ?? double.infinity;
    final placeholder = Container(
      width: w,
      height: w,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.pink.shade50])),
      child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
    );
    if (url == null || url!.isEmpty) return placeholder;
    // Picked images are stored as local file paths, URLs start with http.
    return url!.startsWith('http')
        ? Image.network(url!, width: w, height: w, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder)
        : Image.file(File(url!), width: w, height: w, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
  }
}

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _query = '';
  PriceSort _sort = PriceSort.none;

  void _addToCart(Product p) {
    ref.read(cartProvider.notifier).add(p);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('🛒 Đã thêm "${p.name}" vào giỏ')));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) await ref.read(authProvider.notifier).logout();
  }

  Widget _headerButton(String tooltip, Widget icon, VoidCallback onPressed) => IconButton(
    tooltip: tooltip,
    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
    color: Colors.white,
    icon: icon,
    onPressed: onPressed,
  );

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cartCount = ref.watch(cartProvider).fold<int>(0, (s, c) => s + c.quantity);
    final user = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: brandGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Xin chào 👋', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                              Text(
                                user?.fullName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _headerButton('Doanh thu', const Icon(Icons.bar_chart_rounded), () => context.push('/revenue')),
                        const SizedBox(width: 6),
                        _headerButton(
                          'Giỏ hàng',
                          Badge(
                            isLabelVisible: cartCount > 0,
                            label: Text('$cartCount'),
                            backgroundColor: Colors.amber,
                            textColor: Colors.black,
                            child: const Icon(Icons.shopping_cart_rounded),
                          ),
                          () => context.push('/cart'),
                        ),
                        const SizedBox(width: 6),
                        _headerButton('Đăng xuất', const Icon(Icons.logout_rounded), _logout),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Tìm theo tên...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                for (final (s, label, icon) in const [
                  (PriceSort.none, 'Mặc định', Icons.auto_awesome),
                  (PriceSort.asc, 'Giá tăng dần', Icons.arrow_upward),
                  (PriceSort.desc, 'Giá giảm dần', Icons.arrow_downward),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(icon, size: 16),
                      label: Text(label),
                      selected: _sort == s,
                      onSelected: (_) => setState(() => _sort = s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi tải sản phẩm: $e')),
              data: (all) {
                final list = filterAndSort(all, _query, _sort);
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 72,
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(all.isEmpty ? 'Chưa có sản phẩm. Nhấn + để thêm.' : 'Không tìm thấy sản phẩm'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: list.length,
                  itemBuilder: (_, i) => FadeSlideIn(
                    key: ValueKey(list[i].id),
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProductCard(list[i], onAdd: () => _addToCart(list[i])),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product p;
  final VoidCallback onAdd;
  const _ProductCard(this.p, {required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () => context.push('/products/${p.id}'),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 116,
              child: Hero(tag: 'product-${p.id}', child: ProductImage(p.imageUrl, size: null)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      p.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            money(p.price),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Material(
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: Ink(
                            decoration: const BoxDecoration(gradient: brandGradient),
                            child: IconButton(
                              tooltip: 'Thêm vào giỏ',
                              color: Colors.white,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_shopping_cart, size: 20),
                              onPressed: onAdd,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
