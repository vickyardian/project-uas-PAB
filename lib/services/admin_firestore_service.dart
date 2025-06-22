//services/admin_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Order  ;
import 'package:roti_nyaman/models/user.dart';
import 'package:roti_nyaman/models/category.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/models/order.dart';
import 'package:roti_nyaman/services/imgbb_service.dart';
import 'dart:io';
import 'dart:typed_data';

class AdminFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== USER MANAGEMENT ====================

  Stream<List<User>> streamAllUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
        });
  }

  Stream<List<User>> streamUsersByRole(String role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
        });
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate status user: $e');
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _db.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate role user: $e');
    }
  }

  /// Update user profile photo
  Future<void> updateUserProfilePhoto(String userId, File imageFile) async {
    try {
      // Validate image
      if (!ImgBBService.isValidImageFile(imageFile)) {
        throw Exception('Format gambar tidak didukung');
      }

      if (!await ImgBBService.isValidImageSize(imageFile)) {
        throw Exception('Ukuran gambar terlalu besar (max 32MB)');
      }

      // Upload to ImgBB
      final imageUrl = await ImgBBService.uploadImage(imageFile);
      if (imageUrl == null) {
        throw Exception('Gagal mengupload gambar');
      }

      // Update user document
      await _db.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate foto profil user: $e');
    }
  }

  /// Update user profile photo from bytes (untuk web)
  Future<void> updateUserProfilePhotoFromBytes(String userId, Uint8List imageBytes) async {
    try {
      // Validate image size
      if (!ImgBBService.isValidImageSizeFromBytes(imageBytes)) {
        throw Exception('Ukuran gambar terlalu besar (max 32MB)');
      }

      // Upload to ImgBB
      final imageUrl = await ImgBBService.uploadImageFromBytes(imageBytes);
      if (imageUrl == null) {
        throw Exception('Gagal mengupload gambar');
      }

      // Update user document
      await _db.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate foto profil user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Check if user has orders before deleting
      final userOrdersSnapshot =
          await _db
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .get();

      if (userOrdersSnapshot.docs.isNotEmpty) {
        throw Exception(
          'Tidak dapat menghapus user yang memiliki riwayat pesanan',
        );
      }

      await _db.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus user: $e');
    }
  }

  Future<Map<String, dynamic>> getUserOrderHistory(String userId) async {
    try {
      final ordersSnapshot =
          await _db
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      final orders =
          ordersSnapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

      double totalSpent = 0;
      for (var order in orders) {
        if (order.status == 'completed') {
          totalSpent += order.total;
        }
      }

      return {
        'orders': orders,
        'totalOrders': orders.length,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      throw Exception('Gagal mengambil riwayat pesanan user: $e');
    }
  }

  // ==================== CATEGORY MANAGEMENT ====================

  Stream<List<Category>> streamAllCategories() {
    return _db
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Category.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> addCategory(Category category) async {
    try {
      await _db.collection('categories').doc(category.id).set({
        ...category.toFirestore(),
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  Future<void> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _db.collection('categories').doc(categoryId).update(updates);
    } catch (e) {
      throw Exception('Gagal mengupdate kategori: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      // Cek apakah masih ada produk yang menggunakan kategori ini
      final productsQuery =
          await _db
              .collection('products')
              .where('categoryId', isEqualTo: categoryId)
              .get();

      if (productsQuery.docs.isNotEmpty) {
        throw Exception(
          'Tidak dapat menghapus kategori yang masih digunakan oleh produk',
        );
      }

      await _db.collection('categories').doc(categoryId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus kategori: $e');
    }
  }

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

  // ==================== PRODUCT MANAGEMENT ====================

  Stream<List<Product>> streamAllProductsAdmin() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  Stream<List<Product>> streamProductsByCategory(String categoryId) {
    return _db
        .collection('products')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  /// Add product dengan gambar
  Future<void> addProductWithImage(Product product, File? imageFile) async {
    try {
      String? imageUrl;
      
      if (imageFile != null) {
        // Validate image
        if (!ImgBBService.isValidImageFile(imageFile)) {
          throw Exception('Format gambar tidak didukung');
        }

        if (!await ImgBBService.isValidImageSize(imageFile)) {
          throw Exception('Ukuran gambar terlalu besar (max 32MB)');
        }

        // Upload to ImgBB
        imageUrl = await ImgBBService.uploadImage(imageFile);
        if (imageUrl == null) {
          throw Exception('Gagal mengupload gambar produk');
        }
      }

      // Create product data
      final productData = {
        ...product.toFirestore(),
        'createdAt': Timestamp.now(),
      };

      if (imageUrl != null) {
        productData['imageUrl'] = imageUrl;
      }

      await _db.collection('products').doc(product.id).set(productData);
    } catch (e) {
      throw Exception('Gagal menambah produk: $e');
    }
  }

  /// Add product dengan gambar dari bytes (untuk web)
  Future<void> addProductWithImageBytes(Product product, Uint8List? imageBytes) async {
    try {
      String? imageUrl;
      
      if (imageBytes != null) {
        // Validate image size
        if (!ImgBBService.isValidImageSizeFromBytes(imageBytes)) {
          throw Exception('Ukuran gambar terlalu besar (max 32MB)');
        }

        // Upload to ImgBB
        imageUrl = await ImgBBService.uploadImageFromBytes(imageBytes);
        if (imageUrl == null) {
          throw Exception('Gagal mengupload gambar produk');
        }
      }

      // Create product data
      final productData = {
        ...product.toFirestore(),
        'createdAt': Timestamp.now(),
      };

      if (imageUrl != null) {
        productData['imageUrl'] = imageUrl;
      }

      await _db.collection('products').doc(product.id).set(productData);
    } catch (e) {
      throw Exception('Gagal menambah produk: $e');
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _db.collection('products').doc(product.id).set({
        ...product.toFirestore(),
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal menambah produk: $e');
    }
  }

  /// Update product dengan gambar baru
  Future<void> updateProductWithImage(
    String productId,
    Map<String, dynamic> updates,
    File? newImageFile,
  ) async {
    try {
      if (newImageFile != null) {
        // Validate image
        if (!ImgBBService.isValidImageFile(newImageFile)) {
          throw Exception('Format gambar tidak didukung');
        }

        if (!await ImgBBService.isValidImageSize(newImageFile)) {
          throw Exception('Ukuran gambar terlalu besar (max 32MB)');
        }

        // Upload new image to ImgBB
        final imageUrl = await ImgBBService.uploadImage(newImageFile);
        if (imageUrl == null) {
          throw Exception('Gagal mengupload gambar produk');
        }

        updates['imageUrl'] = imageUrl;
      }

      updates['updatedAt'] = Timestamp.now();
      await _db.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Gagal mengupdate produk: $e');
    }
  }

  /// Update product dengan gambar dari bytes (untuk web)
  Future<void> updateProductWithImageBytes(
    String productId,
    Map<String, dynamic> updates,
    Uint8List? newImageBytes,
  ) async {
    try {
      if (newImageBytes != null) {
        // Validate image size
        if (!ImgBBService.isValidImageSizeFromBytes(newImageBytes)) {
          throw Exception('Ukuran gambar terlalu besar (max 32MB)');
        }

        // Upload new image to ImgBB
        final imageUrl = await ImgBBService.uploadImageFromBytes(newImageBytes);
        if (imageUrl == null) {
          throw Exception('Gagal mengupload gambar produk');
        }

        updates['imageUrl'] = imageUrl;
      }

      updates['updatedAt'] = Timestamp.now();
      await _db.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Gagal mengupdate produk: $e');
    }
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _db.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Gagal mengupdate produk: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _db.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate stok produk: $e');
    }
  }

  Future<void> toggleBestSeller(String productId, bool isBestSeller) async {
    try {
      await _db.collection('products').doc(productId).update({
        'isBestSeller': isBestSeller,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Gagal memperbarui status best seller: $e');
    }
  }

  Stream<List<Product>> streamLowStockProducts({int threshold = 5}) {
    return _db
        .collection('products')
        .where('stock', isLessThan: threshold)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  // ==================== ORDER MANAGEMENT ====================

  Stream<List<Order>> streamAllOrders() {
    return _db
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
        });
  }

  Stream<List<Order>> streamOrdersByStatus(String status) {
    return _db
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
        });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': status,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate status pesanan: $e');
    }
  }

  Future<void> bulkUpdateOrderStatus(
    List<String> orderIds,
    String status,
  ) async {
    try {
      final batch = _db.batch();

      for (String orderId in orderIds) {
        final orderRef = _db.collection('orders').doc(orderId);
        batch.update(orderRef, {
          'status': status,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal memperbarui status pesanan secara bulk: $e');
    }
  }

  // ==================== DASHBOARD ANALYTICS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Total products
      final productsSnapshot = await _db.collection('products').get();
      final totalProducts = productsSnapshot.docs.length;

      // Total orders
      final ordersSnapshot = await _db.collection('orders').get();
      final totalOrders = ordersSnapshot.docs.length;

      // Total users
      final usersSnapshot = await _db.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Total categories
      final categoriesSnapshot = await _db.collection('categories').get();
      final totalCategories = categoriesSnapshot.docs.length;

      // Pending orders
      final pendingOrdersSnapshot =
          await _db
              .collection('orders')
              .where('status', isEqualTo: 'pending')
              .get();
      final pendingOrders = pendingOrdersSnapshot.docs.length;

      // Low stock products (stock < 5)
      final lowStockSnapshot =
          await _db.collection('products').where('stock', isLessThan: 5).get();
      final lowStockProducts = lowStockSnapshot.docs.length;

      // Total revenue
      double totalRevenue = 0;
      for (var doc in ordersSnapshot.docs) {
        final order = Order.fromFirestore(doc);
        if (order.status == 'completed') {
          totalRevenue += order.total;
        }
      }

      return {
        'totalProducts': totalProducts,
        'totalOrders': totalOrders,
        'totalUsers': totalUsers,
        'totalCategories': totalCategories,
        'pendingOrders': pendingOrders,
        'lowStockProducts': lowStockProducts,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik dashboard: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 10,
  }) async {
    try {
      final ordersSnapshot = await _db.collection('orders').get();
      final Map<String, Map<String, dynamic>> productSales = {};

      for (var doc in ordersSnapshot.docs) {
        final order = Order.fromFirestore(doc);

        if (productSales.containsKey(order.productId)) {
          productSales[order.productId]!['totalQuantity'] += order.quantity;
          productSales[order.productId]!['totalRevenue'] += order.total;
        } else {
          productSales[order.productId] = {
            'productId': order.productId,
            'productName': order.productName,
            'totalQuantity': order.quantity,
            'totalRevenue': order.total,
            'image': order.productImage ?? '',
          };
        }
      }

      final sortedProducts = productSales.values.toList();
      sortedProducts.sort(
        (a, b) => b['totalQuantity'].compareTo(a['totalQuantity']),
      );

      return sortedProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Gagal mengambil produk terlaris: $e');
    }
  }

  Future<Map<String, dynamic>> getSalesAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _db.collection('orders');

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final orders =
          snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

      double totalRevenue = 0;
      int totalOrders = orders.length;
      int completedOrders = 0;
      Map<String, double> dailySales = {};

      for (var order in orders) {
        if (order.status == 'completed') {
          totalRevenue += order.total;
          completedOrders++;
        }

        final date = order.createdAt;
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        dailySales[dateKey] = (dailySales[dateKey] ?? 0) + order.total;
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'dailySales': dailySales,
        'averageOrderValue':
            completedOrders > 0 ? totalRevenue / completedOrders : 0,
      };
    } catch (e) {
      throw Exception('Gagal mengambil analitik penjualan: $e');
    }
  }

  // ==================== BULK OPERATIONS ====================

  Future<void> bulkUpdateProductStock(Map<String, int> stockUpdates) async {
    try {
      final batch = _db.batch();

      for (var entry in stockUpdates.entries) {
        final productRef = _db.collection('products').doc(entry.key);
        batch.update(productRef, {
          'stock': entry.value,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Gagal memperbarui stok secara bulk: $e');
    }
  }

  // ==================== ADDITIONAL METHODS FOR ADMIN CONTENT ====================

  // Method untuk mendapatkan product berdasarkan ID
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _db.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil produk: $e');
    }
  }

  // Method untuk mendapatkan user berdasarkan ID
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil user: $e');
    }
  }

  // Method untuk mendapatkan order berdasarkan ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal mengambil order: $e');
    }
  }

  // Method untuk search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot =
          await _db
              .collection('products')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: '${query}z')
              .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Gagal mencari produk: $e');
    }
  }
}