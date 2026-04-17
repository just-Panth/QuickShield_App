import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

/// Centralized auth state manager.
///
/// Handles OTP flow, registration, login, and persistent auth state.
/// After registration completes → user is automatically authenticated.
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService.instance;
  final _locationService = LocationService.instance;

  // ── State ────────────────────────────────────────────────────────
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  String? _token;
  String? _fullName;
  String? _city;
  String? _phone;
  String? _upiId;
  String _role = 'worker'; // 'worker' | 'admin'

  UserData _userData = UserData();
  UserProfile _userProfile = UserProfile();

  // ── Getters ──────────────────────────────────────────────────────
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  String? get fullName => _fullName;
  String? get city => _city;
  String? get phone => _phone;
  String? get upiId => _upiId;
  String get role => _role;
  bool get isAdmin => _role == 'admin';
  UserData get userData => _userData;
  UserProfile get userProfile => _userProfile;

  // ── Helpers ──────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Step 1: Send OTP ─────────────────────────────────────────────
  Future<bool> sendOtp(String phone) async {
    _setError(null);
    _setLoading(true);
    try {
      final ok = await _authService.sendOtp(phone);
      if (ok) {
        _userData = _userData.copyWith(phoneNumber: phone);
      } else {
        _setError('Failed to send OTP. Try again.');
      }
      return ok;
    } catch (e) {
      _setError('Network error. Please check your connection.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Step 2: Verify OTP ───────────────────────────────────────────
  Future<bool> verifyOtp(String otp) async {
    _setError(null);
    _setLoading(true);
    try {
      final ok =
          await _authService.verifyOtp(_userData.phoneNumber ?? '', otp);
      if (!ok) {
        _setError('Invalid OTP. Please try again.');
      }
      return ok;
    } catch (e) {
      _setError('Verification failed. Try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Step 3: Account Setup ────────────────────────────────────────
  Future<bool> registerAccount(String email, String password) async {
    _setError(null);
    _setLoading(true);
    try {
      final data = await _authService.register(
        email: email,
        password: password,
        phoneNumber: _userData.phoneNumber ?? '',
      );
      final worker = data['worker'];
      _token = data['token'];
      _fullName = worker['full_name'];
      _city     = worker['city'];
      _phone    = worker['phone_number'];
      _upiId    = worker['upi_id'];
      _role     = worker['role'] ?? 'worker';
      
      _userData = _userData.copyWith(
        userId: worker['id'],
        email: worker['email'],
        passwordHash: password.hashCode.toRadixString(16),
      );
      
      _userProfile = _userProfile.copyWith(
        workerId: worker['worker_platform_id'],
        city: worker['city'],
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _setError(msg);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Step 4: Work Details ─────────────────────────────────────────
  void setWorkDetails({
    required String workerId,
    required String state,
    required String city,
    required String area,
    String? storeId,
    String? storeName,
  }) {
    _userProfile = _userProfile.copyWith(
      workerId: workerId,
      state: state,
      city: city,
      area: area,
      storeId: storeId,
      storeName: storeName,
    );
    notifyListeners();
  }

  // ── Step 5: Location ─────────────────────────────────────────────
  Future<bool> requestLocationAndCapture() async {
    _setError(null);
    _setLoading(true);
    try {
      final granted = await _locationService.requestPermission();
      if (!granted) {
        _setError('Location permission denied.');
        return false;
      }
      final pos = await _locationService.getCurrentPosition();
      _userProfile = _userProfile.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      // Auto-detect nearest store
      final store =
          await _authService.getNearestStore(pos.latitude, pos.longitude);
      _userProfile = _userProfile.copyWith(
        storeId: store['id'],
        storeName: store['name'],
      );

      return true;
    } catch (e) {
      _setError('Could not get location. You can continue without it.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Complete onboarding → auto-login ─────────────────────────────
  void completeOnboarding() {
    _isLoggedIn = true;
    _error = null;
    notifyListeners();
  }

  // ── Login with credentials ───────────────────────────────────────
  Future<bool> loginWithCredentials(String email, String password) async {
    _setError(null);
    _setLoading(true);
    try {
      final data = await _authService.login(email, password);
      if (data != null) {
        _isLoggedIn = true;
        _token    = data['token'];
        final worker = data['worker'];
        _fullName = worker['full_name'];
        _city     = worker['city'];
        _phone    = worker['phone_number'];
        _upiId    = worker['upi_id'];
        _role     = worker['role'] ?? 'worker';
        _userData = _userData.copyWith(
          userId: worker['id'],
          email: worker['email'],
        );
        _userProfile = _userProfile.copyWith(
          workerId: worker['worker_platform_id'],
          city: worker['city'],
        );
      } else {
        _setError('Invalid email or password.');
      }
      return data != null;
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Simple login (kept for backward compat) ──────────────────────
  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  // ── Update profile fields locally after a successful PUT /auth/profile ──
  void updateProfile({String? fullName, String? city, String? upiId}) {
    if (fullName != null) _fullName = fullName;
    if (city     != null) {
      _city = city;
      _userProfile = _userProfile.copyWith(city: city);
    }
    if (upiId != null) _upiId = upiId;
    notifyListeners();
  }

  // ── Logout ───────────────────────────────────────────────────────
  void logout() {
    _isLoggedIn  = false;
    _userData    = UserData();
    _userProfile = UserProfile();
    _error       = null;
    _token       = null;
    _fullName    = null;
    _city        = null;
    _phone       = null;
    _upiId       = null;
    _role        = 'worker';
    notifyListeners();
  }
}