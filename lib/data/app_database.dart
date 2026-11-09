import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Single SQLite access point for users, products and orders.
class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'prm_shop.db'),
    version: 1,
    onCreate: (db, _) async {
      await db.execute('''CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            price REAL NOT NULL,
            image_url TEXT)''');
      await db.execute('''CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            total REAL NOT NULL,
            created_at TEXT NOT NULL)''');
    },
  );

  static String hash(String password) => sha256.convert(utf8.encode(password)).toString();

  // ---- users ----
  /// Returns false when the email is already registered.
  Future<bool> register(String fullName, String email, String password) async {
    try {
      await (await db).insert('users', {
        'full_name': fullName,
        'email': email.toLowerCase(),
        'password_hash': hash(password),
      });
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  Future<AppUser?> login(String email, String password) async {
    final rows = await (await db).query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.toLowerCase(), hash(password)],
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> userById(int id) async {
    final rows = await (await db).query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  // ---- products ----
  Future<List<Product>> products() async =>
      (await (await db).query('products', orderBy: 'id DESC')).map(Product.fromMap).toList();

  Future<void> insertProduct(Product p) async => (await db).insert('products', p.toMap());

  Future<void> updateProduct(Product p) async =>
      (await db).update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);

  Future<void> deleteProduct(int id) async => (await db).delete('products', where: 'id = ?', whereArgs: [id]);

  // ---- orders ----
  Future<void> insertOrder(double total) async =>
      (await db).insert('orders', {'total': total, 'created_at': DateTime.now().toIso8601String()});

  Future<List<Order>> orders() async =>
      (await (await db).query('orders', orderBy: 'created_at DESC')).map(Order.fromMap).toList();
}
