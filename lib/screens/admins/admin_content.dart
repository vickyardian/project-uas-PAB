// lib/widgets/admins/admin_content.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roti_nyaman/models/category.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/services/admin_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminContent extends StatelessWidget {
  final int selectedIndex;
  final AdminFirestoreService adminService;

  const AdminContent({
    super.key,
    required this.selectedIndex,
    required this.adminService,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return const Center(child: Text('Konten Dashboard'));
      case 1:
        // Saat menu "Produk" dipilih, kita panggil method untuk membangun UI-nya
        return _buildProductManagement(context);
      case 2:
        return const Center(child: Text('Konten Manajemen Kategori'));
      case 3:
        return const Center(child: Text('Konten Manajemen Pesanan'));
      case 4:
        return const Center(child: Text('Konten Manajemen User'));
      case 5:
        return const Center(child: Text('Konten Laporan & Analytics'));
      default:
        return const Center(child: Text('Pilih salah satu menu'));
    }
  }

  // Method untuk membangun UI Manajemen Produk
  Widget _buildProductManagement(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Daftar produk akan muncul di sini.\nGunakan tombol + di pojok kanan bawah.',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context, adminService),
        tooltip: 'Tambah Produk',
        backgroundColor: Colors.orange.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Method untuk menampilkan dialog form tambah produk yang BENAR dan FUNGSIONAL
  void _showAddProductDialog(
    BuildContext context,
    AdminFirestoreService adminService,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    String? selectedCategoryId;
    Uint8List? imageBytes;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Produk Baru'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Harga',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stok Awal',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Category>>(
                          // --- PERUBAHAN DI SINI ---
                          future: adminService.getAllCategoriesOnce(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text(
                                'Error: Tidak ada kategori ditemukan.',
                              );
                            }
                            final categories = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedCategoryId,
                              hint: const Text('Pilih Kategori'),
                              items:
                                  categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat.id,
                                      child: Text(cat.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategoryId = value;
                                });
                              },
                              validator:
                                  (v) =>
                                      v == null ? 'Wajib pilih kategori' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final file = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 80,
                                );
                                if (file != null) {
                                  final bytes = await file.readAsBytes();
                                  setState(() {
                                    imageBytes = bytes;
                                  });
                                }
                              },
                              child: const Text('Pilih Gambar'),
                            ),
                            const SizedBox(width: 16),
                            if (imageBytes != null)
                              Image.memory(
                                imageBytes!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        final newProductId =
                            FirebaseFirestore.instance
                                .collection('products')
                                .doc()
                                .id;
                        final newProduct = Product(
                          id: newProductId,
                          name: nameController.text,
                          description: descriptionController.text,
                          price: double.parse(priceController.text),
                          stock: int.parse(stockController.text),
                          categoryId: selectedCategoryId!,
                          createdAt: DateTime.now(),
                        );

                        await adminService.addProductWithImageBytes(
                          newProduct,
                          imageBytes,
                        );

                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Produk berhasil disimpan!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal menyimpan: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
