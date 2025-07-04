//widgets/layout/home_content.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/services/firestore_service.dart';
import 'package:roti_nyaman/widgets/layout/product_card.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeContent extends StatelessWidget {
  final bool isGuest;
  final Map<String, int> cart;
  final Function(Product) onAddToCart;
  final VoidCallback onCartPressed;

  const HomeContent({
    super.key,
    required this.isGuest,
    required this.cart,
    required this.onAddToCart,
    required this.onCartPressed,
  });

  final List<String> imgList = const [
    'assets/carousel/carousel1.jpg',
    'assets/carousel/carousel2.jpg',
    'assets/carousel/carousel1.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header dengan gradient
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Color.fromARGB(255, 28, 111, 255)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Roti Nyaman',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isGuest ? 'MODE TAMU' : 'BAKERY SHOP',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const Spacer(),
              _buildCartButton(),
            ],
          ),
        ),

        // Banner sederhana
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: CarouselSlider(
            options: CarouselOptions(
              height: 150.0,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.8,
            ),
            items:
                imgList
                    .map(
                      (item) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(item),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),

        // Products Section
        Flexible(
          child: _buildProductsSection(),
        ), //mengganti Expanded dengan Flexible dapat mengatasi masalah layout yang rumit. Flexible lebih "lunak" dan tidak memaksa child untuk mengisi semua ruang yang tersedia.
      ],
    );
  }

  Widget _buildCartButton() {
    final user = FirebaseAuth.instance.currentUser;

    if (isGuest || user == null) {
      return GestureDetector(
        onTap: onCartPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.white),
        ),
      );
    }

    // Untuk user yang login, gunakan StreamBuilder untuk real-time cart count
    return StreamBuilder<Map<String, int>>(
      stream: FirestoreService().streamCart(user.uid),
      builder: (context, snapshot) {
        int totalItems = 0;
        if (snapshot.hasData) {
          totalItems = snapshot.data!.values.fold(
            0,
            (sum, quantity) => sum + quantity,
          );
        }

        return GestureDetector(
          onTap: onCartPressed,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              if (totalItems > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$totalItems',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsSection() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Produk Terbaru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text('Lihat Semua >', style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: FirestoreService().streamAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Trigger rebuild
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada produk tersedia',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final products = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    isGuest: isGuest,
                    onAddToCart: onAddToCart,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
