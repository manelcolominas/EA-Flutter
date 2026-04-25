import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Authentication error');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<Map<String, dynamic>> signup(
      String name, String email, String password, String organizationId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/signup'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'organization': organizationId,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Error registering user');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserById(String userId, String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Error getting user');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }
}
