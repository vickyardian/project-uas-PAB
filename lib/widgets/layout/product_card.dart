import 'package:flutter/material.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/screens/pages/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isGuest;
  final Function(Product) onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.isGuest,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ProductDetailScreen(product: product, isGuest: isGuest),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN GAMBAR ---
            Expanded(
              child: Container(
                width: double.infinity,
                // [PERBAIKAN UTAMA] Tambahkan Padding di sini
                padding: const EdgeInsets.all(
                  8.0,
                ), // Memberi spasi 8 pixel di sekeliling gambar
                child: ClipRRect(
                  // Beri sedikit radius pada gambar agar sudutnya tidak tajam
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    color: Colors.grey[200],
                    child:
                        product.imageUrl != null && product.imageUrl!.isNotEmpty
                            ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildPlaceholder(),
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            )
                            : _buildPlaceholder(),
                  ),
                ),
              ),
            ),

            // --- BAGIAN DETAIL PRODUK ---
            Padding(
              padding: const EdgeInsets.fromLTRB(
                8.0,
                0,
                8.0,
                8.0,
              ), // Sesuaikan padding detail
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed:
                          product.stock > 0 ? () => onAddToCart(product) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(product.stock > 0 ? 'Tambah' : 'Habis'),
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

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey[300],
      child: const Icon(Icons.image, size: 40, color: Colors.grey),
    );
  }
}
