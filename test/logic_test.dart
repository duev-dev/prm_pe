import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_shop/models/models.dart';
import 'package:prm_shop/providers/providers.dart';
import 'package:prm_shop/screens/product_list_screen.dart';
import 'package:prm_shop/screens/revenue_screen.dart';
import 'package:prm_shop/screens/validators.dart';

const a = Product(id: 1, name: 'Apple', description: '', price: 3);
const b = Product(id: 2, name: 'Banana', description: '', price: 1);
const c = Product(id: 3, name: 'Pineapple', description: '', price: 2);

void main() {
  test('search is case-insensitive and sort by price works', () {
    expect(filterAndSort([a, b, c], 'APPLE', PriceSort.asc).map((p) => p.id), [3, 1]);
    expect(filterAndSort([a, b, c], '', PriceSort.desc).map((p) => p.id), [1, 3, 2]);
  });

  test('cart add / quantity / remove / total', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);
    cart
      ..add(a)
      ..add(a)
      ..add(b);
    expect(cart.total, 7);
    cart.setQuantity(1, 5);
    expect(cart.total, 16);
    cart.setQuantity(2, 0);
    expect(container.read(cartProvider).length, 1);
  });

  test('revenue period filter', () {
    final now = DateTime(2026, 11, 5, 10);
    final orders = [
      Order(id: 1, total: 10, createdAt: DateTime(2026, 11, 5, 8)),
      Order(id: 2, total: 20, createdAt: DateTime(2026, 11, 1)),
      Order(id: 3, total: 30, createdAt: DateTime(2026, 1, 1)),
      Order(id: 4, total: 40, createdAt: DateTime(2025, 11, 5)),
    ];
    expect(ordersInPeriod(orders, RevenuePeriod.day, now).length, 1);
    expect(ordersInPeriod(orders, RevenuePeriod.month, now).length, 2);
    expect(ordersInPeriod(orders, RevenuePeriod.year, now).length, 3);
    expect(ordersInPeriod(orders, RevenuePeriod.all, now).length, 4);
  });

  test('money formats VND with dot separators', () {
    expect(money(1250000), '1.250.000 ₫');
    expect(money(999), '999 ₫');
    expect(money(1000.4), '1.000 ₫');
  });

  test('validators', () {
    expect(validateEmail('a@b.com'), isNull);
    expect(validateEmail('a@b'), isNotNull);
    expect(validatePrice('-1'), isNotNull);
    expect(validatePrice('9.5'), isNull);
  });
}
