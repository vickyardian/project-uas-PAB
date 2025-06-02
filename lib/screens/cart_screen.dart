import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  final Map<String, int> cart;
  final Function(Map<String, int>) onCartUpdated;
  final Map<String, String> productImages; // PERBAIKAN: Remove nullable
  final Map<String, String> productNames; // PERBAIKAN: Remove nullable
  final Map<String, double> productPrices; // PERBAIKAN: Remove nullable
  final Map<String, int> productStock; // PERBAIKAN: Remove nullable

  const CartScreen({
    super.key,
    required this.cart,
    required this.onCartUpdated,
    required this.productImages, // PERBAIKAN: Required tanpa nullable
    required this.productNames, // PERBAIKAN: Required tanpa nullable
    required this.productPrices, // PERBAIKAN: Required tanpa nullable
    required this.productStock, // PERBAIKAN: Required tanpa nullable
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, int> localCart;

  @override
  void initState() {
    super.initState();
    localCart = Map<String, int>.from(widget.cart);
  }

  void _updateCart() {
    widget.onCartUpdated(localCart);
  }

  void _updateQuantity(String productId, int newQuantity) {
    final maxStock = _getProductStock(productId);

    if (newQuantity > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok ${_getProductName(productId)} hanya tersedia $maxStock item',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (newQuantity <= 0) {
        localCart.remove(productId);
      } else {
        localCart[productId] = newQuantity;
      }
    });
    _updateCart();
  }

  void _clearCart() {
    setState(() {
      localCart.clear();
    });
    _updateCart();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Keranjang dikosongkan'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  int _getProductStock(String productId) {
    return widget.productStock[productId] ?? 999;
  }

  double _getProductPrice(String productId) {
    // PERBAIKAN: Langsung ambil dari map yang sudah pasti ada
    return widget.productPrices[productId] ?? _getFallbackPrice(productId);
  }

  // Fallback price jika tidak ada di map
  double _getFallbackPrice(String productId) {
    switch (productId.toLowerCase()) {
      case 'roti_tawar':
        return 8000.0;
      case 'roti_coklat':
        return 10000.0;
      case 'roti_keju':
        return 12000.0;
      default:
        return 5000.0;
    }
  }

  String _getProductName(String productId) {
    // PERBAIKAN: Langsung ambil dari map yang sudah pasti ada
    return widget.productNames[productId] ?? _getDefaultProductName(productId);
  }

  double _getSubtotal(String productId) {
    final price = _getProductPrice(productId);
    final quantity = localCart[productId] ?? 0;
    return price * quantity;
  }

  double _getTotalPrice() {
    double total = 0.0;
    for (String productId in localCart.keys) {
      total += _getSubtotal(productId);
    }
    return total;
  }

  int _getTotalItems() {
    return localCart.values.fold(0, (sum, qty) => sum + qty);
  }

  String _getDefaultProductName(String productId) {
    switch (productId.toLowerCase()) {
      case 'roti_tawar':
        return 'Roti Tawar';
      case 'roti_coklat':
        return 'Roti Coklat';
      case 'roti_keju':
        return 'Roti Keju';
      default:
        return productId
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? word[0].toUpperCase() + word.substring(1)
                      : '',
            )
            .join(' ');
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Widget _buildProductImage(String productId) {
    // PERBAIKAN: Langsung ambil image URL dari map
    final imageUrl = widget.productImages[productId] ?? '';

    debugPrint('DEBUG: CartScreen - Product $productId image: $imageUrl');

    // Jika ada URL gambar dan tidak kosong, coba load
    if (imageUrl.isNotEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('ERROR: Failed to load image for $productId: $error');
              return _buildFallbackImage(productId);
            },
          ),
        ),
      );
    }

    // Jika tidak ada URL atau kosong, langsung tampilkan fallback
    return _buildFallbackImage(productId);
  }

  Widget _buildFallbackImage(String productId) {
    // PERBAIKAN: Lebih robust icon selection
    IconData iconData;
    Color iconColor;

    final productName = _getProductName(productId).toLowerCase();

    if (productName.contains('tawar') || productName.contains('bread')) {
      iconData = Icons.bakery_dining;
      iconColor = Colors.orange;
    } else if (productName.contains('coklat') ||
        productName.contains('chocolate')) {
      iconData = Icons.cake;
      iconColor = Colors.brown;
    } else if (productName.contains('keju') || productName.contains('cheese')) {
      iconData = Icons.breakfast_dining;
      iconColor = Colors.yellow[700]!;
    } else if (productName.contains('roti') || productName.contains('bread')) {
      iconData = Icons.bakery_dining;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.shopping_bag;
      iconColor = Colors.grey[600]!;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Icon(iconData, color: iconColor, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (localCart.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Keranjang'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
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
              SizedBox(height: 8),
              Text(
                'Tambahkan produk untuk melanjutkan',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _clearCart,
            child: const Text(
              'Kosongkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: localCart.length,
              itemBuilder: (context, index) {
                final productId = localCart.keys.elementAt(index);
                final quantity = localCart[productId]!;
                final price = _getProductPrice(productId);
                final subtotal = _getSubtotal(productId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductImage(productId),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getProductName(productId),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(price),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subtotal: ${_formatCurrency(subtotal)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stok tersedia: ${_getProductStock(productId)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.red),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed:
                                          quantity > 1
                                              ? () => _updateQuantity(
                                                productId,
                                                quantity - 1,
                                              )
                                              : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color:
                                            quantity > 1
                                                ? Colors.red
                                                : Colors.grey,
                                        size: 20,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            quantity <
                                                    _getProductStock(productId)
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed:
                                          quantity < _getProductStock(productId)
                                              ? () => _updateQuantity(
                                                productId,
                                                quantity + 1,
                                              )
                                              : null,
                                      icon: Icon(
                                        Icons.add,
                                        color:
                                            quantity <
                                                    _getProductStock(productId)
                                                ? Colors.green
                                                : Colors.grey,
                                        size: 20,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
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
                    const Text('Total Item:', style: TextStyle(fontSize: 16)),
                    Text(
                      '${_getTotalItems()} item',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatCurrency(_getTotalPrice()),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        localCart.isNotEmpty
                            ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Checkout - ${_formatCurrency(_getTotalPrice())}',
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Checkout - ${_formatCurrency(_getTotalPrice())}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
