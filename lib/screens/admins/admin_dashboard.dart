//screens/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:roti_nyaman/services/admin_firestore_service.dart';
import 'package:roti_nyaman/widgets/admins/admin_content.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminFirestoreService _adminService = AdminFirestoreService();
  int _selectedIndex = 0;
  
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      title: 'Dashboard Admin',
    ),
    NavigationItem(
      icon: Icons.shopping_bag,
      label: 'Produk',
      title: 'Manajemen Produk',
    ),
    NavigationItem(
      icon: Icons.category,
      label: 'Kategori',
      title: 'Manajemen Kategori',
    ),
    NavigationItem(
      icon: Icons.receipt_long,
      label: 'Pesanan',
      title: 'Manajemen Pesanan',
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'User',
      title: 'Manajemen User',
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Analytics',
      title: 'Laporan & Analytics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navigationItems[_selectedIndex].title),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.orange.shade700,
                  child: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, 
                           color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = _selectedIndex == index;
                      
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange.shade100 : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected ? Colors.orange.shade700 : Colors.grey.shade600,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: AdminContent(
                selectedIndex: _selectedIndex,
                adminService: _adminService,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari admin panel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String title;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.title,
  });
}