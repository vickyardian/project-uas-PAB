//services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roti_nyaman/models/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Product>> streamAllProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Product>> streamBestSellerProducts() {
    return _db
        .collection('products')
        .where('isBestSeller', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .toList();
        });
  }

  Stream<Product> streamProduct(String id) {
    return _db
        .collection('products')
        .doc(id)
        .snapshots()
        .map((doc) => Product.fromFirestore(doc));
  }

  Future<void> addSampleProduct() async {
    final product = Product(
      id: '1',
      name: 'Roti Coklat',
      price: 'Rp 15000',
      image: 'assets/images/roti.jpg',
      description: 'Roti lembut dengan isian coklat lezat',
      stock: 10,
      category: 'Roti',
      isLiked: false,
    );
    await _db.collection('products').doc(product.id).set(product.toFirestore());
  }

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

  Future<void> updateLikeStatus(String productId, bool isLiked) async {
    try {
      await _db.collection('products').doc(productId).update({
        'isLiked': isLiked,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui status suka: $e');
    }
  }

  // DIPERBAIKI: Update cart item instead of always adding new
  Future<void> updateCartItem(
    String userId,
    Product product,
    int quantityToAdd,
  ) async {
    try {
      final cartRef = _db.collection('users').doc(userId).collection('cart');
      final existingQuery =
          await cartRef.where('productId', isEqualTo: product.id).get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing item
        final existingDoc = existingQuery.docs.first;
        final currentQuantity = existingDoc.data()['quantity'] as int;
        await existingDoc.reference.update({
          'quantity': currentQuantity + quantityToAdd,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item
        final cartItem = {
          'productId': product.id,
          'name': product.name,
          'price': product.price,
          'image': product.image,
          'quantity': quantityToAdd,
          'timestamp': FieldValue.serverTimestamp(),
        };
        await cartRef.add(cartItem);
      }
    } catch (e) {
      throw Exception('Gagal menambahkan ke keranjang: $e');
    }
  }

  // BARU: Batch update untuk cart
  Future<void> updateUserCartBatch(
    String userId,
    Map<String, int> updatedCart,
    Map<String, Product> productCache,
  ) async {
    try {
      final batch = _db.batch();
      final cartRef = _db.collection('users').doc(userId).collection('cart');

      // Hapus semua item cart yang ada
      final existingCart = await cartRef.get();
      for (var doc in existingCart.docs) {
        batch.delete(doc.reference);
      }

      // Tambahkan item baru
      for (var entry in updatedCart.entries) {
        String productId = entry.key;
        int quantity = entry.value;
        if (quantity > 0 && productCache.containsKey(productId)) {
          final product = productCache[productId]!;
          final cartItem = {
            'productId': product.id,
            'name': product.name,
            'price': product.price,
            'image': product.image,
            'quantity': quantity,
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

  // DEPRECATED: Use updateCartItem instead
  @deprecated
  Future<void> addToCart(String userId, Product product, int quantity) async {
    await updateCartItem(userId, product, quantity);
  }

  Future<void> createOrder(String userId, Product product, int quantity) async {
    try {
      // Cek stok
      final productRef = _db.collection('products').doc(product.id);
      final doc = await productRef.get();
      if (!doc.exists || (doc.data()!['stock'] as int) < quantity) {
        throw Exception('Stok tidak mencukupi');
      }

      // Buat pesanan
      final order = {
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'image': product.image,
        'quantity': quantity,
        'total':
            double.parse(product.price.replaceAll(RegExp(r'[^\d]'), '')) *
            quantity,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };
      await _db.collection('users').doc(userId).collection('orders').add(order);

      // Perbarui stok
      await productRef.update({'stock': FieldValue.increment(-quantity)});
    } catch (e) {
      throw Exception('Gagal memproses pesanan: $e');
    }
  }

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

  // BARU: Remove item from cart
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

  // BARU: Clear entire cart
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
}
