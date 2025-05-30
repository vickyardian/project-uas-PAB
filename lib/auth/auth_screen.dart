import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _message = "";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLoginMode = true; // New: Toggle between login and register
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation =
        FadeTransition(
          opacity: _animationController,
          child: Container(),
        ).opacity!;
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _clearMessage() {
    if (_message.isNotEmpty) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _message = "";
          });
        }
      });
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      setState(() {
        _message = "Register berhasil! Silakan cek email untuk verifikasi.";
        _isLoading = false;
      });

      _clearMessage();
      _emailController.clear();
      _passwordController.clear();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'weak-password':
            _message = "Password terlalu lemah. Gunakan minimal 6 karakter.";
            break;
          case 'email-already-in-use':
            _message = "Email sudah terdaftar. Silakan gunakan email lain.";
            break;
          case 'invalid-email':
            _message = "Format email tidak valid.";
            break;
          case 'operation-not-allowed':
            _message = "Registrasi email/password tidak diaktifkan.";
            break;
          default:
            _message = "Register gagal: ${e.message}";
        }
      });
      _clearMessage();
    } catch (e) {
      setState(() {
        _message = "Register gagal: Terjadi kesalahan tak terduga.";
        _isLoading = false;
      });
      _clearMessage();
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = "";
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Check if email is verified
      if (!userCredential.user!.emailVerified) {
        setState(() {
          _message = "Email belum diverifikasi. Silakan cek email Anda.";
          _isLoading = false;
        });
        _clearMessage();
        return;
      }

      setState(() {
        _message = "Login berhasil! Selamat datang kembali.";
        _isLoading = false;
      });
      _clearMessage();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'user-not-found':
            _message = "Email tidak terdaftar. Silakan daftar terlebih dahulu.";
            break;
          case 'wrong-password':
            _message = "Password salah. Silakan coba lagi.";
            break;
          case 'invalid-email':
            _message = "Format email tidak valid.";
            break;
          case 'user-disabled':
            _message = "Akun telah dinonaktifkan. Hubungi admin.";
            break;
          case 'too-many-requests':
            _message = "Terlalu banyak percobaan. Coba lagi nanti.";
            break;
          case 'invalid-credential':
            _message = "Email atau password salah.";
            break;
          default:
            _message = "Login gagal: ${e.message}";
        }
      });
      _clearMessage();
    } catch (e) {
      setState(() {
        _message = "Login gagal: Terjadi kesalahan tak terduga.";
        _isLoading = false;
      });
      _clearMessage();
    }
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _message = "Logout berhasil!";
        _emailController.clear();
        _passwordController.clear();
      });
      _clearMessage();
    } catch (e) {
      setState(() {
        _message = "Logout gagal: Terjadi kesalahan.";
      });
      _clearMessage();
    }
  }

  void _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = "Masukkan email terlebih dahulu untuk reset password.";
      });
      _clearMessage();
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      setState(() {
        _message = "Email reset password telah dikirim. Cek inbox Anda.";
      });
      _clearMessage();
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _message = "Email tidak terdaftar.";
        } else {
          _message = "Gagal mengirim email reset: ${e.message}";
        }
      });
      _clearMessage();
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _message = "";
    });
  }

  String _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    // More comprehensive email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return '';
  }

  String _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    // Additional password strength check for registration
    if (!_isLoginMode) {
      if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
        return 'Password harus mengandung huruf dan angka';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Firebase Auth",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (currentUser != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: 'Logout',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: const CircleBorder(),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Colors.white],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 40 : 24,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : double.infinity,
                ),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Welcome Section
                          Container(
                            margin: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    currentUser != null
                                        ? Icons.verified_user_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 50,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  currentUser != null
                                      ? 'Welcome Back!'
                                      : 'Welcome',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentUser != null
                                      ? 'Manage your account'
                                      : _isLoginMode
                                      ? 'Sign in to your account'
                                      : 'Create your new account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // User Info Card (if logged in)
                          if (currentUser != null) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      currentUser.emailVerified
                                          ? Icons.verified_user_rounded
                                          : Icons.warning_rounded,
                                      color:
                                          currentUser.emailVerified
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Logged in as:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentUser.email ?? 'No email',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (!currentUser.emailVerified) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Email not verified',
                                        style: TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          // Auth Form Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Mode Toggle (if not logged in)
                                  if (currentUser == null) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (!_isLoginMode)
                                                _toggleAuthMode();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    _isLoginMode
                                                        ? const Color(
                                                          0xFF6366F1,
                                                        )
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Sign In',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      _isLoginMode
                                                          ? Colors.white
                                                          : Colors.grey[600],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (_isLoginMode)
                                                _toggleAuthMode();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    !_isLoginMode
                                                        ? const Color(
                                                          0xFF6366F1,
                                                        )
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Sign Up',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      !_isLoginMode
                                                          ? Colors.white
                                                          : Colors.grey[600],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                  ],

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: "Email Address",
                                      hintText: "Enter your email",
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.email_outlined,
                                          color: Color(0xFF6366F1),
                                          size: 20,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF6366F1),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final error = _validateEmail(value);
                                      return error.isEmpty ? null : error;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      hintText: "Enter your password",
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: Color(0xFF6366F1),
                                          size: 20,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF6366F1),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                    ),
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      final error = _validatePassword(value);
                                      return error.isEmpty ? null : error;
                                    },
                                  ),

                                  // Forgot Password Link (only in login mode)
                                  if (_isLoginMode && currentUser == null) ...[
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _resetPassword,
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Color(0xFF6366F1),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 32),

                                  // Action Buttons
                                  if (_isLoading)
                                    Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF8B5CF6),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  else if (currentUser == null) ...[
                                    // Main Action Button
                                    ElevatedButton(
                                      onPressed:
                                          _isLoginMode ? _login : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF6366F1,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF6366F1),
                                              Color(0xFF8B5CF6),
                                            ],
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Text(
                                          _isLoginMode
                                              ? "Sign In"
                                              : "Create Account",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Message Display
                          if (_message.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    _message.toLowerCase().contains("berhasil")
                                        ? const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.1)
                                        : const Color(
                                          0xFFEF4444,
                                        ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      _message.toLowerCase().contains(
                                            "berhasil",
                                          )
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          _message.toLowerCase().contains(
                                                "berhasil",
                                              )
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _message.toLowerCase().contains(
                                            "berhasil",
                                          )
                                          ? Icons.check_rounded
                                          : Icons.error_outline_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _message,
                                      style: TextStyle(
                                        color:
                                            _message.toLowerCase().contains(
                                                  "berhasil",
                                                )
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
