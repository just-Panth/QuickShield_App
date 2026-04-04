import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Real backend authentication service.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // TODO: Replace with your actual deployed Render backend URL
  // Example: 'https://quickshield-backend-xxxx.onrender.com/api'
  static const String _baseUrl = 'https://quickshield-backend.onrender.com/api';

  // The demo OTP code that is always accepted
  static const _validOtp = '1234';

  // ── OTP ──────────────────────────────────────────────────────────

  /// Simulates sending an OTP to [phoneNumber].
  Future<bool> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    // In production, call SMS gateway here.
    return true;
  }

  /// Verifies the [otp] for [phoneNumber].
  /// Returns `true` only when OTP matches `1234`.
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return otp == _validOtp;
  }

  // ── Registration ─────────────────────────────────────────────────

  /// Registers a new user. Returns the parsed response data.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'phone': phoneNumber,
          // Since the backend uses a passwordless platform ID system, we mock the platform info for the demo
          'worker_platform_id': 'QS-${Random().nextInt(900000) + 100000}',
          'platform': 'blinkit',
          'city': 'Bangalore',
          'zone_id': 'BLR-SOUTH',
          'full_name': email.split('@')[0],
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        try {
          final errBody = jsonDecode(response.body);
          throw Exception(errBody['error'] ?? 'Registration failed');
        } catch (_) {
          throw Exception('Registration failed: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('HTTP Register Error: $e');
      rethrow;
    }
  }

  // ── Login ────────────────────────────────────────────────────────

  /// Validates credentials via Node.js backend and returns response.
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      // Backend uses passwordless email login for the demo
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('HTTP Login Error: $e');
      return null;
    }
  }

  // ── Store lookup ─────────────────────────────────────────────────

  /// Returns the nearest store based on lat/lng. Mock data for demo.
  Future<Map<String, String>> getNearestStore(double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'id': 'STORE-${Random().nextInt(9000) + 1000}',
      'name': 'QuickShield Partner Store #${Random().nextInt(50) + 1}',
    };
  }

  // ── Mock store list per city ─────────────────────────────────────

  static List<Map<String, String>> getStoresForCity(String city) {
    return List.generate(
      5,
      (i) => {
        'id': 'STORE-$city-${i + 1}',
        'name': '$city Branch ${i + 1}',
      },
    );
  }

  // ── India state / city data ──────────────────────────────────────

  static const Map<String, List<String>> stateCityMap = {
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Nagpur',
      'Nashik',
      'Aurangabad',
      'Thane'
    ],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Hubli', 'Mangaluru', 'Belgaum'],
    'Delhi': ['New Delhi', 'Dwarka', 'Rohini', 'Saket'],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Salem',
      'Tiruchirappalli'
    ],
    'Uttar Pradesh': [
      'Lucknow',
      'Noida',
      'Kanpur',
      'Agra',
      'Varanasi',
      'Ghaziabad'
    ],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer'],
    'West Bengal': ['Kolkata', 'Howrah', 'Siliguri', 'Durgapur'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur'],
  };

  static List<String> get states => stateCityMap.keys.toList()..sort();

  static List<String> getCities(String state) => stateCityMap[state] ?? [];
}
