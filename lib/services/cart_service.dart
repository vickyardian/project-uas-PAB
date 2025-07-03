import 'package:flutter/material.dart';
import 'package:roti_nyaman/models/product.dart'; // [SUDAH DIPERBAIKI] Menggunakan model/product.dart

class CartService with ChangeNotifier {
  // Variabel privat untuk menyimpan daftar produk di keranjang.
  final List<Product> _cartItems =
      []; // [SUDAH DIPERBAIKI] Menggunakan kelas Product

  // Getter publik untuk mendapatkan daftar produk di keranjang.
  List<Product> get cartItems => _cartItems;

  // Getter untuk menghitung jumlah total item di keranjang.
  int get totalItems => _cartItems.length;

  // Getter untuk menghitung total harga dari semua item di keranjang.
  double get totalPrice {
    return _cartItems.fold(0, (total, current) => total + current.price);
  }

  /// Menambahkan produk ke dalam keranjang.
  void addToCart(Product product) {
    // [SUDAH DIPERBAIKI] Menggunakan kelas Product
    _cartItems.add(product);
    // Memberi tahu semua widget yang "mendengarkan" bahwa ada perubahan.
    notifyListeners();
  }

  /// Menghapus produk dari keranjang.
  void removeFromCart(Product product) {
    // [SUDAH DIPERBAIKI] Menggunakan kelas Product
    _cartItems.remove(product);
    notifyListeners();
  }

  /// Mengosongkan semua isi keranjang.
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
