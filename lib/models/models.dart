class AppUser {
  final int id;
  final String fullName;
  final String email;
  const AppUser({required this.id, required this.fullName, required this.email});

  factory AppUser.fromMap(Map<String, Object?> m) =>
      AppUser(id: m['id'] as int, fullName: m['full_name'] as String, email: m['email'] as String);
}

class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  const Product({this.id, required this.name, required this.description, required this.price, this.imageUrl});

  factory Product.fromMap(Map<String, Object?> m) => Product(
    id: m['id'] as int,
    name: m['name'] as String,
    description: m['description'] as String,
    price: (m['price'] as num).toDouble(),
    imageUrl: m['image_url'] as String?,
  );

  Map<String, Object?> toMap() => {'name': name, 'description': description, 'price': price, 'image_url': imageUrl};
}

class CartItem {
  final Product product;
  final int quantity;
  const CartItem(this.product, this.quantity);
  double get total => product.price * quantity;
}

class Order {
  final int id;
  final double total;
  final DateTime createdAt;
  const Order({required this.id, required this.total, required this.createdAt});

  factory Order.fromMap(Map<String, Object?> m) => Order(
    id: m['id'] as int,
    total: (m['total'] as num).toDouble(),
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}
