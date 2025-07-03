import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roti_nyaman/models/category.dart';
import 'package:roti_nyaman/view_models/add_edit_product_viewmodel.dart';

class AddEditProductDialog extends StatelessWidget {
  const AddEditProductDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Pesan ini akan muncul di Debug Console saat UI form dibuat
    print("DEBUG: Membangun UI AddEditProductDialog...");
    final viewModel = Provider.of<AddEditProductViewModel>(
      context,
      listen: false,
    );

    return AlertDialog(
      title: const Text('Tambah Produk Baru'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: viewModel.formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: viewModel.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: viewModel.descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator:
                      (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: viewModel.priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: viewModel.stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok Awal',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Category>>(
                  future: viewModel.getCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Error: Kategori tidak ditemukan.');
                    }
                    final categories = snapshot.data!;
                    return Consumer<AddEditProductViewModel>(
                      builder:
                          (
                            context,
                            vm,
                            child,
                          ) => DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              border: OutlineInputBorder(),
                            ),
                            value: vm.selectedCategoryId,
                            hint: const Text('Pilih Kategori'),
                            items:
                                categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  );
                                }).toList(),
                            onChanged: (value) => vm.setSelectedCategory(value),
                            validator:
                                (v) =>
                                    v == null ? 'Wajib pilih kategori' : null,
                          ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer<AddEditProductViewModel>(
                  builder:
                      (context, vm, child) => Row(
                        children: [
                          ElevatedButton(
                            onPressed: vm.pickImage,
                            child: const Text('Pilih Gambar'),
                          ),
                          const SizedBox(width: 16),
                          vm.imageBytes != null
                              ? Image.memory(
                                vm.imageBytes!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                              : Container(
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
        Consumer<AddEditProductViewModel>(
          builder:
              (context, vm, child) => ElevatedButton(
                onPressed:
                    vm.isLoading
                        ? null
                        : () async {
                          try {
                            await vm.saveProduct();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Produk berhasil disimpan!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal menyimpan: ${e.toString().replaceAll("Exception: ", "")}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                child:
                    vm.isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : const Text('Simpan'),
              ),
        ),
      ],
    );
  }
}
