//screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:roti_nyaman/models/cart.dart';

class CartScreen extends StatefulWidget {
  final List<Cart> cartItems;
  final Function(List<Cart>) onCartUpdated;
  final String userId;
  final Map<String, int>? productStock; // Optional stock data

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onCartUpdated,
    required this.userId,
    this.productStock,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Cart> localCartItems;

  @override
  void initState() {
    super.initState();
    localCartItems = List<Cart>.from(widget.cartItems);
  }

  void _updateCart() {
    widget.onCartUpdated(localCartItems);
  }

  void _updateQuantity(String cartId, int newQuantity) {
    final cartIndex = localCartItems.indexWhere((item) => item.id == cartId);
    if (cartIndex == -1) return;

    final cartItem = localCartItems[cartIndex];
    final maxStock = _getProductStock(cartItem.productId);

    if (newQuantity > maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok ${cartItem.productName} hanya tersedia $maxStock item',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (newQuantity <= 0) {
        localCartItems.removeAt(cartIndex);
      } else {
        localCartItems[cartIndex] = cartItem.copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );
      }
    });
    _updateCart();
  }

  void _removeItem(String cartId) {
    setState(() {
      localCartItems.removeWhere((item) => item.id == cartId);
    });
    _updateCart();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item dihapus dari keranjang'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _clearCart() {
    setState(() {
      localCartItems.clear();
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
    return widget.productStock?[productId] ?? 999;
  }

  double _getTotalPrice() {
    return localCartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int _getTotalItems() {
    return localCartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Widget _buildProductImage(Cart cartItem) {
    final imageUrl = cartItem.productImage ?? '';

    debugPrint('DEBUG: CartScreen - Product ${cartItem.productId} image: $imageUrl');

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
              debugPrint('ERROR: Failed to load image for ${cartItem.productId}: $error');
              return _buildFallbackImage(cartItem);
            },
          ),
        ),
      );
    }

    return _buildFallbackImage(cartItem);
  }

  Widget _buildFallbackImage(Cart cartItem) {
    IconData iconData;
    Color iconColor;

    final productName = cartItem.productName.toLowerCase();

    if (productName.contains('tawar') || productName.contains('bread')) {
      iconData = Icons.bakery_dining;
      iconColor = Colors.orange;
    } else if (productName.contains('coklat') || productName.contains('chocolate')) {
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
    if (localCartItems.isEmpty) {
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
              itemCount: localCartItems.length,
              itemBuilder: (context, index) {
                final cartItem = localCartItems[index];
                final maxStock = _getProductStock(cartItem.productId);

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
                        _buildProductImage(cartItem),
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
                              Text(
                                _formatCurrency(cartItem.productPrice),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Subtotal: ${_formatCurrency(cartItem.totalPrice)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stok tersedia: $maxStock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ditambahkan: ${cartItem.createdAt.day}/${cartItem.createdAt.month}/${cartItem.createdAt.year}',
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
                                      onPressed: cartItem.quantity > 1
                                          ? () => _updateQuantity(
                                                cartItem.id,
                                                cartItem.quantity - 1,
                                              )
                                          : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color: cartItem.quantity > 1
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
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: cartItem.quantity < maxStock
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: cartItem.quantity < maxStock
                                          ? () => _updateQuantity(
                                                cartItem.id,
                                                cartItem.quantity + 1,
                                              )
                                          : null,
                                      icon: Icon(
                                        Icons.add,
                                        color: cartItem.quantity < maxStock
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
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _removeItem(cartItem.id),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Hapus dari keranjang',
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
                    onPressed: localCartItems.isNotEmpty
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