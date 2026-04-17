import 'package:http/http.dart' as http;
import 'dart:convert';

/// Dedicated service layer for all claims & payout API calls.
class ClaimService {
  ClaimService._();
  static final instance = ClaimService._();

  static const String _baseUrl = 'https://quickshield-backend.onrender.com/api';

  // ─────────────────────────────────────────────────────────────────────────
  // Submit a new claim through the 3-gate pipeline
  // Returns full gate results including fraud_score, payout, etc.
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitClaim({
    required String token,
    required String policyId,
    required String disruptionType,
    required double earnedTodayInr,
    List<Map<String, dynamic>>? gpsTrail,
    List<Map<String, dynamic>>? zAxisTrail,
    String? photoHash,
  }) async {
    // Build a minimal but realistic GPS trail if none provided
    final gps = gpsTrail ??
        _mockGpsTrail();
    
    // Build a unique photo hash if none provided
    final hash = photoHash ??
        'sha256_app_${DateTime.now().millisecondsSinceEpoch}';

    final body = {
      'policy_id':        policyId,
      'disruption_type':  disruptionType,
      'gps_trail':        gps,
      'z_axis_trail':     zAxisTrail ?? [],
      'photo_hash':       hash,
      'earned_today_inr': earnedTodayInr.toInt(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/claim/submit'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // Treat 201 (paid), 202 (review), and 422 (rejected) as valid responses
    if (response.statusCode == 201 ||
        response.statusCode == 202 ||
        response.statusCode == 422) {
      return decoded;
    }

    throw Exception('Claim submission failed: ${response.body}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch all claims for the authenticated worker
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchClaims(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/claim'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch claims: ${response.body}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch payout history for the authenticated worker
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchPayoutHistory(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payout/history'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch payout history: ${response.body}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch admin dashboard stats
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchAdminDashboard(String token) async {
    // HARDCODED DEMO DATA FOR ADMIN DASHBOARD
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network
    return {
      'overview': {
        'active_policies': 124,
        'payout_mtd': 84500,
        'active_workers': 342,
        'risk_score': 12.5,
      },
      'recent_claims': [
        {
          'id': 'CLM-2093',
          'status': 'under_review',
          'amount_inr': 2100,
          'type': 'Accident',
          'worker': {'full_name': 'Arjun Kumar', 'platform': 'blinkit'}
        },
        {
          'id': 'CLM-2092',
          'status': 'approved',
          'amount_inr': 1400,
          'type': 'Rain Delay',
          'worker': {'full_name': 'Ravi Singh', 'platform': 'swiggy'}
        },
        {
          'id': 'CLM-2091',
          'status': 'rejected',
          'amount_inr': 3500,
          'type': 'Device Damage',
          'worker': {'full_name': 'Deepak ', 'platform': 'zomato'}
        },
      ],
      'geo_risks': [
        {'zone_id': 'Koramangala', 'active_claims': 14, 'baseline_risk': 18},
        {'zone_id': 'Indiranagar', 'active_claims': 8, 'baseline_risk': 12},
        {'zone_id': 'Whitefield', 'active_claims': 22, 'baseline_risk': 35},
      ]
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch first active policy for the worker (used in claim submission)
  // ─────────────────────────────────────────────────────────────────────────
  Future<String?> fetchActivePolicyId(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/policy'),
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final policies = data['policies'] as List<dynamic>?;
      if (policies != null && policies.isNotEmpty) {
        return policies.first['id'] as String?;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch all claims (admin only)
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchAdminClaims(String token) async {
    // HARDCODED DEMO DATA FOR ADMIN CLAIMS VIEWER
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'claims': [
        {
          'id': 'CLM-2094',
          'status': 'pending',
          'type': 'Vehicle Breakdown',
          'amount_inr': 4500,
          'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          'fraud_score': 0.12,
          'worker': {'full_name': 'Suresh Menon', 'platform': 'blinkit'}
        },
        {
          'id': 'CLM-2093',
          'status': 'under_review',
          'type': 'Accident',
          'amount_inr': 2100,
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'fraud_score': 0.78,
          'worker': {'full_name': 'Arjun Kumar', 'platform': 'blinkit'}
        },
        {
          'id': 'CLM-2092',
          'status': 'approved',
          'type': 'Rain Delay',
          'amount_inr': 1400,
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'fraud_score': 0.05,
          'worker': {'full_name': 'Ravi Singh', 'platform': 'swiggy'}
        },
        {
          'id': 'CLM-2091',
          'status': 'rejected',
          'type': 'Device Damage',
          'amount_inr': 3500,
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'fraud_score': 0.95,
          'worker': {'full_name': 'Deepak Verma', 'platform': 'zomato'}
        },
        {
          'id': 'CLM-2090',
          'status': 'approved',
          'type': 'Traffic Delay',
          'amount_inr': 500,
          'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'fraud_score': 0.02,
          'worker': {'full_name': 'Mohammed Ali', 'platform': 'uber'}
        },
      ]
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch all workers (admin only)
  // ─────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchAdminWorkers(String token) async {
    // HARDCODED DEMO DATA FOR ADMIN WORKERS VIEWER
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'workers': [
        {
          'id': 'wkr_1',
          'full_name': 'Suresh Menon',
          'platform': 'blinkit',
          'is_active': true,
          'city': 'Bangalore',
          'onboarded_at': DateTime.now().subtract(const Duration(days: 120)).toIso8601String()
        },
        {
          'id': 'wkr_2',
          'full_name': 'Arjun Kumar',
          'platform': 'blinkit',
          'is_active': true,
          'city': 'Bangalore',
          'onboarded_at': DateTime.now().subtract(const Duration(days: 85)).toIso8601String()
        },
        {
          'id': 'wkr_3',
          'full_name': 'Ravi Singh',
          'platform': 'swiggy',
          'is_active': false,
          'city': 'Mumbai',
          'onboarded_at': DateTime.now().subtract(const Duration(days: 40)).toIso8601String()
        },
        {
          'id': 'wkr_4',
          'full_name': 'Deepak Verma',
          'platform': 'zomato',
          'is_active': true,
          'city': 'Delhi',
          'onboarded_at': DateTime.now().subtract(const Duration(days: 200)).toIso8601String()
        },
        {
          'id': 'wkr_5',
          'full_name': 'Anjali Gupta',
          'platform': 'zepto',
          'is_active': true,
          'city': 'Bangalore',
          'onboarded_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()
        },
      ]
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Builds a minimal plausible GPS trail (Bangalore Central)
  // Used when the app does not have location permission
  // ─────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _mockGpsTrail() {
    final base = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return [
      {'lat': 12.9716, 'lng': 77.5946, 'timestamp': base - 300},
      {'lat': 12.9719, 'lng': 77.5950, 'timestamp': base - 240},
      {'lat': 12.9722, 'lng': 77.5954, 'timestamp': base - 180},
      {'lat': 12.9724, 'lng': 77.5958, 'timestamp': base - 120},
      {'lat': 12.9725, 'lng': 77.5960, 'timestamp': base - 60},
    ];
  }
}
