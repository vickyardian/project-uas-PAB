// lib/widgets/admins/admin_content.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/screens/admins/dialogs/add_edit_product_dialog.dart';
import 'package:roti_nyaman/services/admin_firestore_service.dart';
import 'package:roti_nyaman/view_models/add_edit_product_viewmodel.dart';

// Import model lain yang mungkin dibutuhkan oleh fungsi lain di file ini
import 'package:roti_nyaman/models/category.dart';
import 'package:roti_nyaman/models/order.dart';
import 'package:roti_nyaman/models/user.dart';

class AdminContent extends StatefulWidget {
  final int selectedIndex;
  final AdminFirestoreService adminService;

  const AdminContent({
    super.key,
    required this.selectedIndex,
    required this.adminService,
  });

  @override
  State<AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends State<AdminContent> {
  @override
  Widget build(BuildContext context) {
    switch (widget.selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildProductManagement(); // Fokus di sini
      case 2:
        return _buildCategoryManagement();
      case 3:
        return _buildOrderManagement();
      case 4:
        return _buildUserManagement();
      case 5:
        return _buildAnalytics();
      default:
        return _buildDashboard();
    }
  }

  // ================= WIDGET PRODUCT MANAGEMENT (DIPERBAIKI) =================
  Widget _buildProductManagement() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Produk',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Produk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Product>>(
              // [FIX] Menggunakan nama stream yang benar: streamAllProductsAdmin()
              stream: widget.adminService.streamAllProductsAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada produk di database.'),
                  );
                }

                final products = snapshot.data!;
                // [FIX] Menggunakan LayoutBuilder dan SingleChildScrollView agar responsif
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nama')),
                            DataColumn(label: Text('Harga')),
                            DataColumn(label: Text('Stok')),
                            DataColumn(label: Text('Aksi')),
                          ],
                          rows:
                              products.map((product) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(product.name)),
                                    DataCell(
                                      Text(
                                        'Rp ${product.price.toStringAsFixed(0)}',
                                      ),
                                    ),
                                    DataCell(Text('${product.stock}')),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              // TODO: Implement edit
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            // [FIX] Memanggil fungsi delete dengan argumen yang benar
                                            onPressed:
                                                () =>
                                                    _deleteProductConfirmation(
                                                      product,
                                                    ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // [FIX] Fungsi dialog yang benar, tidak ada perubahan
  void _showAddProductDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ChangeNotifierProvider(
          create: (_) => AddEditProductViewModel(widget.adminService),
          child: const AddEditProductDialog(),
        );
      },
    );
  }

  // [FIX] Fungsi konfirmasi hapus yang memanggil service dengan benar
  void _deleteProductConfirmation(Product product) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Anda yakin ingin menghapus produk "${product.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await widget.adminService.deleteProduct(
                      product.id,
                      product.imageUrl,
                    );
                    Navigator.pop(context); // Tutup dialog setelah berhasil
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Produk berhasil dihapus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  // Bagian lain biarkan sama... (Saya sertakan lagi untuk kelengkapan)
  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang di Admin Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          FutureBuilder<Map<String, dynamic>>(
            future: widget.adminService.getDashboardStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final stats = snapshot.data!;
              return Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildStatCard(
                      'Total Produk',
                      '${stats['totalProducts']}',
                      Icons.shopping_bag,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Pesanan',
                      '${stats['totalOrders']}',
                      Icons.receipt_long,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Total User',
                      '${stats['totalUsers']}',
                      Icons.people,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Pesanan Pending',
                      '${stats['pendingOrders']}',
                      Icons.pending,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Stok Rendah',
                      '${stats['lowStockProducts']}',
                      Icons.warning,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Total Revenue',
                      'Rp ${stats['totalRevenue'].toStringAsFixed(0)}',
                      Icons.monetization_on,
                      Colors.teal,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PRODUCT MANAGEMENT (VERSI FINAL) ====================

  // --- FUNGSI DIALOG YANG SUDAH DIGANTI DENGAN YANG BENAR ---

  // Sisa kode lainnya... (biarkan sama)

  // Semua fungsi lain seperti _buildCategoryManagement, _buildOrderManagement, dll.
  // tidak perlu diubah. Saya tidak sertakan lagi agar tidak terlalu panjang.
  // Cukup salin bagian atas dan dua blok kode yang saya beri komentar.

  // Category Management
  Widget _buildCategoryManagement() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Kategori',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddCategoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Kategori'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: widget.adminService.streamAllCategories(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada kategori'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final category = snapshot.data![index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.category),
                        title: Text(category.name),
                        // Fixed: Handle potential null description
                        subtitle: Text(category.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed:
                                  () => _showEditCategoryDialog(category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(category.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Order Management
  Widget _buildOrderManagement() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Manajemen Pesanan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Order>>(
              // Fixed: Cast the stream to proper type
              stream: widget.adminService.streamAllOrders().cast<List<Order>>(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada pesanan'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('User ID')),
                      DataColumn(label: Text('Produk')),
                      DataColumn(label: Text('Jumlah')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows:
                        snapshot.data!.map((order) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  order.id.length > 8
                                      ? '${order.id.substring(0, 8)}...'
                                      : order.id,
                                ),
                              ),
                              DataCell(
                                Text(
                                  order.userId.length > 8
                                      ? '${order.userId.substring(0, 8)}...'
                                      : order.userId,
                                ),
                              ),
                              DataCell(Text(order.productName)),
                              DataCell(Text('${order.quantity}')),
                              DataCell(
                                Text('Rp ${order.total.toStringAsFixed(0)}'),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                DropdownButton<String>(
                                  value: order.status,
                                  items:
                                      [
                                            'pending',
                                            'processing',
                                            'completed',
                                            'cancelled',
                                          ]
                                          .map(
                                            (status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      _updateOrderStatus(order.id, newStatus);
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // User Management
  Widget _buildUserManagement() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Manajemen User',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: widget.adminService.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada user'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data![index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          // Fixed: Use profilePhotoUrl from User model
                          backgroundImage:
                              user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                          child:
                              user.profileImageUrl == null
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text('${user.email}\nRole: ${user.role}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: user.isActive,
                              onChanged:
                                  (value) => _updateUserStatus(user.id, value),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteUser(user.id);
                                } else {
                                  _updateUserRole(user.id, value);
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'user',
                                      child: Text('Set sebagai User'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'admin',
                                      child: Text('Set sebagai Admin'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Hapus User'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Analytics
  Widget _buildAnalytics() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics & Laporan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Selling Products
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produk Terlaris',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: widget.adminService.getTopSellingProducts(
                              limit: 5,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text('Tidak ada data');
                              }

                              return Column(
                                children:
                                    snapshot.data!.map((product) {
                                      return ListTile(
                                        title: Text(product['productName']),
                                        subtitle: Text(
                                          'Terjual: ${product['totalQuantity']} unit',
                                        ),
                                        trailing: Text(
                                          'Rp ${product['totalRevenue'].toStringAsFixed(0)}',
                                        ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Low Stock Products
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produk Stok Rendah',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<List<Product>>(
                            stream:
                                widget.adminService.streamLowStockProducts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text(
                                  'Semua produk memiliki stok yang cukup',
                                );
                              }

                              return Column(
                                children:
                                    snapshot.data!.map((product) {
                                      return ListTile(
                                        title: Text(product.name),
                                        subtitle: Text(
                                          'Stok tersisa: ${product.stock}',
                                        ),
                                        trailing: const Icon(
                                          Icons.warning,
                                          color: Colors.red,
                                        ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Action Methods

  void _updateOrderStatus(String orderId, String status) {
    widget.adminService.updateOrderStatus(orderId, status);
  }

  void _updateUserStatus(String userId, bool isActive) {
    widget.adminService.updateUserStatus(userId, isActive);
  }

  void _updateUserRole(String userId, String role) {
    widget.adminService.updateUserRole(userId, role);
  }

  void _deleteCategory(String categoryId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Yakin ingin menghapus kategori ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.adminService.deleteCategory(categoryId);
                  Navigator.pop(context);
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  void _deleteUser(String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Yakin ingin menghapus user ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.adminService.deleteUser(userId);
                  Navigator.pop(context);
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  // Dialog Methods

  void _showAddCategoryDialog() {
    // Implement add category dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tambah Kategori'),
            content: const Text(
              'Form tambah kategori akan diimplementasi disini',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    // Implement edit category dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Kategori'),
            content: Text('Form edit kategori untuk: ${category.name}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }
}
