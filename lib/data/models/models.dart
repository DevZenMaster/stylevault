// ─── USER MODEL ───────────────────────────────────────────────
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String photoUrl;
  final String role; // 'user' or 'admin'

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.photoUrl = '',
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'photoUrl': photoUrl,
    'role': role,
  };

  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? photoUrl,
    String? role,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
    );
  }
}


// ─── PRODUCT MODEL ─────────────────────────────────────────────
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final int stock;
  final List<String> sizes;
  final List<String> colors;
  final bool isFeatured;
  final double rating;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.stock,
    this.sizes = const [],
    this.colors = const [],
    this.isFeatured = false,
    this.rating = 4.0,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      stock: map['stock'] ?? 0,
      sizes: List<String>.from(map['sizes'] ?? []),
      colors: List<String>.from(map['colors'] ?? []),
      isFeatured: map['isFeatured'] ?? false,
      rating: (map['rating'] ?? 4.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'imageUrl': imageUrl,
    'stock': stock,
    'sizes': sizes,
    'colors': colors,
    'isFeatured': isFeatured,
    'rating': rating,
  };
}


// ─── CART ITEM MODEL ───────────────────────────────────────────
class CartItemModel {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  final String size;
  final String color;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.size = '',
    this.color = '',
  });

  double get totalPrice => price * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map, String id) {
    return CartItemModel(
      id: id,
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      size: map['size'] ?? '',
      color: map['color'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'size': size,
    'color': color,
  };
}


// ─── ORDER MODEL ───────────────────────────────────────────────
class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double total;
  final String status;
  final String address;
  final String phone;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.address,
    required this.phone,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>? ?? [])
        .map((item) => CartItemModel.fromMap(
            item as Map<String, dynamic>, item['productId'] ?? ''))
        .toList();

    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: itemsList,
      total: (map['total'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      createdAt:
          (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'items': items.map((e) => e.toMap()).toList(),
    'total': total,
    'status': status,
    'address': address,
    'phone': phone,
    'createdAt': createdAt,
  };
}