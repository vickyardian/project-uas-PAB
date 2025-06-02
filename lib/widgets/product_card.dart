// widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/screens/product_detail_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isGuest;
  final Function(Product) onAddToCart;
  final VoidCallback? onLikeChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.isGuest,
    required this.onAddToCart,
    this.onLikeChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  static const double _cardElevation = 3.0;
  static const double _cardRadius = 12.0;
  static const double _imageHeight =
      120.0; // Dikurangi untuk memberi ruang button
  // ignore: unused_field
  static const EdgeInsets _cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets _imagePadding = EdgeInsets.fromLTRB(
    8.0,
    8.0,
    8.0,
    0,
  ); // Dikurangi padding

  @override
  void initState() {
    super.initState();
    isLiked = widget.product.isLiked;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    if (!mounted) return;

    setState(() {
      isLiked = !isLiked;
      widget.product.isLiked = isLiked;
    });

    widget.onLikeChanged?.call();
  }

  Future<void> _openDetail() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ProductDetailScreen(
                product: widget.product,
                onAddToCart: widget.onAddToCart,
                onLikeChanged: widget.onLikeChanged,
              ),
        ),
      );

      if (mounted) {
        setState(() {
          isLiked = widget.product.isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddToCart() async {
    if (widget.product.stock <= 0) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      widget.onAddToCart(widget.product);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  Widget _buildProductImage() {
    return Padding(
      padding: _imagePadding,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Image.asset(
              widget.product.image,
              fit: BoxFit.cover,
              height: _imageHeight,
              width: double.infinity,
              errorBuilder:
                  (context, error, stackTrace) => _buildImagePlaceholder(),
            ),
          ),
          _buildStockBadge(),
          _buildLikeButton(),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: _imageHeight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bakery_dining_outlined, size: 40, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Gambar tidak tersedia',
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBadge() {
    if (widget.product.stock > 5) return const SizedBox.shrink();

    return Positioned(
      top: 6,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: widget.product.stock == 0 ? Colors.red : Colors.orange,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          widget.product.stock == 0 ? 'Habis' : 'Sisa ${widget.product.stock}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return Positioned(
      bottom: 6,
      right: 6,
      child: GestureDetector(
        onTap: _toggleLike,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.grey[600],
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Expanded(
      // Tambahan: Expanded untuk mengisi ruang tersisa
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12.0,
          8.0,
          12.0,
          12.0,
        ), // Padding disesuaikan
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Tambahan: MainAxisSize.min
          children: [
            Text(
              widget.product.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                // Ubah ke titleSmall
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.price,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                // Ubah ke titleSmall
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            _buildStockInfo(),
            const SizedBox(height: 8), // Dikurangi spacing
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo() {
    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          'Stok: ${widget.product.stock}',
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final bool isOutOfStock = widget.product.stock <= 0;

    return SizedBox(
      width: double.infinity,
      height: 32, // Tambahan: Fixed height untuk button
      child: ElevatedButton(
        onPressed:
            _isLoading || isOutOfStock
                ? null
                : () {
                  if (widget.isGuest) {
                    _openDetail();
                  } else {
                    _handleAddToCart();
                  }
                },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.isGuest
                  ? Theme.of(context).primaryColor
                  : (isOutOfStock ? Colors.grey : Colors.blue),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6), // Dikurangi padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: isOutOfStock ? 0 : 1,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  widget.isGuest
                      ? 'Lihat Detail'
                      : (isOutOfStock ? 'Stok Habis' : 'Tambah ke Keranjang'),
                  style: const TextStyle(
                    fontSize: 10, // Dikurangi font size
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: _cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: _openDetail,
              // Perubahan: Menggunakan Column dengan MainAxisSize.min
              child: IntrinsicHeight(
                // Tambahan: IntrinsicHeight untuk mengatur tinggi
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_buildProductImage(), _buildProductInfo()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
