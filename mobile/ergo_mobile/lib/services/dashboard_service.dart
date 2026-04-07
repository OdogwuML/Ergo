import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class DashboardService {
  static const String _tokenKey = 'auth_token';

  Future<Map<String, dynamic>?> getLandlordDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/dashboard/landlord'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('API Error: ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        // Token expired — wipe it immediately
        await prefs.remove(_tokenKey);
        throw Exception('Session expired. Please log in again.');
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Dashboard fetch error: $e');
      throw Exception('Network or parsing error: $e');
    }
  }
}
