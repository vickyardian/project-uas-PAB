//screens/home_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roti_nyaman/services/firestore_service.dart';
import 'package:roti_nyaman/widgets/home_content.dart';
import '../screens/profile_screen.dart';
import '../screens/cart_screen.dart';
import '../auth/login_screen.dart';
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
  final List<CartItem> _guestCartItems = []; // Renamed untuk clarity
  final Map<String, Product> _productCache = {};
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Load guest cart if returning from login
    _initializeCart();
  }

  void _initializeCart() {
    // Initialize cart based on mode
    if (!widget.isGuest && _currentUser != null) {
      _syncGuestCartOnLogin();
    }
  }

  List<Widget> get _pages {
    return [
      HomeContent(
        isGuest: widget.isGuest,
        cart: _getCartMap(),
        onAddToCart: _addToCart,
        onCartPressed: widget.isGuest
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
              key: ValueKey(_getCartMap().hashCode),
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

  Future<void> _addToCart(Product product) async {
    _productCache[product.id] = product;

    if (widget.isGuest) {
      // Mode tamu: update state lokal
      _addToGuestCart(product);
    } else if (_currentUser != null) {
      // Mode login: update Firestore
      try {
        await _firestoreService.updateCartItem(_currentUser!.uid, product, 1);
        _showSuccessSnackBar(product, false);
      } catch (e) {
        _showErrorSnackBar('Gagal menambahkan ke keranjang: $e');
        return;
      }
    }

    if (widget.isGuest) {
      _showSuccessSnackBar(product, true);
    }
  }

  void _addToGuestCart(Product product) {
    setState(() {
      int existingIndex = _guestCartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        _guestCartItems[existingIndex] = CartItem(
          product: _guestCartItems[existingIndex].product,
          quantity: _guestCartItems[existingIndex].quantity + 1,
        );
      } else {
        _guestCartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _showSuccessSnackBar(Product product, bool isGuest) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        backgroundColor: isGuest ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Lihat Keranjang',
          textColor: Colors.white,
          onPressed: () {
            if (!widget.isGuest) {
              setState(() => _selectedIndex = 1);
            } else {
              GuestDialogs.showCartDialog(context, _getCartMap(), _redirectToLogin);
            }
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _updateCartFromCartScreen(Map<String, int> updatedCart) async {
    if (widget.isGuest) {
      _updateGuestCart(updatedCart);
    } else if (_currentUser != null) {
      await _updateUserCart(updatedCart);
    }
  }

  void _updateGuestCart(Map<String, int> updatedCart) {
    setState(() {
      _guestCartItems.clear();
      for (var entry in updatedCart.entries) {
        String productId = entry.key;
        int quantity = entry.value;
        if (quantity > 0 && _productCache.containsKey(productId)) {
          _guestCartItems.add(
            CartItem(product: _productCache[productId]!, quantity: quantity),
          );
        }
      }
    });
  }

  Future<void> _updateUserCart(Map<String, int> updatedCart) async {
    try {
      await _firestoreService.updateUserCartBatch(_currentUser!.uid, updatedCart, _productCache);
    } catch (e) {
      _showErrorSnackBar('Gagal memperbarui keranjang: $e');
    }
  }

  Map<String, int> _getCartMap() {
  if (widget.isGuest) {
    return {for (var item in _guestCartItems) item.product.id: item.quantity};
  }
  // Untuk user login, return empty map karena cart dikelola oleh StreamBuilder
  return {};
}

  Map<String, String> _getProductImagesMap() {
  if (widget.isGuest) {
    return {for (var item in _guestCartItems) item.product.id: item.product.image};
  }
  return {for (var product in _productCache.values) product.id: product.image};
}

  Map<String, String> _getProductNamesMap() {
    return {for (var item in _guestCartItems) item.product.id: item.product.name};
  }

  Map<String, double> _getProductPricesMap() {
    return {
      for (var item in _guestCartItems)
        item.product.id: _parsePrice(item.product.price)
    };
  }

  Map<String, int> _getProductStockMap() {
    return {for (var item in _guestCartItems) item.product.id: item.product.stock};
  }

  double _parsePrice(String priceString) {
    String cleanPrice = priceString
        .replaceAll('Rp', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '');
    try {
      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  int get _totalCartItems =>
      _guestCartItems.fold(0, (sum, item) => sum + item.quantity);

  void _redirectToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _syncGuestCartOnLogin() async {
    if (_guestCartItems.isEmpty) return;
    
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      try {
        for (var item in _guestCartItems) {
          await _firestoreService.updateCartItem(
              _currentUser!.uid, item.product, item.quantity);
        }
        setState(() {
          _guestCartItems.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Keranjang tamu telah disinkronkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Gagal menyinkronkan keranjang tamu: $e');
        }
      }
    }
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
            widget.isGuest ? const Color.fromARGB(255, 0, 140, 255) : Colors.blue,
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