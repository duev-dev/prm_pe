import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../models/models.dart';

const rememberKey = 'remember_user_id';

/// User restored from "Remember Me" at startup; overridden in main().
final initialUserProvider = Provider<AppUser?>((_) => null);

// ---------------- auth ----------------
class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => ref.read(initialUserProvider);

  /// Returns null on success, or an error message.
  Future<String?> login(String email, String password, {required bool remember}) async {
    final user = await AppDatabase.instance.login(email, password);
    if (user == null) return 'Email hoặc mật khẩu không đúng';
    final prefs = await SharedPreferences.getInstance();
    remember ? await prefs.setInt(rememberKey, user.id) : await prefs.remove(rememberKey);
    state = user;
    return null;
  }

  Future<void> logout() async {
    await (await SharedPreferences.getInstance()).remove(rememberKey);
    ref.read(cartProvider.notifier).clear();
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

// ---------------- products ----------------
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  final _db = AppDatabase.instance;

  @override
  Future<List<Product>> build() => _db.products();

  Future<void> add(Product p) async {
    await _db.insertProduct(p);
    ref.invalidateSelf();
  }

  Future<void> edit(Product p) async {
    await _db.updateProduct(p);
    ref.read(cartProvider.notifier).syncProduct(p);
    ref.invalidateSelf();
  }

  Future<void> remove(int id) async {
    await _db.deleteProduct(id);
    ref.read(cartProvider.notifier).remove(id);
    ref.invalidateSelf();
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(ProductsNotifier.new);

// ---------------- cart ----------------
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  double get total => state.fold(0, (sum, i) => sum + i.total);

  void add(Product p) {
    final i = state.indexWhere((c) => c.product.id == p.id);
    state = i < 0
        ? [...state, CartItem(p, 1)]
        : [for (final c in state) c.product.id == p.id ? CartItem(c.product, c.quantity + 1) : c];
  }

  /// Quantity <= 0 removes the item.
  void setQuantity(int productId, int qty) => state = [
    for (final c in state)
      if (c.product.id != productId) c else if (qty > 0) CartItem(c.product, qty),
  ];

  void remove(int productId) => setQuantity(productId, 0);

  void syncProduct(Product p) => state = [for (final c in state) c.product.id == p.id ? CartItem(p, c.quantity) : c];

  void clear() => state = const [];

  Future<void> checkout() async {
    if (state.isEmpty) return;
    await AppDatabase.instance.insertOrder(total);
    clear();
    ref.invalidate(ordersProvider);
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

// ---------------- orders ----------------
final ordersProvider = FutureProvider<List<Order>>((_) => AppDatabase.instance.orders());
