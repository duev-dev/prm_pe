import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/providers.dart';
import 'screens/cart_screen.dart';
import 'screens/login_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/revenue_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirect when login state changes, without rebuilding the router.
  final authChanged = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => authChanged.value++);
  ref.onDispose(authChanged.dispose);

  return GoRouter(
    initialLocation: '/products',
    refreshListenable: authChanged,
    redirect: (_, state) {
      final loggedIn = ref.read(authProvider) != null;
      final onAuthPage = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (!loggedIn) return onAuthPage ? null : '/login';
      return onAuthPage ? '/products' : null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/products',
        builder: (_, _) => const ProductListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const ProductFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, s) => ProductDetailScreen(productId: int.parse(s.pathParameters['id']!)),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, s) => ProductFormScreen(productId: int.parse(s.pathParameters['id']!)),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
      GoRoute(path: '/revenue', builder: (_, _) => const RevenueScreen()),
    ],
  );
});
