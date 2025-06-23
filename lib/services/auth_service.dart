//services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roti_nyaman/models/user.dart';

// Custom Exception for Authentication Errors
class AuthException implements Exception {
  final String message;
  final String code;

  AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException($code): $message';
}

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mendapatkan pengguna saat ini
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Stream untuk perubahan status autentikasi
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Login dengan email dan password
  Future<firebase_auth.User?> loginUser(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw AuthException(
          'Email dan password tidak boleh kosong',
          'INVALID_INPUT',
        );
      }
      firebase_auth.UserCredential credential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      return credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Terjadi kesalahan saat login: $e', 'UNKNOWN_ERROR');
    }
  }

  // Registrasi pengguna baru
  Future<firebase_auth.User?> registerUser(
    String name,
    String email,
    String password,
  ) async {
    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw AuthException(
          'Nama, email, dan password tidak boleh kosong',
          'INVALID_INPUT',
        );
      }

      firebase_auth.UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Buat User object sesuai model yang ada
      final user = User(
        id: credential.user!.uid,
        name: name,
        email: email.trim(),
        role: 'customer', // Default role customer (bukan admin)
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Simpan ke Firestore
      await _db.collection('users').doc(user.id).set(user.toFirestore());

      return credential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException(
        'Terjadi kesalahan saat registrasi: $e',
        'UNKNOWN_ERROR',
      );
    }
  }

  // Login dengan Google
  Future<firebase_auth.User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User membatalkan login, return null (bukan throw exception)
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw AuthException(
          'Gagal mendapatkan kredensial Google',
          'INVALID_CREDENTIAL',
        );
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      firebase_auth.UserCredential userCredential = await _auth
          .signInWithCredential(credential);

      // Cek apakah user sudah ada di Firestore
      final userDoc =
          await _db.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        // Buat User baru jika belum ada
        final user = User(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Pengguna Google',
          email: userCredential.user!.email ?? '',
          role: 'customer', // Default role customer
          createdAt: DateTime.now(),
          isActive: true,
        );

        await _db.collection('users').doc(user.id).set(user.toFirestore());
      }

      return userCredential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on PlatformException catch (e) {
      throw _handleGoogleSignInException(e);
    } catch (e) {
      throw AuthException(
        'Terjadi kesalahan saat login dengan Google: $e',
        'UNKNOWN_ERROR',
      );
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw AuthException('Email tidak boleh kosong', 'INVALID_INPUT');
      }
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException(
        'Terjadi kesalahan saat mengirim email reset: $e',
        'UNKNOWN_ERROR',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Terjadi kesalahan saat logout: $e', 'LOGOUT_ERROR');
    }
  }

  // Mendapatkan data pengguna dari Firestore
  Future<User?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }

      // Jika tidak ada di Firestore, buat default user
      final defaultUser = User(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        role: 'customer',
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Simpan ke Firestore untuk konsistensi dengan merge option
      await _db
          .collection('users')
          .doc(user.uid)
          .set(defaultUser.toFirestore(), SetOptions(merge: true));

      return defaultUser;
    } catch (e) {
      throw AuthException('Gagal mengambil data pengguna: $e', 'FETCH_ERROR');
    }
  }

  // Ganti fungsi isAdmin() yang lama dengan yang ini
  Future<bool> isAdmin() async {
    print('--- Memulai Pengecekan Admin ---');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[DEBUG] isAdmin: Gagal, tidak ada pengguna yang login.');
        print('--- Pengecekan Admin Selesai ---');
        return false;
      }

      print('[DEBUG] isAdmin: User UID yang akan dicek: ${user.uid}');

      final doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists) {
        print('[DEBUG] isAdmin: Dokumen ditemukan!');
        print('[DEBUG] isAdmin: Data di dalam dokumen: ${doc.data()}');

        final userData = User.fromFirestore(doc);
        final role = userData.role;
        print('[DEBUG] isAdmin: Role dari data adalah: "$role"');

        final bool result = role == 'admin';
        print(
          '[DEBUG] isAdmin: Hasil perbandingan (role == "admin") adalah: $result',
        );
        print('--- Pengecekan Admin Selesai ---');
        return result;
      } else {
        print(
          '[DEBUG] isAdmin: Gagal, dokumen dengan UID tersebut TIDAK DITEMUKAN di koleksi "users".',
        );
        print('--- Pengecekan Admin Selesai ---');
        return false;
      }
    } catch (e) {
      print('[DEBUG] isAdmin: Terjadi ERROR saat pengecekan: $e');
      print('--- Pengecekan Admin Selesai ---');
      throw AuthException('Gagal memeriksa status admin: $e', 'FETCH_ERROR');
    }
  }

  // Method untuk mendapatkan current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Method untuk check apakah user sudah login
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Method untuk update profile user
  Future<void> updateUserProfile({
    String? name,
    String? profileImageUrl,
    String? profileImagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User tidak login', 'USER_NOT_LOGGED_IN');
      }

      final updates = <String, dynamic>{};

      if (name != null) {
        updates['name'] = name;
        // Update juga display name di Firebase Auth
        await user.updateDisplayName(name);
      }

      if (profileImageUrl != null) {
        updates['profileImageUrl'] = profileImageUrl;
      }

      if (profileImagePath != null) {
        updates['profileImagePath'] = profileImagePath;
      }

      if (updates.isNotEmpty) {
        await _db.collection('users').doc(user.uid).update(updates);
      }
    } catch (e) {
      throw AuthException(
        'Gagal mengupdate profil: $e',
        'UPDATE_PROFILE_ERROR',
      );
    }
  }

  // Method untuk delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User tidak login', 'USER_NOT_LOGGED_IN');
      }

      // Hapus data user dari Firestore terlebih dahulu
      await _db.collection('users').doc(user.uid).delete();

      // Sign out dari Google jika perlu
      await _googleSignIn.signOut();

      // Hapus account dari Firebase Auth (ini akan otomatis sign out)
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Untuk keamanan, silakan login ulang sebelum menghapus akun',
          'REQUIRES_RECENT_LOGIN',
        );
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw AuthException('Gagal menghapus akun: $e', 'DELETE_ACCOUNT_ERROR');
    }
  }

  // Menangani error FirebaseAuthException
  AuthException _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('Email tidak terdaftar', 'USER_NOT_FOUND');
      case 'wrong-password':
        return AuthException('Password salah', 'WRONG_PASSWORD');
      case 'email-already-in-use':
        return AuthException('Email sudah digunakan', 'EMAIL_ALREADY_IN_USE');
      case 'weak-password':
        return AuthException('Password terlalu lemah', 'WEAK_PASSWORD');
      case 'invalid-email':
        return AuthException('Format email tidak valid', 'INVALID_EMAIL');
      case 'user-disabled':
        return AuthException('Akun telah dinonaktifkan', 'USER_DISABLED');
      case 'too-many-requests':
        return AuthException(
          'Terlalu banyak percobaan. Coba lagi nanti',
          'TOO_MANY_REQUESTS',
        );
      case 'operation-not-allowed':
        return AuthException(
          'Operasi tidak diizinkan',
          'OPERATION_NOT_ALLOWED',
        );
      case 'account-exists-with-different-credential':
        return AuthException(
          'Akun sudah ada dengan kredensial yang berbeda',
          'ACCOUNT_EXISTS',
        );
      case 'invalid-credential':
        return AuthException('Kredensial tidak valid', 'INVALID_CREDENTIAL');
      case 'credential-already-in-use':
        return AuthException('Kredensial sudah digunakan', 'CREDENTIAL_IN_USE');
      case 'requires-recent-login':
        return AuthException(
          'Operasi ini memerlukan login ulang',
          'REQUIRES_RECENT_LOGIN',
        );
      default:
        return AuthException(
          'Terjadi kesalahan: ${e.message}',
          'UNKNOWN_AUTH_ERROR',
        );
    }
  }

  // Menangani error Google Sign-In
  AuthException _handleGoogleSignInException(PlatformException e) {
    switch (e.code) {
      case 'sign_in_failed':
        return AuthException(
          'Login Google gagal. Periksa koneksi internet dan coba lagi',
          'SIGN_IN_FAILED',
        );
      case 'network_error':
        return AuthException('Tidak ada koneksi internet', 'NETWORK_ERROR');
      case 'sign_in_canceled':
        return AuthException(
          'Login dibatalkan oleh pengguna',
          'SIGN_IN_CANCELED',
        );
      case 'sign_in_required':
        return AuthException('Perlu login ulang', 'SIGN_IN_REQUIRED');
      default:
        return AuthException(
          'Terjadi kesalahan Google Sign-In: ${e.message}',
          'GOOGLE_SIGN_IN_ERROR',
        );
    }
  }
}
