// lib/widgets/admins/content/product_management_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roti_nyaman/services/admin_firestore_service.dart';
import 'package:roti_nyaman/view_models/add_edit_product_viewmodel.dart';
import 'package:roti_nyaman/screens/admins/dialogs/add_edit_product_dialog.dart';

class ProductManagementContent extends StatelessWidget {
  final AdminFirestoreService adminService;
  const ProductManagementContent({super.key, required this.adminService});

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // User tidak bisa menutup dialog dengan klik di luar
      builder:
          (_) => ChangeNotifierProvider(
            create: (_) => AddEditProductViewModel(adminService),
            child: const AddEditProductDialog(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Anda bisa menampilkan daftar produk di sini menggunakan StreamBuilder
      // dari adminService.streamAllProductsAdmin()
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Gunakan tombol + di pojok kanan bawah untuk menambah produk.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            // Di sini Anda bisa menambahkan widget untuk menampilkan daftar produk
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        tooltip: 'Tambah Produk',
        backgroundColor: Colors.orange.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }
}
