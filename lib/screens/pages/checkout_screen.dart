import 'package:flutter/material.dart';
import 'package:roti_nyaman/models/cart.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Cart> cartItems;
  final Map<String, int> productStock;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.productStock,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  double get _totalPrice {
    return widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  Future<void> _placeOrder() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk membuat pesanan.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil fungsi dengan argumen yang benar
      await _firestoreService.createOrdersFromCart(
        _currentUser.uid,
        widget.cartItems as Map<String, int>, // Ini adalah List<Cart>
        widget.productStock
            .cast<String, Product>(), // Ini adalah Map<String, int>
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Ringkasan Pesanan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...widget.cartItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      item.productImage != null && item.productImage!.isNotEmpty
                          ? Image.network(
                            item.productImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.shopping_bag, size: 50),
                ),
                title: Text(item.productName),
                subtitle: Text(
                  '${item.quantity} x ${_formatCurrency(item.productPrice)}',
                ),
                trailing: Text(
                  _formatCurrency(item.totalPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
          const Divider(height: 32),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatCurrency(_totalPrice),
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
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text('Konfirmasi Pesanan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
