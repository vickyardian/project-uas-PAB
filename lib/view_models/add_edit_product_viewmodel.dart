// lib/view_models/add_edit_product_viewmodel.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/cloudinary_service.dart';

class AddEditProductViewModel extends ChangeNotifier {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AddEditProductViewModel() {
    print("DEBUG: AddEditProductViewModel berhasil dibuat.");
  }

  // --- State untuk Form dan UI ---
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  Uint8List? get imageBytes => _imageBytes;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- Logika dan Fungsi ---

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSelectedCategory(String? value) {
    _selectedCategoryId = value;
    notifyListeners();
  }

  /// Memilih gambar dari galeri.
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      _imageFile = file;
      _imageBytes = await file.readAsBytes();
      notifyListeners();
    }
  }

  /// Mengambil daftar kategori dari Firestore.
  Future<List<Category>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  /// Fungsi utama untuk menyimpan produk.
  Future<void> saveProduct() async {
    // 1. Validasi input
    if (formKey.currentState?.validate() != true ||
        _selectedCategoryId == null ||
        (_imageFile == null && _imageBytes == null)) {
      throw Exception('Harap isi semua data dan pilih gambar.');
    }

    setLoading(true);

    try {
      // 2. Panggil fungsi upload yang sudah disatukan
      // Ini akan otomatis menangani platform web atau mobile.
      final imageUrl = await _cloudinaryService.uploadImage(
        imageFile: _imageFile, // Argumen ini digunakan di mobile
        imageBytes: _imageBytes, // Argumen ini digunakan di web
      );

      // 3. Pastikan URL berhasil didapat
      if (imageUrl == null) {
        throw Exception("Gagal mengunggah gambar.");
      }

      // 4. Buat objek produk dengan URL dari Cloudinary
      final newProduct = Product(
        id: '', // Firestore akan membuat ID secara otomatis
        name: nameController.text,
        description: descriptionController.text,
        price: double.parse(priceController.text.replaceAll('.', '')),
        stock: int.parse(stockController.text),
        categoryId: _selectedCategoryId!,
        imageUrl: imageUrl, // <-- Gunakan URL yang didapat
        createdAt: DateTime.now(),
      );

      // 5. Simpan ke Firestore
      await _firestore.collection('products').add(newProduct.toFirestore());
    } catch (e) {
      // Lempar kembali error agar bisa ditangkap dan ditampilkan oleh UI
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
