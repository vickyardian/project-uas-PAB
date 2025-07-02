//services/imgbb_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImgBBService {
  static const String _apiKey =
      'https://ibb.co/gL9ZG09z'; // Ganti dengan API key ImgBB Anda
  static const String _baseUrl = 'https://api.imgbb.com/1/upload';

  /// Upload gambar dari File path
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      return await _uploadToImgBB(base64Image);
    } catch (e) {
      print('Error uploading image from file: $e');
      return null;
    }
  }

  /// Upload gambar dari Uint8List (untuk web)
  static Future<String?> uploadImageFromBytes(Uint8List imageBytes) async {
    try {
      final base64Image = base64Encode(imageBytes);
      return await _uploadToImgBB(base64Image);
    } catch (e) {
      print('Error uploading image from bytes: $e');
      return null;
    }
  }

  /// Upload gambar dari base64 string
  static Future<String?> uploadImageFromBase64(String base64Image) async {
    try {
      return await _uploadToImgBB(base64Image);
    } catch (e) {
      print('Error uploading image from base64: $e');
      return null;
    }
  }

  /// Method private untuk upload ke ImgBB
  static Future<String?> _uploadToImgBB(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'key': _apiKey,
          'image': base64Image,
          'expiration': '0', // 0 = tidak expired
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success']) {
          return jsonResponse['data']['url'];
        } else {
          print('ImgBB API Error: ${jsonResponse['error']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network Error: $e');
      return null;
    }
  }

  /// Delete gambar dari ImgBB (opsional - ImgBB tidak menyediakan delete API)
  /// Jika ingin menghapus gambar lama, Anda perlu menyimpan delete_url dari response
  static Future<bool> deleteImage(String deleteUrl) async {
    try {
      final response = await http.get(Uri.parse(deleteUrl));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Validate image file
  static bool isValidImageFile(File file) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final fileName = file.path.toLowerCase();

    return validExtensions.any((ext) => fileName.endsWith(ext));
  }

  /// Validate image size (max 32MB untuk ImgBB)
  static Future<bool> isValidImageSize(File file) async {
    try {
      final fileSize = await file.length();
      const maxSizeInBytes = 32 * 1024 * 1024; // 32MB
      return fileSize <= maxSizeInBytes;
    } catch (e) {
      return false;
    }
  }

  /// Validate image from bytes
  static bool isValidImageSizeFromBytes(Uint8List bytes) {
    const maxSizeInBytes = 32 * 1024 * 1024; // 32MB
    return bytes.length <= maxSizeInBytes;
  }
}
