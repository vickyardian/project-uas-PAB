import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/services/firestore_service.dart';
import 'package:roti_nyaman/auth/login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isGuest;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.isGuest = false,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLiked = false;
  int _quantity = 1;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Inisialisasi status 'like' dari data produk
    _isLiked = widget.product.isLiked;
  }

  // Fungsi untuk mengubah status suka (like)
  Future<void> _toggleLike() async {
    if (widget.isGuest) {
      _showGuestDialog();
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
    });

    try {
      // Panggil service untuk update ke Firestore
      // Pastikan Anda memiliki fungsi ini di firestore_service.dart
      await _firestoreService.updateLikeStatus(widget.product.id, _isLiked);
    } catch (e) {
      // Jika gagal, kembalikan state seperti semula
      setState(() {
        _isLiked = !_isLiked;
      });
      _showErrorMessage('Gagal memperbarui status suka: $e');
    }
  }

  // Fungsi untuk menambahkan produk ke keranjang
  Future<void> _addToCart() async {
    if (_isLoading) return;

    if (widget.isGuest) {
      _showGuestDialog();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (_quantity > widget.product.stock) {
      _showErrorMessage('Jumlah melebihi stok yang tersedia');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.updateCartItem(
        user.uid,
        widget.product,
        _quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.product.name} ($_quantity) ditambahkan ke keranjang',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Gagal menambahkan ke keranjang: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk menampilkan dialog jika pengguna adalah tamu
  void _showGuestDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mode Tamu'),
            content: const Text('Silakan login untuk menggunakan fitur ini.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          ),
    );
  }

  // Fungsi untuk menampilkan pesan error
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar sekarang lebih simpel tanpa actions
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.lightBlueAccent,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child:
                  widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? Image.network(
                        widget.product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
            ),

            // Detail Produk
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris untuk Nama Produk dan Ikon Love
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey[600],
                          size: 32,
                        ),
                        onPressed: _toggleLike,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Harga Produk
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 22,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status Stok
                  Row(
                    children: [
                      Icon(
                        widget.product.stock > 0
                            ? Icons.check_circle
                            : Icons.cancel,
                        color:
                            widget.product.stock > 0
                                ? Colors.green
                                : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.product.stock > 0
                            ? 'Stok tersedia: ${widget.product.stock}'
                            : 'Stok habis',
                        style: TextStyle(
                          color:
                              widget.product.stock > 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Deskripsi
                  Text(
                    'Deskripsi Produk',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bagian Bawah untuk Tombol Aksi
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Pemilih Kuantitas
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                  color: Theme.of(context).primaryColor,
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed:
                      _quantity < widget.product.stock
                          ? () => setState(() => _quantity++)
                          : null,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),

            // Tombol Tambah ke Keranjang
            ElevatedButton.icon(
              onPressed:
                  widget.product.stock > 0 && !_isLoading ? _addToCart : null,
              icon:
                  _isLoading
                      ? Container(
                        width: 20,
                        height: 20,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                      : const Icon(Icons.add_shopping_cart),
              label: Text(widget.product.stock > 0 ? 'Tambah' : 'Habis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
