// home_screen.dart

import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import '../widgets/home_content.dart';
import '../widgets/guest_cart_page.dart';
import '../widgets/guest_profile_page.dart';
import '../widgets/guest_dialogs.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<CartItem> _cartItems = [];
  final Map<String, Product> _productCache = {}; // Key by product.id

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: HomeScreen initialized');
  }

  List<Widget> get _pages {
    return [
      HomeContent(
        isGuest: widget.isGuest,
        cart: _getCartMap(),
        onAddToCart: _addToCart,
        onCartPressed:
            widget.isGuest
                ? () => GuestDialogs.showCartDialog(
                  context,
                  _getCartMap(),
                  _redirectToLogin,
                )
                : () => setState(() => _selectedIndex = 1),
      ),
      widget.isGuest
          ? GuestCartPage(onLoginPressed: _redirectToLogin)
          : CartScreen(
            key: ValueKey(_cartItems.length), // Paksa rebuild saat cart berubah
            cart: _getCartMap(),
            onCartUpdated: _updateCartFromCartScreen,
            productImages: _getProductImagesMap(),
            productNames: _getProductNamesMap(),
            productPrices: _getProductPricesMap(),
            productStock: _getProductStockMap(),
          ),
      widget.isGuest
          ? GuestProfilePage(onLoginPressed: _redirectToLogin)
          : const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (widget.isGuest && index != 0) {
      GuestDialogs.showLimitationDialog(context, _redirectToLogin);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _addToCart(Product product) {
    _productCache[product.id] = product;
    int existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    setState(() {
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        backgroundColor: widget.isGuest ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Lihat Keranjang',
          textColor: Colors.white,
          onPressed: () => setState(() => _selectedIndex = 1),
        ),
      ),
    );
  }

  void _updateCartFromCartScreen(Map<String, int> updatedCart) {
    setState(() {
      _cartItems.clear();
      for (var entry in updatedCart.entries) {
        String productId = entry.key;
        int quantity = entry.value;
        if (quantity > 0) {
          Product? product = _productCache[productId];
          if (product != null) {
            _cartItems.add(CartItem(product: product, quantity: quantity));
          } else {
            _cartItems.add(
              CartItem(
                product: Product(
                  id: productId,
                  name: 'Produk Tidak Dikenal',
                  description: 'Dari keranjang',
                  price: '0',
                  image: '',
                  stock: 999,
                  category: 'Lainnya',
                ),
                quantity: quantity,
              ),
            );
          }
        }
      }
    });
  }

  Map<String, int> _getCartMap() {
    return {for (var item in _cartItems) item.product.id: item.quantity};
  }

  // PERBAIKAN UTAMA: Selalu return map (bukan null) dan pastikan semua produk di-include
  Map<String, String> _getProductImagesMap() {
    Map<String, String> imageMap = {};

    // Loop semua item di cart, bukan hanya yang memiliki gambar
    for (var item in _cartItems) {
      // Selalu tambahkan ke map, meskipun image kosong
      imageMap[item.product.id] = item.product.image;
      debugPrint(
        'DEBUG: Product ${item.product.id} image: ${item.product.image}',
      );
    }

    debugPrint('DEBUG: Final image map: $imageMap');
    return imageMap;
  }

  // PERBAIKAN: Selalu return map (bukan null)
  Map<String, String> _getProductNamesMap() {
    Map<String, String> nameMap = {};
    for (var item in _cartItems) {
      nameMap[item.product.id] = item.product.name;
    }
    return nameMap;
  }

  // PERBAIKAN: Selalu return map (bukan null)
  Map<String, double> _getProductPricesMap() {
    Map<String, double> priceMap = {};
    for (var item in _cartItems) {
      double price = _parsePrice(item.product.price);
      priceMap[item.product.id] = price;
    }
    return priceMap;
  }

  // PERBAIKAN: Selalu return map (bukan null)
  Map<String, int> _getProductStockMap() {
    Map<String, int> stockMap = {};
    for (var item in _cartItems) {
      stockMap[item.product.id] = item.product.stock;
    }
    return stockMap;
  }

  // Helper function untuk parsing harga
  double _parsePrice(String priceString) {
    // Hapus "Rp", spasi, dan titik pemisah ribuan
    String cleanPrice = priceString
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '');

    // Coba parse ke double
    try {
      return double.parse(cleanPrice);
    } catch (e) {
      debugPrint('Error parsing price: $priceString');
      return 0.0;
    }
  }

  int get _totalCartItems =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor:
            widget.isGuest
                ? const Color.fromARGB(255, 0, 140, 255)
                : Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(
                  widget.isGuest
                      ? Icons.shopping_cart_outlined
                      : Icons.shopping_cart,
                ),
                if (_totalCartItems > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_totalCartItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(widget.isGuest ? Icons.person_outline : Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
