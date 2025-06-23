// lib/viewmodels/add_edit_product_viewmodel.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roti_nyaman/models/category.dart';
import 'package:roti_nyaman/models/product.dart';
import 'package:roti_nyaman/services/admin_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditProductViewModel extends ChangeNotifier {
  final AdminFirestoreService _adminService;

  AddEditProductViewModel(this._adminService) {
    fetchCategories();
  }

  // Form Controllers
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  // State
  List<Category> _categories = [];
  List<Category> get categories => _categories;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    try {
      // Ambil data kategori dari stream
      _categories = await _adminService.streamAllCategories().first;
      notifyListeners();
    } catch (e) {
      // Handle error jika diperlukan
      print('Gagal mengambil kategori: $e');
    }
  }

  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    _pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (_pickedImage != null) {
      _imageBytes = await _pickedImage!.readAsBytes();
    }
    notifyListeners();
  }

  Future<bool> saveProduct() async {
    if (!formKey.currentState!.validate() || _selectedCategoryId == null) {
      return false;
    }

    setLoading(true);

    try {
      final newProductId =
          FirebaseFirestore.instance.collection('products').doc().id;

      final newProduct = Product(
        id: newProductId,
        name: nameController.text,
        description: descriptionController.text,
        price: double.tryParse(priceController.text) ?? 0.0,
        stock: int.tryParse(stockController.text) ?? 0,
        categoryId: _selectedCategoryId!,
        createdAt: DateTime.now(),
      );

      // Gunakan method dari service Anda untuk menambah produk
      await _adminService.addProductWithImageBytes(newProduct, _imageBytes);

      setLoading(false);
      return true;
    } catch (e) {
      print('Error saat menyimpan produk: $e');
      setLoading(false);
      return false;
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
