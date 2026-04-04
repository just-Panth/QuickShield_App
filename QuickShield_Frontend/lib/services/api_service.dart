import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  // TODO: Replace with your actual deployed Render backend URL
  // Example: 'https://quickshield-backend-xxxx.onrender.com/api'
  static const String baseUrl = 'https://quickshield-backend.onrender.com/api';

  Future<Map<String, dynamic>> get(String endpoint, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed GET $endpoint: ${response.body}');
      }
    } catch (e) {
      print('API GET Error data: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed POST $endpoint: ${response.body}');
      }
    } catch (e) {
      print('API POST Error data: $e');
      throw e;
    }
  }
}
