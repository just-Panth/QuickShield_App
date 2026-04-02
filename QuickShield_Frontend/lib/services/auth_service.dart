import 'dart:math';

/// Mock authentication service.
/// Replace method bodies with real API calls in production.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // In-memory store of registered users (email → passwordHash)
  final Map<String, String> _users = {};

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

  /// Registers a new user. Returns a generated user ID.
  Future<String> register({
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final uid = 'QS-${Random().nextInt(900000) + 100000}';
    // Simple hash simulation (NOT cryptographic — demo only)
    final hash = password.hashCode.toRadixString(16);
    _users[email] = hash;
    return uid;
  }

  // ── Login ────────────────────────────────────────────────────────

  /// Validates credentials. Returns `true` if email exists and password matches.
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final hash = password.hashCode.toRadixString(16);
    return _users[email] == hash;
  }

  // ── Store lookup ─────────────────────────────────────────────────

  /// Returns the nearest store based on lat/lng. Mock data.
  Future<Map<String, String>> getNearestStore(
      double lat, double lng) async {
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
    'Karnataka': [
      'Bengaluru',
      'Mysuru',
      'Hubli',
      'Mangaluru',
      'Belgaum'
    ],
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
    'Gujarat': [
      'Ahmedabad',
      'Surat',
      'Vadodara',
      'Rajkot',
      'Gandhinagar'
    ],
    'Rajasthan': [
      'Jaipur',
      'Jodhpur',
      'Udaipur',
      'Kota',
      'Ajmer'
    ],
    'West Bengal': ['Kolkata', 'Howrah', 'Siliguri', 'Durgapur'],
    'Telangana': [
      'Hyderabad',
      'Warangal',
      'Nizamabad',
      'Karimnagar'
    ],
    'Kerala': [
      'Thiruvananthapuram',
      'Kochi',
      'Kozhikode',
      'Thrissur'
    ],
  };

  static List<String> get states => stateCityMap.keys.toList()..sort();

  static List<String> getCities(String state) =>
      stateCityMap[state] ?? [];
}
