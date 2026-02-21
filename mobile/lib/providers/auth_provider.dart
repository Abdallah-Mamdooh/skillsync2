import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;

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

    _isLoading = false;

    if (response['success'] == true) {
      _user = response['data'];
      notifyListeners();
      return true;
    } else {
      _error = response['message'];
      notifyListeners();
      return false;
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
      notifyListeners();
      return true;
    } else {
      _error = response['message'];
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();
  }
}
