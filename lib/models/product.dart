//models/product.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final int stock;
  final String? imageUrl; // Changed to match service usage (imageUrl)
  final bool isLiked;
  final bool isBestSeller;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt; // Changed to optional for consistency

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.stock,
    this.imageUrl, // Changed to match service
    this.isLiked = false,
    this.isBestSeller = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Getter for backward compatibility
  String? get image => imageUrl;

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is String 
          ? double.parse(data['price'].replaceAll('Rp ', '').replaceAll('.', '').replaceAll(',', '.'))
          : (data['price'] ?? 0.0)).toDouble(),
      categoryId: data['categoryId'] ?? '',
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'] ?? data['image'], // Support both field names
      isLiked: data['isLiked'] ?? false,
      isBestSeller: data['isBestSeller'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'stock': stock,
      'imageUrl': imageUrl, // Changed to match service
      'isLiked': isLiked,
      'isBestSeller': isBestSeller,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    int? stock,
    String? imageUrl,
    bool? isLiked,
    bool? isBestSeller,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      isLiked: isLiked ?? this.isLiked,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
