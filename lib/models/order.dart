//models/order.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final double productPrice;
  final String? productImage;
  final int quantity;
  final double total;
  final String status; // 'pending', 'processing', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? lastUpdated; // Added for admin updates

  Order({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.productImage,
    required this.quantity,
    required this.total,
    required this.status,
    required this.createdAt,
    this.lastUpdated,
  });

  // Getter for backward compatibility with service
  DateTime get timestamp => createdAt;

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? data['name'] ?? '', // Support both field names
      productPrice: (data['productPrice'] ?? data['price'] is String 
          ? double.parse((data['productPrice'] ?? data['price']).toString().replaceAll('Rp ', '').replaceAll('.', '').replaceAll(',', '.'))
          : (data['productPrice'] ?? data['price'] ?? 0.0)).toDouble(),
      productImage: data['productImage'] ?? data['image'], // Support both field names
      quantity: data['quantity'] ?? 0,
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] ?? data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(), // Support both field names
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
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
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt), // Changed to match field name
      'timestamp': Timestamp.fromDate(createdAt), // Keep for backward compatibility
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? productId,
    String? productName,
    double? productPrice,
    String? productImage,
    int? quantity,
    double? total,
    String? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}