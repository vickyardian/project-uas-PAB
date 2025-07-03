import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final int stock;
  final String? imageUrl;
  final bool isLiked;
  final bool isBestSeller;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.stock,
    this.imageUrl,
    this.isLiked = false,
    this.isBestSeller = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String? get image => imageUrl;

  // [PERBAIKAN UTAMA ADA DI SINI]
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Fungsi bantu untuk mengubah berbagai tipe data menjadi boolean secara aman
    bool boolFrom(dynamic value, {bool defaultValue = false}) {
      if (value is bool) return value;
      if (value is num)
        return value != 0; // Angka 0 dianggap false, selain itu true
      if (value is String) return value.toLowerCase() == 'true';
      return defaultValue; // Nilai default jika tipe tidak dikenali atau null
    }

    // Fungsi bantu untuk mengubah harga menjadi double secara aman
    double doubleFrom(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(
              value
                  .replaceAll('Rp', '')
                  .replaceAll('.', '')
                  .replaceAll(',', '.'),
            ) ??
            0.0;
      }
      return 0.0;
    }

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: doubleFrom(data['price']), // Menggunakan fungsi bantu
      categoryId: data['categoryId'] ?? '',
      stock: (data['stock'] ?? 0).toInt(),
      imageUrl: data['imageUrl'] ?? data['image'],

      // Menggunakan fungsi bantu untuk konversi boolean yang aman
      isLiked: boolFrom(data['isLiked'], defaultValue: false),
      isBestSeller: boolFrom(data['isBestSeller'], defaultValue: false),
      isActive: boolFrom(data['isActive'], defaultValue: true),

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
      'imageUrl': imageUrl,
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
