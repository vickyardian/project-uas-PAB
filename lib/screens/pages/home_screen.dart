//screens/pages/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:roti_nyaman/services/firestore_service.dart';
import 'package:roti_nyaman/widgets/layout/home_content.dart';
import 'package:roti_nyaman/screens/pages/profile_screen.dart';
import 'package:roti_nyaman/screens/pages/cart_screen.dart';
import 'package:roti_nyaman/auth/login_screen.dart';
import 'package:roti_nyaman/widgets/users/guest_cart_page.dart';
import 'package:roti_nyaman/widgets/users/guest_profile_page.dart';
import 'package:roti_nyaman/widgets/users/guest_dialogs.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/models/cart.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  const HomeScreen({super.key, this.isGuest = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Cart> _guestCartItems = [];
  List<Cart> _userCartItems = [];
  final Map<String, Product> _productCache = {};
  final Map<String, int> _productStock = {}; // Track product stock
  final FirestoreService _firestoreService = FirestoreService();
  User? _currentUser;
  bool _isLoadingCart = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _initializeCart();
  }

  void _initializeCart() {
    if (!widget.isGuest && _currentUser != null) {
      _loadUserCart();
      _syncGuestCartOnLogin();
    }
  }

  Future<void> _loadUserCart() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoadingCart = true;
    });

    try {
      // For now, start with empty cart and load as products are added
      // This will be populated when products are added to cart
      _userCartItems.clear();
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Gagal memuat keranjang: $e');
    } finally {
      setState(() {
        _isLoadingCart = false;
      });
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
              cartItems: _userCartItems,
              onCartUpdated: _updateCartFromCartScreen,
              userId: _currentUser?.uid ?? '',
              productStock: _productStock,
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
    _productStock[product.id] = product.stock; // Cache product stock

    if (widget.isGuest) {
      _addToGuestCart(product);
      _showSuccessSnackBar(product, true);
    } else if (_currentUser != null) {
      try {
        // Check if product already exists in cart
        final existingCartIndex = _userCartItems.indexWhere(
          (item) => item.productId == product.id,
        );

        if (existingCartIndex != -1) {
          // Update existing cart item
          final existingCart = _userCartItems[existingCartIndex];
          final newQuantity = existingCart.quantity + 1;
          
          if (newQuantity > product.stock) {
            _showErrorSnackBar('Stok ${product.name} tidak mencukupi');
            return;
          }

          // Use existing FirestoreService method
          await _firestoreService.updateCartItem(
            _currentUser!.uid, 
            product, 
            newQuantity
          );
          
          setState(() {
            _userCartItems[existingCartIndex] = existingCart.copyWith(
              quantity: newQuantity,
              updatedAt: DateTime.now(),
            );
          });
        } else {
          // Add new cart item using existing method
          await _firestoreService.updateCartItem(
            _currentUser!.uid, 
            product, 
            1
          );
          
          setState(() {
            _userCartItems.add(Cart(
              id: '${_currentUser!.uid}_${product.id}',
              userId: _currentUser!.uid,
              productId: product.id,
              productName: product.name,
              productPrice: product.price,
              productImage: product.image,
              quantity: 1,
              createdAt: DateTime.now(),
            ));
          });
        }
        
        _showSuccessSnackBar(product, false);
      } catch (e) {
        _showErrorSnackBar('Gagal menambahkan ke keranjang: $e');
      }
    }
  }

  void _addToGuestCart(Product product) {
    setState(() {
      int existingIndex = _guestCartItems.indexWhere(
        (item) => item.productId == product.id,
      );
      
      if (existingIndex != -1) {
        final existingCart = _guestCartItems[existingIndex];
        final newQuantity = existingCart.quantity + 1;
        
        if (newQuantity > product.stock) {
          _showErrorSnackBar('Stok ${product.name} tidak mencukupi');
          return;
        }

        _guestCartItems[existingIndex] = existingCart.copyWith(
          quantity: newQuantity,
          updatedAt: DateTime.now(),
        );
      } else {
        _guestCartItems.add(Cart(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'guest',
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productImage: product.image,
          quantity: 1,
          createdAt: DateTime.now(),
        ));
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateCartFromCartScreen(List<Cart> updatedCartItems) async {
    if (widget.isGuest) {
      _updateGuestCart(updatedCartItems);
    } else if (_currentUser != null) {
      await _updateUserCart(updatedCartItems);
    }
  }

  void _updateGuestCart(List<Cart> updatedCartItems) {
    setState(() {
      _guestCartItems.clear();
      _guestCartItems.addAll(updatedCartItems);
    });
  }

  Future<void> _updateUserCart(List<Cart> updatedCartItems) async {
    try {
      // Update local state first for immediate UI response
      setState(() {
        _userCartItems = List<Cart>.from(updatedCartItems);
      });

      // Convert List<Cart> to Map<String, int> for existing FirestoreService method
      final cartMap = <String, int>{};
      for (var item in updatedCartItems) {
        cartMap[item.productId] = item.quantity;
      }

      // Use existing batch update method
      await _firestoreService.updateUserCartBatch(
        _currentUser!.uid,
        cartMap,
        _productCache,
      );
    } catch (e) {
      // Revert local state on error
      await _loadUserCart();
      _showErrorSnackBar('Gagal memperbarui keranjang: $e');
    }
  }

  Map<String, int> _getCartMap() {
    if (widget.isGuest) {
      return {
        for (var item in _guestCartItems) item.productId: item.quantity
      };
    } else {
      return {
        for (var item in _userCartItems) item.productId: item.quantity
      };
    }
  }

  int get _totalCartItems {
    if (widget.isGuest) {
      return _guestCartItems.fold(0, (sum, item) => sum + item.quantity);
    } else {
      return _userCartItems.fold(0, (sum, item) => sum + item.quantity);
    }
  }

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
        // Convert guest cart to map format for existing method
        final cartMapToSync = <String, int>{};
        
        for (var guestItem in _guestCartItems) {
          final existingIndex = _userCartItems.indexWhere(
            (item) => item.productId == guestItem.productId,
          );

          if (existingIndex != -1) {
            // Merge quantities
            final existingCart = _userCartItems[existingIndex];
            final newQuantity = existingCart.quantity + guestItem.quantity;
            final maxStock = _productStock[guestItem.productId] ?? 999;
            
            cartMapToSync[guestItem.productId] = newQuantity > maxStock ? maxStock : newQuantity;
            
            // Update local cart
            _userCartItems[existingIndex] = existingCart.copyWith(
              quantity: cartMapToSync[guestItem.productId]!,
              updatedAt: DateTime.now(),
            );
          } else {
            // Add new cart item
            cartMapToSync[guestItem.productId] = guestItem.quantity;
            _userCartItems.add(guestItem.copyWith(
              userId: _currentUser!.uid,
              createdAt: DateTime.now(),
            ));
          }
        }
        
        // Use existing batch update method
        await _firestoreService.updateUserCartBatch(
          _currentUser!.uid,
          cartMapToSync,
          _productCache,
        );
        
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
        child: _isLoadingCart
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: widget.isGuest ? Colors.orange : Colors.blue,
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
                const Icon(Icons.shopping_cart),
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}