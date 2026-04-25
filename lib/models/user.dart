import 'organization.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final Organization? organization; // Organization object

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organization,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    Organization? org;
    if (json['organization'] != null) {
      if (json['organization'] is Map<String, dynamic>) {
        org = Organization.fromJson(json['organization']);
      } else {
        // If it's just a String (ID), create an Organization with that ID
        org = Organization(
          id: json['organization'].toString(),
          name: 'Organization', // Fallback name
          users: [],
        );
      }
    }

    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      organization: org,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'organization': organization?.id, // Store ID when converting back to JSON
    };
  }
}
