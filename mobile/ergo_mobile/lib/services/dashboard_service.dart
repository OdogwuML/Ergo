import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class DashboardService {
  static const String _tokenKey = 'auth_token';

  Future<Map<String, dynamic>?> getLandlordDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null) return null;

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
        }
      }
      return null;
    } catch (e) {
      print('Dashboard fetch error: $e');
      return null;
    }
  }
}
