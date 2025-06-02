import 'package:flutter/material.dart';

class GuestProfilePage extends StatelessWidget {
  final VoidCallback onLoginPressed;

  const GuestProfilePage({super.key, required this.onLoginPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              const Text(
                'Masuk untuk Mengakses Profil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Anda perlu masuk atau daftar untuk melihat profil dan riwayat pesanan.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onLoginPressed,
                  child: const Text('Masuk/Daftar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
