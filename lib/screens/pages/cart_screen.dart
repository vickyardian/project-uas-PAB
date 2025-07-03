import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roti_nyaman/models/cart.dart';

class CartScreen extends StatefulWidget {
  final List<Cart> cartItems;
  final Function(List<Cart>) onCartUpdated;
  final String userId;
  final Map<String, int> productStock;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onCartUpdated,
    required this.userId,
    required this.productStock,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Gunakan state lokal untuk mengelola item keranjang di halaman ini
  late List<Cart> localCartItems;

  @override
  void initState() {
    super.initState();
    // Salin item dari widget ke state lokal agar bisa diubah
    localCartItems = List<Cart>.from(widget.cartItems);
  }

  // [PERBAIKAN UTAMA] Tambahkan didUpdateWidget untuk sinkronisasi data
  @override
  void didUpdateWidget(covariant CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cek jika data dari parent (HomeScreen) berubah, perbarui state lokal
    if (widget.cartItems != oldWidget.cartItems) {
      setState(() {
        localCartItems = List<Cart>.from(widget.cartItems);
      });
    }
  }

  // Fungsi ini dipanggil setiap kali ada perubahan di state lokal
  void _updateParent() {
    widget.onCartUpdated(localCartItems);
  }

  void _updateQuantity(String cartId, int newQuantity) {
    final cartIndex = localCartItems.indexWhere((item) => item.id == cartId);
    if (cartIndex == -1) return;

    final cartItem = localCartItems[cartIndex];
    // Ambil stok maksimal dari data yang di-pass oleh HomeScreen
    final maxStock = widget.productStock[cartItem.productId] ?? 0;

    if (newQuantity > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok ${cartItem.productName} hanya tersedia $maxStock item',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      if (newQuantity <= 0) {
        // Hapus item jika kuantitasnya 0 atau kurang
        localCartItems.removeAt(cartIndex);
      } else {
        // Update kuantitas jika masih valid
        localCartItems[cartIndex] = cartItem.copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );
      }
    });
    // Kirim perubahan kembali ke HomeScreen
    _updateParent();
  }

  void _removeItem(String cartId) {
    setState(() {
      localCartItems.removeWhere((item) => item.id == cartId);
    });
    // Kirim perubahan kembali ke HomeScreen
    _updateParent();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item dihapus dari keranjang'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ignore: unused_element
  void _clearCart() {
    setState(() {
      localCartItems.clear();
    });
    _updateParent();
  }

  double _getTotalPrice() {
    return localCartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (localCartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Keranjang Anda Kosong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: localCartItems.length,
            itemBuilder: (context, index) {
              final cartItem = localCartItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Placeholder untuk gambar, bisa disesuaikan
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            cartItem.productImage != null &&
                                    cartItem.productImage!.isNotEmpty
                                ? Image.network(
                                  cartItem.productImage!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (ctx, err, st) => const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                      ),
                                )
                                : const Icon(
                                  Icons.shopping_bag,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cartItem.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_formatCurrency(cartItem.productPrice)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _updateQuantity(
                                        cartItem.id,
                                        cartItem.quantity - 1,
                                      ),
                                ),
                                Text(
                                  '${cartItem.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                      () => _updateQuantity(
                                        cartItem.id,
                                        cartItem.quantity + 1,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(cartItem.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bagian Total dan Checkout
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Harga:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatCurrency(_getTotalPrice()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logika checkout
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Lanjut ke Checkout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
