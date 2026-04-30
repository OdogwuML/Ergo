import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart';

class BuildingService {
  static const String _tokenKey = 'auth_token';

  Future<String?> uploadBuildingPhoto(String filepath) async {
    try {
      final file = File(filepath);
      final fileName = 'building_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      final String path = await Supabase.instance.client.storage.from('buildings').upload(
            fileName,
            file,
          );
          
      return Supabase.instance.client.storage.from('buildings').getPublicUrl(fileName);
    } catch (e) {
      print('Upload building photo error: $e');
      return null;
    }
  }

  Future<List<dynamic>> getBuildings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/buildings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Fetch buildings error: $e');
      return [];
    }
  }

  Future<bool> createBuilding({
    required String name,
    required String address,
    required int totalUnits,
    required int pricePerUnit,
    bool hasPool = false,
    bool hasGym = false,
    bool hasParking = false,
    bool hasCctv = false,
    String? photoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/buildings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'address': address,
          'total_units': totalUnits,
          'price_per_unit': pricePerUnit,
          'has_pool': hasPool,
          'has_gym': hasGym,
          'has_parking': hasParking,
          'has_cctv': hasCctv,
          if (photoUrl != null) 'photo_url': photoUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Create building error: $e');
      return false;
    }
  }

  Future<List<dynamic>> getUnits(String buildingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/buildings/$buildingId/units'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Fetch units error: $e');
      return [];
    }
  }

  Future<bool> createUnit({
    required String buildingId,
    required String unitNumber,
    required int rentAmountKobo,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/units'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'building_id': buildingId,
          'unit_number': unitNumber,
          'rent_amount': rentAmountKobo,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Create unit error: $e');
      return false;
    }
  }
}
