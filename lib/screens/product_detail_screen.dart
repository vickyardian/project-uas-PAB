import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/services/firestore_service.dart';
import '../auth/login_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isGuest;
  final Function(Product, int)? onAddToCart; // BARU: Callback dengan quantity

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.isGuest = false,
    this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLiked = false;
  int _quantity = 1;
  bool _isLoading = false; // BARU: Loading state

  @override
  void initState() {
    super.initState();
    _isLiked = widget.product.isLiked;
  }

  Future<void> _toggleLike() async {
    if (widget.isGuest) {
      _showGuestDialog();
      return;
    }
    
    setState(() {
      _isLiked = !_isLiked;
    });
    
    try {
      await FirestoreService().updateLikeStatus(widget.product.id, _isLiked);
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status suka: $e')),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    if (_isLoading) return; // Prevent double tap
    
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
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use callback if provided, otherwise use FirestoreService directly
      if (widget.onAddToCart != null) {
        widget.onAddToCart!(widget.product, _quantity);
      } else {
        await FirestoreService().updateCartItem(user.uid, widget.product, _quantity);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} (${_quantity}x) ditambahkan ke keranjang'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan ke keranjang: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleLike,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.product.image,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey,
                child: const Center(child: Text('Gambar tidak tersedia')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.price,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // BARU: Stock indicator
                  Row(
                    children: [
                      Icon(
                        widget.product.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: widget.product.isAvailable ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.isAvailable 
                            ? 'Stok: ${widget.product.stock}' 
                            : 'Stok habis',
                        style: TextStyle(
                          color: widget.product.isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Jumlah:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _quantity > 1 ? () {
                          setState(() {
                            _quantity--;
                          });
                        } : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _quantity < widget.product.stock ? () {
                          setState(() {
                            _quantity++;
                          });
                        } : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.product.isAvailable && !_isLoading ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isLoading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.product.isAvailable 
                                ? 'Tambah ke Keranjang' 
                                : 'Stok Habis'
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}