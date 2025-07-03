// lib/services/cloudinary_service.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service untuk menangani semua interaksi dengan API Cloudinary.
class CloudinaryService {
  // --- KREDENSIAL DARI DASHBOARD CLOUDINARY ANDA ---
  static const String _cloudName = "dhttkroog"; // Nama Cloud Anda
  static const String _uploadPreset = "roti_nyaman"; // Upload Preset Anda
  static const String _apiKey = "973136922711561"; // API Key Anda

  /// Mengunggah gambar ke Cloudinary.
  ///
  /// Fungsi ini secara otomatis memilih metode yang tepat
  /// berdasarkan platform (web atau mobile).
  Future<String?> uploadImage({XFile? imageFile, Uint8List? imageBytes}) async {
    // Validasi input untuk mencegah error
    if (imageFile == null && imageBytes == null) {
      throw ArgumentError("Harap sediakan imageFile atau imageBytes.");
    }
    if (!kIsWeb && imageFile == null) {
      throw ArgumentError("imageFile diperlukan untuk platform mobile.");
    }
    if (kIsWeb && imageBytes == null) {
      throw ArgumentError("imageBytes diperlukan untuk platform web.");
    }

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );
    final request =
        http.MultipartRequest('POST', url)
          ..fields['api_key'] = _apiKey
          ..fields['upload_preset'] = _uploadPreset;

    // Tambahkan file berdasarkan platform
    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes!,
          filename: 'upload.jpg',
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile!.path),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonMap = json.decode(responseBody);
        debugPrint("✅ Upload ke Cloudinary berhasil!");
        return jsonMap['secure_url'];
      } else {
        // Tampilkan pesan error yang jelas dari server
        debugPrint("❌ Gagal mengunggah. Status: ${response.statusCode}");
        debugPrint("🔍 Pesan Error dari Cloudinary: $responseBody");
        return null;
      }
    } catch (e) {
      debugPrint("🚨 Terjadi error koneksi saat mengunggah: $e");
      rethrow; // Lempar kembali error untuk ditangani oleh UI
    }
  }

  /// Menghapus gambar dari Cloudinary berdasarkan URL-nya.
  /// Catatan: Memerlukan pengaturan "Signed" pada upload preset Anda
  /// dan penggunaan API Secret untuk otentikasi.
  /// Ini adalah fungsionalitas lanjutan.
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Logika untuk menghapus gambar dari Cloudinary akan ditambahkan di sini
      // jika diperlukan di masa depan.
      debugPrint(
        "Fungsi deleteImage dipanggil untuk: $imageUrl (belum diimplementasi)",
      );
    } catch (e) {
      debugPrint("Error saat mencoba menghapus gambar: $e");
      // Tidak melempar error agar tidak menghentikan alur utama
    }
  }
}
