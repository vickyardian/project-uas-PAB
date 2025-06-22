//models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' atau 'customer'
  final DateTime createdAt;
  final DateTime? updatedAt; // Added for consistency with service
  final bool isActive;
  final String? profileImageUrl; // Changed to match service usage (profileImageUrl)
  final String? profileImagePath; // Path file di storage untuk keperluan delete

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.profileImageUrl,
    this.profileImagePath,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      profileImageUrl: data['profileImageUrl'], // Changed to match service
      profileImagePath: data['profileImagePath'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl, // Changed to match service
      'profileImagePath': profileImagePath,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
    String? profileImagePath,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  // Helper method untuk cek apakah user punya foto profil
  bool get hasProfilePhoto => profileImageUrl != null && profileImageUrl!.isNotEmpty;

  // Helper method untuk mendapatkan foto profil atau default
  String getProfilePhotoUrl({String? defaultUrl}) {
    return profileImageUrl ?? defaultUrl ?? '';
  }
}