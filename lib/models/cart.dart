//models/cart.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Cart {
  final String id;
  final String userId; // Added to link cart to specific user
  final String productId;
  final String productName; // Changed from 'name' to match other models
  final double productPrice; // Changed from 'price' to match other models
  final String? productImage; // Changed from 'image' to match other models
  final int quantity;
  final DateTime createdAt; // Changed from Timestamp to DateTime for consistency
  final DateTime? updatedAt; // Changed from Timestamp to DateTime for consistency

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

  // Getters for backward compatibility
  String get name => productName;
  double get price => productPrice;
  String? get image => productImage;
  DateTime get timestamp => updatedAt ?? createdAt;

  // Calculate total price for this cart item
  double get totalPrice => productPrice * quantity;

  factory Cart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Cart(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? data['name'] ?? '', // Support both field names
      productPrice: (data['productPrice'] ?? data['price'] is String 
          ? double.parse((data['productPrice'] ?? data['price']).toString().replaceAll('Rp ', '').replaceAll('.', '').replaceAll(',', '.'))
          : (data['productPrice'] ?? data['price'] ?? 0.0)).toDouble(),
      productImage: data['productImage'] ?? data['image'], // Support both field names
      quantity: data['quantity'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName, // Changed to match field name
      'name': productName, // Keep for backward compatibility
      'productPrice': productPrice, // Changed to match field name
      'price': productPrice, // Keep for backward compatibility
      'productImage': productImage, // Changed to match field name
      'image': productImage, // Keep for backward compatibility
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
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