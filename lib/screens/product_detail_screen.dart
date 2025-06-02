// screens/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roti_nyaman/models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Function(Product) onAddToCart;
  final VoidCallback? onLikeChanged;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
    this.onLikeChanged,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int quantity = 1;
  bool _isAddingToCart = false;
  bool _isBuyingNow = false;

  // Constants
  static const double _imageHeight = 280.0;
  static const EdgeInsets _screenPadding = EdgeInsets.all(16.0);

  @override
  void initState() {
    super.initState();
    isLiked = widget.product.isLiked;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    if (!mounted) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      isLiked = !isLiked;
      widget.product.isLiked = isLiked;
    });

    widget.onLikeChanged?.call();
    _showLikeFeedback();
  }

  void _showLikeFeedback() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(isLiked ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLiked ? Colors.red[400] : Colors.grey[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (widget.product.stock < quantity) {
      _showErrorSnackBar('Stok tidak mencukupi');
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      // Simulasi delay network
      await Future.delayed(const Duration(milliseconds: 800));

      for (int i = 0; i < quantity; i++) {
        widget.onAddToCart(widget.product);
      }

      if (mounted) {
        _showSuccessSnackBar(
          '$quantity item berhasil ditambahkan ke keranjang',
        );
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal menambahkan ke keranjang');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _buyNow() async {
    if (widget.product.stock < quantity) {
      _showErrorSnackBar('Stok tidak mencukupi');
      return;
    }

    setState(() {
      _isBuyingNow = true;
    });

    try {
      // Simulasi proses pembelian
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        _showPurchaseDialog();
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal memproses pembelian');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuyingNow = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.green),
              SizedBox(width: 12),
              Text('Konfirmasi Pembelian'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apakah Anda yakin ingin membeli:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Jumlah: $quantity'),
                    Text('Harga: ${widget.product.price}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar(
                  'Pembelian berhasil! Menuju pembayaran...',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Beli Sekarang'),
            ),
          ],
        );
      },
    );
  }

  void _increaseQuantity() {
    if (quantity < widget.product.stock) {
      setState(() {
        quantity++;
      });
      HapticFeedback.selectionClick();
    } else {
      _showErrorSnackBar('Jumlah melebihi stok yang tersedia');
    }
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
      HapticFeedback.selectionClick();
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: _imageHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.share, color: Colors.grey[700]),
          ),
          onPressed: () {
            // Implementasi share
            _showSuccessSnackBar('Fitur berbagi akan segera tersedia');
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.product.image,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => _buildImagePlaceholder(),
            ),
            _buildImageOverlay(),
            _buildLikeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bakery_dining_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Gambar tidak tersedia',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: _toggleLike,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLiked ? Colors.red : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.white : Colors.grey[700],
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: _screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductHeader(),
              const SizedBox(height: 20),
              _buildQuantitySelector(),
              const SizedBox(height: 20),
              _buildDescription(),
              const SizedBox(height: 20),
              _buildStockInfo(),
              const SizedBox(height: 100), // Space for bottom buttons
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.price,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuantityButton(
              icon: Icons.remove,
              onPressed: quantity > 1 ? _decreaseQuantity : null,
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                quantity.toString(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            _buildQuantityButton(
              icon: Icons.add,
              onPressed:
                  quantity < widget.product.stock ? _increaseQuantity : null,
            ),
            const Spacer(),
            Text(
              'Stok: ${widget.product.stock}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed != null ? Colors.blue[200]! : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: onPressed != null ? Colors.blue[700] : Colors.grey[400],
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi Produk',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.product.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.product.stock > 5 ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              widget.product.stock > 5
                  ? Colors.green[200]!
                  : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.product.stock > 5 ? Icons.check_circle : Icons.warning,
            color:
                widget.product.stock > 5
                    ? Colors.green[700]
                    : Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.stock > 5
                      ? 'Stok Tersedia'
                      : widget.product.stock == 0
                      ? 'Stok Habis'
                      : 'Stok Terbatas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        widget.product.stock > 5
                            ? Colors.green[700]
                            : Colors.orange[700],
                  ),
                ),
                Text(
                  widget.product.stock == 0
                      ? 'Produk sedang tidak tersedia'
                      : 'Tersisa ${widget.product.stock} unit',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final bool isOutOfStock = widget.product.stock == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isOutOfStock || _isAddingToCart ? null : _addToCart,
                icon:
                    _isAddingToCart
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.shopping_cart),
                label: Text(
                  isOutOfStock
                      ? 'Stok Habis'
                      : _isAddingToCart
                      ? 'Menambahkan...'
                      : 'Tambah ke Keranjang',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isOutOfStock ? 0 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isOutOfStock || _isBuyingNow ? null : _buyNow,
                icon:
                    _isBuyingNow
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.flash_on),
                label: Text(
                  isOutOfStock
                      ? 'Tidak Tersedia'
                      : _isBuyingNow
                      ? 'Memproses...'
                      : 'Beli Sekarang',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isOutOfStock ? 0 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildProductInfo()),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActions(),
          ),
        ],
      ),
    );
  }
}
