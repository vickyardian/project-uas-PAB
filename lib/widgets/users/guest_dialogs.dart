import 'package:flutter/material.dart';

class GuestDialogs {
  static void showCartDialog(
    BuildContext context,
    Map<String, int> cart,
    VoidCallback onLoginPressed,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('Keranjang Anda'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cart.isEmpty)
                  const Text('Keranjang masih kosong')
                else
                  ...cart.entries.map(
                    (entry) => ListTile(
                      title: Text(entry.key),
                      trailing: Text('${entry.value}x'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    '⚠️ Untuk melakukan checkout, silakan masuk atau daftar terlebih dahulu.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onLoginPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Masuk/Daftar'),
              ),
            ],
          ),
    );
  }

  static void showLimitationDialog(
    BuildContext context,
    VoidCallback onLoginPressed,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('Akses Terbatas'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fitur ini memerlukan akun untuk digunakan.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Silakan masuk atau daftar untuk mengakses keranjang, profil, dan melakukan pemesanan.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onLoginPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Masuk/Daftar'),
              ),
            ],
          ),
    );
  }
}
