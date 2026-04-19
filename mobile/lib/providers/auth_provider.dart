import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/profile_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _loadAuthData();
  }

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _user = json.decode(userData);
    }
    await _hydrateCurrentUser();
    notifyListeners();
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', json.encode(user));
  }

  Future<void> _hydrateCurrentUser() async {
    final token = _token;
    if (token == null || token.isEmpty) return;

    try {
      final meResponse = await AuthService.getCurrentUser(token: token);
      if (meResponse['success'] == true && meResponse['data'] is Map) {
        final current = Map<String, dynamic>.from(_user ?? {});
        current.addAll(Map<String, dynamic>.from(meResponse['data']));
        _user = current;
      }

      final profileResponse = await ProfileService.getProfile(token: token);
      if (profileResponse['success'] == true && profileResponse['data'] is Map) {
        final current = Map<String, dynamic>.from(_user ?? {});
        final profileData = Map<String, dynamic>.from(profileResponse['data']);
        if (profileData['user'] is Map) {
          current.addAll(Map<String, dynamic>.from(profileData['user']));
        } else {
          current.addAll(profileData);
        }
        _user = current;
      }

      if (_user != null) {
        await _saveAuthData(token, _user!);
      }
    } catch (_) {}
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  void updateUser(Map<String, dynamic> userData) {
    _user = userData;
    _saveAuthData(_token ?? '', userData);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Called after a successful Google sign-in to store the token and user
  /// from the [GoogleAuthService] response without making a second API call.
  Future<void> setFromGoogle({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _token = token;
    _user = user;
    _error = null;
    await _hydrateCurrentUser();
    await _saveAuthData(token, user);
    notifyListeners();
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
    String? cvUrl,
    String? linkedinUrl,
    String? additionalInfo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await AuthService.signup(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      role: role,
      cvUrl: cvUrl,
      linkedinUrl: linkedinUrl,
      additionalInfo: additionalInfo,
    );

    if (response['success'] != true) {
      _isLoading = false;
      _error = response['message'];
      notifyListeners();
      return false;
    }

    // Signup succeeded — now login so the user gets a JWT token
    final loginResponse = await AuthService.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (loginResponse['success'] == true) {
      _token = loginResponse['data']['token'];
      _user = loginResponse['data']['user'];
      await _hydrateCurrentUser();
      await _saveAuthData(_token!, _user!);
      notifyListeners();
      return true;
    } else {
      // Signup succeeded but auto-login failed; still report success
      // so the user can manually log in
      _user = response['data'];
      _error = null;
      notifyListeners();
      return true;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await AuthService.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (response['success'] == true) {
      _token = response['data']['token'];
      _user = response['data']['user'];
      await _hydrateCurrentUser();
      await _saveAuthData(_token!, _user!);
      notifyListeners();
      return true;
    } else {
      _error = response['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleLogin({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await AuthService.googleLogin(email: email);

    _isLoading = false;

    if (response['success'] == true) {
      _token = response['data']['token'];
      _user = response['data']['user'];
      await _hydrateCurrentUser();
      await _saveAuthData(_token!, _user!);
      notifyListeners();
      return true;
    } else {
      _error = response['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _error = null;
    await _clearAuthData();
    // Also sign out from Google in case the user logged in via Google
    await GoogleAuthService.signOut();
    notifyListeners();
  }
}
