import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:globetrotter_flutter/models/user.dart';
import 'package:globetrotter_flutter/services/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<AppUser> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final errorMessage = body?['error'] as String? ?? 'Login failed';
      throw Exception(errorMessage);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String;
    final username = body['username'] as String;
    final userEmail = body['email'] as String;
    final user = AppUser(username: username, email: userEmail, token: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', userEmail);
    await prefs.setString('token', token);
    return user;
  }

  static Future<void> register(
    String username,
    String email,
    String password,
    List<String> preferences,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'preferences': preferences,
      }),
    );

    if (response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final errorMessage = body?['error'] as String? ?? 'Registration failed';
      throw Exception(errorMessage);
    }
  }

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final errorMessage = body?['error'] as String? ?? 'Could not request reset';
      throw Exception(errorMessage);
    }
  }

  static Future<void> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      final errorMessage = body?['error'] as String? ?? 'Password reset failed';
      throw Exception(errorMessage);
    }
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('token');
  }
}
