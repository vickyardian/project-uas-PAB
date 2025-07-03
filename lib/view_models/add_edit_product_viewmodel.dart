import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/services/admin_firestore_service.dart';
import 'package:roti_nyaman/models/category.dart';

class AddEditProductViewModel extends ChangeNotifier {
  final AdminFirestoreService _adminService;

  AddEditProductViewModel(this._adminService) {
    // Pesan ini akan muncul di Debug Console saat dialog disiapkan
    print("DEBUG: AddEditProductViewModel berhasil dibuat.");
  }

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSelectedCategory(String? value) {
    _selectedCategoryId = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      _imageBytes = await file.readAsBytes();
      notifyListeners();
    }
  }

  Future<List<Category>> getCategories() {
    return _adminService.getAllCategoriesOnce();
  }

  Future<void> saveProduct() async {
    if (formKey.currentState?.validate() != true ||
        _selectedCategoryId == null ||
        _imageBytes == null) {
      throw Exception('Harap isi semua data dan pilih gambar.');
    }

    setLoading(true);

    try {
      final newProductId =
          FirebaseFirestore.instance.collection('products').doc().id;
      final newProduct = Product(
        id: newProductId,
        name: nameController.text,
        description: descriptionController.text,
        price: double.parse(priceController.text),
        stock: int.parse(stockController.text),
        categoryId: _selectedCategoryId!,
        createdAt: DateTime.now(),
      );

      await _adminService.addProductWithImageBytes(newProduct, _imageBytes);
    } catch (e) {
      // Re-throw error untuk ditangkap UI
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }
}
