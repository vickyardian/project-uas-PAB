import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Method untuk menghitung total harga item
  double get totalPrice {
    // Ambil harga dari string dan convert ke double
    String priceString = product.price
        .replaceAll('Rp ', '')
        .replaceAll('.', '');
    double price = double.tryParse(priceString) ?? 0.0;
    return price * quantity;
  }

  // Method untuk copy dengan quantity baru
  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.product.name == product.name;
  }

  @override
  int get hashCode => product.name.hashCode;
}
