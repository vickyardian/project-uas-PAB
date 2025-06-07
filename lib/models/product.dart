class Product {
  final String id;
  final String name;
  final String price;
  final String image;
  final String description;
  final int stock;
  final String category;
  late final bool isLiked; // Tambahkan sebagai field final

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.stock,
    required this.category,
    this.isLiked = false, // Default value false
  });

  // Method untuk membuat copy dari Product
  Product copyWith({
    String? id,
    String? name,
    String? price,
    String? image,
    String? description,
    int? stock,
    String? category,
    bool? isLiked,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  // Method untuk konversi ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'stock': stock,
      'category': category,
      'isLiked': isLiked,
    };
  }

  // Method untuk membuat Product dari Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '0',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      image: map['image'] ?? '',
      description: map['description'] ?? '',
      stock: map['stock'] ?? 0,
      category: map['category'] ?? '',
      isLiked: map['isLiked'] ?? false,
    );
  }

  // Method untuk parsing harga dari string ke double
  double get priceAsDouble {
    String priceStr = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(priceStr) ?? 0;
  }

  // Method untuk format harga dengan titik sebagai pemisah ribuan
  String get formattedPrice {
    double priceValue = priceAsDouble;
    return 'Rp ${priceValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Method untuk cek apakah produk tersedia
  bool get isAvailable => stock > 0;

  // Method untuk toggle like status
  Product toggleLike() {
    return copyWith(isLiked: !isLiked);
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock, isLiked: $isLiked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.image == image &&
        other.description == description &&
        other.stock == stock &&
        other.category == category &&
        other.isLiked == isLiked;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        price.hashCode ^
        image.hashCode ^
        description.hashCode ^
        stock.hashCode ^
        category.hashCode ^
        isLiked.hashCode;
  }
}
