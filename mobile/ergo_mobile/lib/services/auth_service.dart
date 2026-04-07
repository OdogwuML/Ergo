import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // The Go backend returns APIResponse with Data field containing AuthResponse
    final authData = data['data'];
    if (authData != null) {
      final token = authData['access_token'] as String;
      final user = authData['user'] as Map<String, dynamic>;
      
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userRoleKey, user['role'] as String);
      await prefs.setString(_userIdKey, user['id'] as String);
      if (user['full_name'] != null) {
        await prefs.setString('user_name', user['full_name'] as String);
      }
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        await _saveSession(data);
        return null; // Success
      }
      
      return data['error'] ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      print('Login error: $e');
      return 'Connection error. Please check your network and try again.';
    }
  }

  Future<String?> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'role': 'landlord', // Signup screen is only for landlords as requested
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        await _saveSession(data);
        return null; // Success
      }

      return data['error'] ?? 'Signup failed. Please try again.';
    } catch (e) {
      print('Signup error: $e');
      return 'Connection error. Please check your network and try again.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }
}
