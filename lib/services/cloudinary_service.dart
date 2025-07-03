// lib/services/cloudinary_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service untuk menangani semua interaksi dengan API Cloudinary.
class CloudinaryService {
  // --- KREDENSIAL DARI DASHBOARD CLOUDINARY ANDA ---
  // Pastikan ini benar dan tidak ada salah ketik.
  static const String _cloudName = "dhttkroog"; // <-- SUDAH DIPERBAIKI
  static const String _uploadPreset = "roti_nyaman";
  static const String _apiKey = "973136922711561"; // <-- WAJIB DIGANTI

  /// Mengunggah gambar ke Cloudinary.
  ///
  /// Fungsi ini secara otomatis memilih metode yang tepat
  /// berdasarkan platform (web atau mobile).
  Future<String?> uploadImage({XFile? imageFile, Uint8List? imageBytes}) async {
    // Validasi input untuk mencegah error
    if (!kIsWeb && imageFile == null) {
      throw ArgumentError("imageFile diperlukan untuk platform mobile.");
    }
    if (kIsWeb && imageBytes == null) {
      throw ArgumentError("imageBytes diperlukan untuk platform web.");
    }

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );
    final request = http.MultipartRequest('POST', url);

    // Tambahkan semua kredensial yang diperlukan ke dalam request
    request.fields['api_key'] = _apiKey;
    request.fields['upload_preset'] = _uploadPreset;

    // Tambahkan file berdasarkan platform
    if (kIsWeb) {
      // Untuk Web, kita menggunakan data bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes!,
          filename: 'upload.jpg', // Nama file default
        ),
      );
    } else {
      // Untuk Mobile/Desktop, kita menggunakan path file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile!.path),
      );
    }

    try {
      final response = await request.send();
      // Selalu baca respons untuk mendapatkan detail error jika ada
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Jika berhasil (200 OK), ambil URL gambar
        final jsonMap = json.decode(responseBody);
        print("✅ Upload ke Cloudinary berhasil!");
        return jsonMap['secure_url'];
      } else {
        // Jika gagal, tampilkan pesan error yang jelas dari server
        print("❌ Gagal mengunggah. Status: ${response.statusCode}");
        print("🔍 Pesan Error dari Cloudinary: $responseBody");
        return null;
      }
    } catch (e) {
      print("🚨 Terjadi error koneksi saat mengunggah: $e");
      rethrow; // Lempar kembali error untuk ditangani oleh ViewModel
    }
  }
}
