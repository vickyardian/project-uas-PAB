import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:roti_nyaman/services/auth_service.dart';
import 'package:roti_nyaman/auth/register_screen.dart';
import 'package:roti_nyaman/auth/login_screen.dart';
import 'package:roti_nyaman/screens/pages/welcome_screen.dart';
import 'package:roti_nyaman/screens/pages/home_screen.dart';
import 'package:roti_nyaman/screens/admins/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roti Nyaman',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 140, 255),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 0, 140, 255),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 140, 255),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      // Tambahkan routes untuk navigasi
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home_screen': (context) => const HomeScreen(isGuest: false),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/welcome': (context) => const SplashScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InitialLoadingScreen();
        }

        // User sudah login
        if (snapshot.hasData && snapshot.data != null) {
          // Check apakah user admin atau customer
          return FutureBuilder<bool>(
            future: authService.isAdmin(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const InitialLoadingScreen();
              }

              if (adminSnapshot.data == true) {
                return const AdminDashboardScreen();
              } else {
                return const HomeScreen(isGuest: false);
              }
            },
          );
        }

        // User belum login, tampilkan welcome screen
        return const SplashScreen();
      },
    );
  }
}

// Screen untuk loading awal (inisialisasi Firebase, dll)
class InitialLoadingScreen extends StatefulWidget {
  const InitialLoadingScreen({super.key});

  @override
  State<InitialLoadingScreen> createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends State<InitialLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Inisialisasi data atau operasi startup lainnya jika diperlukan
      // Sementara kosong karena addSampleProduct belum tersedia
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulasi loading

      // Gunakan debugPrint untuk menghindari warning
      debugPrint('App initialized successfully');
    } catch (e) {
      // Gunakan debugPrint untuk error logging
      debugPrint('Error initializing data: $e');

      // Untuk production, bisa tambahkan error reporting
      // Misalnya: FirebaseCrashlytics.instance.recordError(e, stackTrace);

      // Handle error sesuai kebutuhan
      if (mounted) {
        // Tampilkan error message atau redirect ke error screen jika perlu
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Terjadi kesalahan saat memuat aplikasi')),
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF3E0), // Light blue
              Color(0xFFFFE0B2), // Medium blue
              Color(0xFFFFCC80), // Darker blue
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau gambar splash
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade300.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bakery_dining,
                  size: 60,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Roti Nyaman',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Menyiapkan aplikasi...',
                style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
