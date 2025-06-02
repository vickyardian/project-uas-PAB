import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Stream untuk auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login dengan email dan password
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register dengan email dan password
  Future<User?> registerUser(String name, String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in dengan Google
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out terlebih dahulu untuk memastikan account picker muncul
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User membatalkan proses sign in
        throw 'Login dibatalkan oleh pengguna';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Pastikan token tidak null
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Gagal mendapatkan kredensial Google';
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on PlatformException catch (e) {
      throw _handleGoogleSignInException(e);
    } catch (e) {
      throw 'Terjadi kesalahan saat login dengan Google: ${e.toString()}';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Sign out dari Google jika user login dengan Google
      await _googleSignIn.signOut();
      // Sign out dari Firebase
      await _auth.signOut();
    } catch (e) {
      throw 'Terjadi kesalahan saat logout: ${e.toString()}';
    }
  }

  // Handle Google Sign-In platform exceptions
  String _handleGoogleSignInException(PlatformException e) {
    switch (e.code) {
      case 'sign_in_failed':
        return 'Login Google gagal. Periksa koneksi internet dan coba lagi';
      case 'network_error':
        return 'Tidak ada koneksi internet';
      case 'sign_in_canceled':
        return 'Login dibatalkan oleh pengguna';
      case 'sign_in_required':
        return 'Perlu login ulang';
      default:
        return 'Terjadi kesalahan Google Sign-In: ${e.message}';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      case 'account-exists-with-different-credential':
        return 'Akun sudah ada dengan kredensial yang berbeda';
      case 'invalid-credential':
        return 'Kredensial tidak valid';
      case 'credential-already-in-use':
        return 'Kredensial sudah digunakan';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }

  Future getUserData() async {}
}
