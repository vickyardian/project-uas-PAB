//services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/models/order.dart';
import 'package:roti_nyaman/models/category.dart';
import 'package:roti_nyaman/models/user.dart';
import 'package:roti_nyaman/models/cart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== PRODUCT OPERATIONS (READ ONLY FOR CUSTOMERS) ====================

  /// Stream all available products for customers
  Stream<List<Product>> streamAllProducts() {
    return _db
        .collection('products')
        .where('stock', isGreaterThan: 0) // Only show products with stock
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream best seller products
  Stream<List<Product>> streamBestSellerProducts() {
    return _db
        .collection('products')
        .where('isBestSeller', isEqualTo: true)
        .where('stock', isGreaterThan: 0) // Only show products with stock
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream products by category for customers
  Stream<List<Product>> streamProductsByCategory(String categoryId) {
    return _db
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .where('stock', isGreaterThan: 0) // Only show products with stock
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream single product
  Stream<Product> streamProduct(String id) {
    return _db
        .collection('products')
        .doc(id)
        .snapshots()
        .map((doc) => Product.fromFirestore(doc));
  }

  /// Get single product
  Future<Product?> getProduct(String id) async {
    try {
      final doc = await _db.collection('products').doc(id).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil produk: $e');
    }
  }

  /// Search products for customers
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot =
          await _db
              .collection('products')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: '${query}z')
              .where('stock', isGreaterThan: 0) // Only show products with stock
              .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Gagal mencari produk: $e');
    }
  }

  /// Update product like status
  Future<void> updateLikeStatus(String productId, bool isLiked) async {
    try {
      await _db.collection('products').doc(productId).update({
        'isLiked': isLiked,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal memperbarui status suka: $e');
    }
  }

  /// Get product stock map for cart validation
  Future<Map<String, int>> getProductStockMap(List<String> productIds) async {
    try {    
      final stockMap = <String, int>{};
      
      // Batch get untuk efisiensi - Firestore limit 10 docs per batch
      final chunks = <List<String>>[];
      for (int i = 0; i < productIds.length; i += 10) {
        chunks.add(productIds.sublist(i, 
            i + 10 > productIds.length ? productIds.length : i + 10));
      }
      
      for (final chunk in chunks) {
        final snapshots = await Future.wait(
          chunk.map((id) => _db.collection('products').doc(id).get())
        );
        
        for (int i = 0; i < snapshots.length; i++) {
          final doc = snapshots[i];
          if (doc.exists) {
            stockMap[chunk[i]] = doc.data()!['stock'] as int;
          }
        }
      }
      
      return stockMap;
    } catch (e) {
      throw Exception('Gagal mengambil data stok: $e');
    }
  }

  // ==================== CATEGORY OPERATIONS (READ ONLY FOR CUSTOMERS) ====================

  /// Stream all categories for customers
  Stream<List<Category>> streamAllCategories() {
    return _db.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }

  /// Get single category
  Future<Category?> getCategory(String categoryId) async {
    try {
      final doc = await _db.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return Category.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil kategori: $e');
    }
  }

  // ==================== CART MANAGEMENT (UPDATED FOR CART MODEL) ====================

  /// Stream user's cart as Cart objects (compatible with CartScreen)
  Stream<List<Cart>> streamUserCart(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Cart.fromFirestore(doc)).toList();
        });
  }

  // Stream user's cart (legacy - returns Map<String, int>)
  Stream<Map<String, int>> streamCart(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) {
          final cart = <String, int>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            cart[data['productId'] as String] = data['quantity'] as int;
          }
          return cart;
        });
  }

  /// Get user's cart as Map (one-time fetch)
  Future<Map<String, int>> getUserCartMap(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();
      
      final cart = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        cart[data['productId'] as String] = data['quantity'] as int;
      }
      return cart;
    } catch (e) {
      throw Exception('Gagal mengambil data keranjang: $e');
    }
  }

  /// Add or update cart item - returns cart document ID
  Future<String> updateCartItem(
    String userId,
    Product product,
    int quantityToAdd,
  ) async {
    try {
      final cartRef = _db.collection('users').doc(userId).collection('cart');
      final existingQuery =
          await cartRef.where('productId', isEqualTo: product.id).get();

      if (existingQuery.docs.isNotEmpty) {
        final existingDoc = existingQuery.docs.first;
        final currentQuantity = existingDoc.data()['quantity'] as int;
        await existingDoc.reference.update({
          'quantity': currentQuantity + quantityToAdd,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return existingDoc.id; // Return cart document ID
      } else {
        final cartItem = {
          'userId': userId,
          'productId': product.id,
          'productName': product.name,
          'productPrice': product.price,
          'productImage': product.imageUrl,
          'quantity': quantityToAdd,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // Backward compatibility fields
          'name': product.name,
          'price': product.price,
          'image': product.imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        };
        final docRef = await cartRef.add(cartItem);
        return docRef.id; // Return cart document ID
      }
    } catch (e) {
      throw Exception('Gagal menambahkan ke keranjang: $e');
    }
  }

  /// Update single cart item quantity by cart ID
  Future<void> updateCartItemQuantity(
    String userId, 
    String cartId, 
    int newQuantity
  ) async {
    try {
      if (newQuantity <= 0) {
        await _db
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(cartId)
            .delete();
      } else {
        await _db
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(cartId)
            .update({
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Gagal memperbarui quantity: $e');
    }
  }

  /// Remove cart item by cart document ID
  Future<void> removeCartItem(String userId, String cartId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartId)
          .delete();
    } catch (e) {
      throw Exception('Gagal menghapus item dari keranjang: $e');
    }
  }

  /// Update entire cart with batch operation (legacy method)
  Future<void> updateUserCartBatch(
    String userId,
    Map<String, int> updatedCart,
    Map<String, Product> productCache,
  ) async {
    try {
      final batch = _db.batch();
      final cartRef = _db.collection('users').doc(userId).collection('cart');

      // Clear existing cart
      final existingCart = await cartRef.get();
      for (var doc in existingCart.docs) {
        batch.delete(doc.reference);
      }

      // Add updated cart items
      for (var entry in updatedCart.entries) {
        String productId = entry.key;
        int quantity = entry.value;
        if (quantity > 0 && productCache.containsKey(productId)) {
          final product = productCache[productId]!;
          final cartItem = {
            'userId': userId,
            'productId': product.id,
            'productName': product.name,
            'productPrice': product.price,
            'productImage': product.imageUrl,
            'quantity': quantity,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            // Backward compatibility fields
            'name': product.name,
            'price': product.price,
            'image': product.imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          };
          batch.set(cartRef.doc(), cartItem);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal memperbarui keranjang: $e');
    }
  }

  /// Remove specific item from cart by product ID (legacy method)
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      final cartRef = _db.collection('users').doc(userId).collection('cart');
      final query =
          await cartRef.where('productId', isEqualTo: productId).get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Gagal menghapus dari keranjang: $e');
    }
  }

  /// Clear entire cart
  Future<void> clearCart(String userId) async {
    try {
      final cartRef = _db.collection('users').doc(userId).collection('cart');
      final docs = await cartRef.get();

      final batch = _db.batch();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal mengosongkan keranjang: $e');
    }
  }

  // ==================== ORDER MANAGEMENT (CUSTOMER SIDE) ====================

  /// Create new order with transaction for data consistency
  Future<String> createOrder(String userId, Product product, int quantity) async {
    try {
      // Use transaction to ensure atomicity
      return await _db.runTransaction<String>((transaction) async {
        final productRef = _db.collection('products').doc(product.id);
        final productDoc = await transaction.get(productRef);
        
        if (!productDoc.exists) {
          throw Exception('Produk tidak ditemukan');
        }
        
        final currentStock = productDoc.data()!['stock'] as int;
        if (currentStock < quantity) {
          throw Exception('Stok tidak mencukupi. Stok tersedia: $currentStock');
        }

        // Create order object
        final order = Order(
          id: '', // Will be set by Firestore
          userId: userId,
          productId: product.id,
          productName: product.name,
          productPrice: product.price,
          productImage: product.imageUrl,
          quantity: quantity,
          total: product.price * quantity,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        // Add to user's orders subcollection
        final userOrderRef = _db
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc();
        
        transaction.set(userOrderRef, order.copyWith(id: userOrderRef.id).toFirestore());

        // Add to global orders collection for admin management
        final globalOrderRef = _db.collection('orders').doc(userOrderRef.id);
        transaction.set(globalOrderRef, order.copyWith(id: userOrderRef.id).toFirestore());

        // Update product stock
        transaction.update(productRef, {
          'stock': FieldValue.increment(-quantity),
          'updatedAt': Timestamp.now(),
        });

        return userOrderRef.id;
      });
    } catch (e) {
      throw Exception('Gagal memproses pesanan: $e');
    }
  }

  /// Create orders from Cart objects (compatible with CartScreen)
  Future<List<String>> createOrdersFromCartItems(
    String userId, 
    List<Cart> cartItems,
  ) async {
    try {
      return await _db.runTransaction<List<String>>((transaction) async {
        final orderIds = <String>[];
        
        // Validate all products and stock first
        for (var cartItem in cartItems) {
          final productRef = _db.collection('products').doc(cartItem.productId);
          final productDoc = await transaction.get(productRef);
          
          if (!productDoc.exists) {
            throw Exception('Produk ${cartItem.productName} tidak ditemukan');
          }
          
          final currentStock = productDoc.data()!['stock'] as int;
          if (currentStock < cartItem.quantity) {
            throw Exception('Stok ${cartItem.productName} tidak mencukupi. Stok tersedia: $currentStock');
          }
        }
        
        // Create orders and update stock
        for (var cartItem in cartItems) {
          final order = Order(
            id: '',
            userId: userId,
            productId: cartItem.productId,
            productName: cartItem.productName,
            productPrice: cartItem.productPrice,
            productImage: cartItem.productImage,
            quantity: cartItem.quantity,
            total: cartItem.totalPrice,
            status: 'pending',
            createdAt: DateTime.now(),
          );

          // Add to user's orders subcollection
          final userOrderRef = _db
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc();
          
          transaction.set(userOrderRef, order.copyWith(id: userOrderRef.id).toFirestore());

          // Add to global orders collection
          final globalOrderRef = _db.collection('orders').doc(userOrderRef.id);
          transaction.set(globalOrderRef, order.copyWith(id: userOrderRef.id).toFirestore());

          // Update product stock
          final productRef = _db.collection('products').doc(cartItem.productId);
          transaction.update(productRef, {
            'stock': FieldValue.increment(-cartItem.quantity),
            'updatedAt': Timestamp.now(),
          });
          
          orderIds.add(userOrderRef.id);
        }
        
        return orderIds;
      });
    } catch (e) {
      throw Exception('Gagal memproses pesanan dari keranjang: $e');
    }
  }

  /// Create multiple orders from cart with transaction (legacy method)
  Future<List<String>> createOrdersFromCart(
    String userId, 
    Map<String, int> cartItems,
    Map<String, Product> productCache,
  ) async {
    try {
      return await _db.runTransaction<List<String>>((transaction) async {
        final orderIds = <String>[];
        
        // Validate all products and stock first
        for (var entry in cartItems.entries) {
          final productId = entry.key;
          final quantity = entry.value;
          final product = productCache[productId];
          
          if (product == null) {
            throw Exception('Produk $productId tidak ditemukan');
          }
          
          final productRef = _db.collection('products').doc(productId);
          final productDoc = await transaction.get(productRef);
          
          if (!productDoc.exists) {
            throw Exception('Produk ${product.name} tidak ditemukan');
          }
          
          final currentStock = productDoc.data()!['stock'] as int;
          if (currentStock < quantity) {
            throw Exception('Stok ${product.name} tidak mencukupi. Stok tersedia: $currentStock');
          }
        }
        
        // Create orders and update stock
        for (var entry in cartItems.entries) {
          final productId = entry.key;
          final quantity = entry.value;
          final product = productCache[productId]!;
          
          final order = Order(
            id: '',
            userId: userId,
            productId: product.id,
            productName: product.name,
            productPrice: product.price,
            productImage: product.imageUrl,
            quantity: quantity,
            total: product.price * quantity,
            status: 'pending',
            createdAt: DateTime.now(),
          );

          // Add to user's orders subcollection
          final userOrderRef = _db
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc();
          
          transaction.set(userOrderRef, order.copyWith(id: userOrderRef.id).toFirestore());

          // Add to global orders collection
          final globalOrderRef = _db.collection('orders').doc(userOrderRef.id);
          transaction.set(globalOrderRef, order.copyWith(id: userOrderRef.id).toFirestore());

          // Update product stock
          final productRef = _db.collection('products').doc(productId);
          transaction.update(productRef, {
            'stock': FieldValue.increment(-quantity),
            'updatedAt': Timestamp.now(),
          });
          
          orderIds.add(userOrderRef.id);
        }
        
        return orderIds;
      });
    } catch (e) {
      throw Exception('Gagal memproses pesanan: $e');
    }
  }

  /// Stream user's orders
  Stream<List<Order>> streamUserOrders(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
        });
  }

  /// Get user's order history with pagination
  Future<List<Order>> getUserOrderHistory(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _db
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final ordersSnapshot = await query.get();

      return ordersSnapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil riwayat pesanan: $e');
    }
  }

  /// Get specific order
  Future<Order?> getOrder(String userId, String orderId) async {
    try {
      final doc =
          await _db
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc(orderId)
              .get();

      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil pesanan: $e');
    }
  }

  /// Update order status (for admin or status changes)
  Future<void> updateOrderStatus(
    String userId, 
    String orderId, 
    String newStatus,
  ) async {
    try {
      final now = DateTime.now();
      final updateData = {
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(now),
      };

      final batch = _db.batch();
      
      // Update in user's orders subcollection
      final userOrderRef = _db
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId);
      batch.update(userOrderRef, updateData);
      
      // Update in global orders collection
      final globalOrderRef = _db.collection('orders').doc(orderId);
      batch.update(globalOrderRef, updateData);
      
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal memperbarui status pesanan: $e');
    }
  }

  /// Cancel order (only if status is pending)
  Future<void> cancelOrder(String userId, String orderId) async {
    try {
      await _db.runTransaction((transaction) async {
        // Get order details
        final userOrderRef = _db
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);
        
        final orderDoc = await transaction.get(userOrderRef);
        if (!orderDoc.exists) {
          throw Exception('Pesanan tidak ditemukan');
        }
        
        final order = Order.fromFirestore(orderDoc);
        if (order.status != 'pending') {
          throw Exception('Pesanan tidak dapat dibatalkan. Status: ${order.status}');
        }
        
        // Update order status
        final now = DateTime.now();
        final updateData = {
          'status': 'cancelled',
          'updatedAt': Timestamp.fromDate(now),
        };
        
        transaction.update(userOrderRef, updateData);
        
        // Update global orders collection
        final globalOrderRef = _db.collection('orders').doc(orderId);
        transaction.update(globalOrderRef, updateData);
        
        // Restore product stock
        final productRef = _db.collection('products').doc(order.productId);
        transaction.update(productRef, {
          'stock': FieldValue.increment(order.quantity),
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Gagal membatalkan pesanan: $e');
    }
  }

  // ==================== USER PROFILE MANAGEMENT ====================

  /// Add new user
  Future<void> addUser(User user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toFirestore());
    } catch (e) {
      throw Exception('Gagal menambahkan user: $e');
    }
  }

  /// Get user data
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil data user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _db.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw Exception('Gagal memperbarui profile user: $e');
    }
  }

  /// Stream user data
  Stream<User> streamUser(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => User.fromFirestore(doc));
  }
}