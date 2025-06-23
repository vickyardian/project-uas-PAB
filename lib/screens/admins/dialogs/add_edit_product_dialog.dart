// lib/widgets/admins/dialogs/add_edit_product_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roti_nyaman/viewmodels/add_edit_product_viewmodel.dart';

class AddEditProductDialog extends StatelessWidget {
  const AddEditProductDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddEditProductViewModel>();

    return AlertDialog(
      title: const Text('Tambah Produk Baru'),
      content: SizedBox(
        width: 500, // Lebar dialog
        child: SingleChildScrollView(
          child: Form(
            key: viewModel.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input Nama Produk
                TextFormField(
                  controller: viewModel.nameController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Input Deskripsi
                TextFormField(
                  controller: viewModel.descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Input Harga
                TextFormField(
                  controller: viewModel.priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Input Stok
                TextFormField(
                  controller: viewModel.stockController,
                  decoration: const InputDecoration(labelText: 'Stok Awal'),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Dropdown Kategori
                if (viewModel.categories.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: viewModel.selectedCategoryId,
                    hint: const Text('Pilih Kategori'),
                    items:
                        viewModel.categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      viewModel.setSelectedCategory(value);
                    },
                    validator:
                        (value) =>
                            value == null ? 'Wajib pilih kategori' : null,
                  ),
                const SizedBox(height: 16),

                // Pilih Gambar
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: viewModel.pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar'),
                    ),
                    const SizedBox(width: 16),
                    if (viewModel.imageBytes != null)
                      Image.memory(
                        viewModel.imageBytes!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      )
                    else
                      const Text('Belum ada gambar'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed:
              viewModel.isLoading
                  ? null
                  : () async {
                    bool success = await viewModel.saveProduct();
                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Produk berhasil disimpan!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gagal menyimpan. Periksa kembali semua isian.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
          child:
              viewModel.isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Simpan'),
        ),
      ],
    );
  }
}
