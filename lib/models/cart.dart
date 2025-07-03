import 'package:cloud_firestore/cloud_firestore.dart';

class Cart {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double productPrice;
  final String? productImage;
  final int quantity;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    required this.quantity,
    required this.createdAt,
    this.updatedAt,
  });

  // Getter untuk menghitung subtotal per item
  double get totalPrice => productPrice * quantity;

  // [PERBAIKAN UTAMA ADA DI SINI]
  factory Cart.fromFirestore(DocumentSnapshot doc) {
    final data =
        doc.data() as Map<String, dynamic>? ?? {}; // Lebih aman jika data null

    // Fungsi bantu untuk konversi aman
    double doubleFrom(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return 0.0;
    }

    int intFrom(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return 0;
    }

    return Cart(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',

      // Menggunakan fungsi bantu yang aman
      productPrice: doubleFrom(data['productPrice']),
      quantity: intFrom(data['quantity']),

      productImage: data['productImage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImage': productImage,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Cart copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    double? productPrice,
    String? productImage,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
