import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';

enum PriceSort { none, asc, desc }

/// Search by name, then sort by price. Pure function so it is easy to test.
List<Product> filterAndSort(List<Product> all, String query, PriceSort sort) {
  final q = query.trim().toLowerCase();
  final list = all.where((p) => p.name.toLowerCase().contains(q)).toList();
  if (sort == PriceSort.asc) list.sort((a, b) => a.price.compareTo(b.price));
  if (sort == PriceSort.desc) list.sort((a, b) => b.price.compareTo(a.price));
  return list;
}

String money(double v) => '\$${v.toStringAsFixed(2)}';

class ProductImage extends StatelessWidget {
  final String? url;
  final double size;
  const ProductImage(this.url, {super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(url!, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder);
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
      ..showSnackBar(SnackBar(content: Text('Đã thêm "${p.name}" vào giỏ')));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final cartCount = ref.watch(cartProvider).fold<int>(0, (s, c) => s + c.quantity);
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Xin chào, ${user?.fullName ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Doanh thu',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/revenue'),
          ),
          IconButton(
            tooltip: 'Giỏ hàng',
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(tooltip: 'Đăng xuất', icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tên...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<PriceSort>(
                  tooltip: 'Sắp xếp theo giá',
                  icon: const Icon(Icons.sort),
                  initialValue: _sort,
                  onSelected: (s) => setState(() => _sort = s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: PriceSort.none, child: Text('Mặc định')),
                    PopupMenuItem(value: PriceSort.asc, child: Text('Giá tăng dần')),
                    PopupMenuItem(value: PriceSort.desc, child: Text('Giá giảm dần')),
                  ],
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
                    child: Text(all.isEmpty ? 'Chưa có sản phẩm. Nhấn + để thêm.' : 'Không tìm thấy sản phẩm'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductImage(p.imageUrl, size: 56),
                        ),
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${p.description}\n${money(p.price)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Thêm vào giỏ',
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () => _addToCart(p),
                        ),
                        onTap: () => context.push('/products/${p.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
