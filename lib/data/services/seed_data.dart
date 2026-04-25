// ============================================================
// FIRESTORE SEED DATA — Run this ONCE to populate products
// Add this to a temporary screen or run via Firebase console
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> seedFirestore() async {
  final db = FirebaseFirestore.instance;
  final products = [
    {
      'name': 'Slim Fit Oxford Shirt',
      'description': 'A crisp Oxford shirt with a slim, tailored fit. Perfect for smart-casual occasions.',
      'price': 4500,
      'category': 'Men',
      'imageUrl': 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800',
      'stock': 50,
      'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
      'colors': ['White', 'Blue', 'Black'],
      'isFeatured': true,
      'rating': 4.5,
    },
    {
      'name': 'Pleated Midi Dress',
      'description': 'Elegant pleated midi dress with a flowy silhouette. Ideal for any season.',
      'price': 7800,
      'category': 'Women',
      'imageUrl': 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=800',
      'stock': 30,
      'sizes': ['XS', 'S', 'M', 'L'],
      'colors': ['Sage', 'Dusty Rose', 'Cream'],
      'isFeatured': true,
      'rating': 4.7,
    },
    {
      'name': 'Classic Leather Belt',
      'description': 'Full-grain leather belt with a brushed silver buckle. A wardrobe essential.',
      'price': 2200,
      'category': 'Accessories',
      'imageUrl': 'https://images.unsplash.com/photo-1624222247344-550fb60583dc?w=800',
      'stock': 100,
      'sizes': ['S', 'M', 'L'],
      'colors': ['Black', 'Tan'],
      'isFeatured': false,
      'rating': 4.3,
    },
    {
      'name': 'Suede Chelsea Boots',
      'description': 'Handcrafted suede Chelsea boots with elastic side panels and a stacked heel.',
      'price': 14500,
      'category': 'Footwear',
      'imageUrl': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
      'stock': 20,
      'sizes': ['40', '41', '42', '43', '44', '45'],
      'colors': ['Camel', 'Black'],
      'isFeatured': true,
      'rating': 4.8,
    },
    {
      'name': 'Kids Denim Jacket',
      'description': 'Durable and stylish denim jacket for kids, with brass button details.',
      'price': 3200,
      'category': 'Kids',
      'imageUrl': 'https://images.unsplash.com/photo-1503919545889-aef636e10ad4?w=800',
      'stock': 40,
      'sizes': ['2T', '3T', '4T', '5', '6', '7'],
      'colors': ['Blue', 'Light Blue'],
      'isFeatured': false,
      'rating': 4.4,
    },
    {
      'name': 'Performance Running Tee',
      'description': 'Moisture-wicking running tee with a four-way stretch for full range of motion.',
      'price': 2800,
      'category': 'Sports',
      'imageUrl': 'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=800',
      'stock': 60,
      'sizes': ['S', 'M', 'L', 'XL'],
      'colors': ['Black', 'White', 'Navy'],
      'isFeatured': false,
      'rating': 4.2,
    },
    {
      'name': 'High-Rise Tailored Trousers',
      'description': 'Elevated high-rise trousers in a comfortable stretch fabric with a straight leg.',
      'price': 6500,
      'category': 'Women',
      'imageUrl': 'https://images.unsplash.com/photo-1594938298603-c8148c4b984a?w=800',
      'stock': 35,
      'sizes': ['XS', 'S', 'M', 'L', 'XL'],
      'colors': ['Charcoal', 'Ecru', 'Black'],
      'isFeatured': true,
      'rating': 4.6,
    },
    {
      'name': 'Silk Scarf',
      'description': 'Luxurious 100% silk scarf with an artisan print. Versatile and timeless.',
      'price': 3800,
      'category': 'Accessories',
      'imageUrl': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800',
      'stock': 45,
      'sizes': [],
      'colors': ['Floral', 'Abstract', 'Striped'],
      'isFeatured': false,
      'rating': 4.5,
    },
  ];

  final batch = db.batch();
  for (final product in products) {
    final ref = db.collection('products').doc();
    batch.set(ref, {
      ...product,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  debugPrint('✅ Seeded ${products.length} products to Firestore!');
}
