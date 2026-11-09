import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_database.dart';
import 'providers/providers.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final rememberedId = (await SharedPreferences.getInstance()).getInt(rememberKey);
  final user = rememberedId == null ? null : await AppDatabase.instance.userById(rememberedId);

  runApp(ProviderScope(overrides: [initialUserProvider.overrideWithValue(user)], child: const ShopApp()));
}

class ShopApp extends ConsumerWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PRM Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
