import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService apiService;
  bool isInitializing = true;
  String? _token;
  User? user;

  AuthProvider({required this.apiService});

  Future<void> init() async {
    _token = await _authService.getToken();
    if (_token != null) {
      // optionally fetch user profile using api
      try {
        final profile = await apiService.fetchProfile(_token!);
        user = User.fromJson(profile);
      } catch (_) {
        user = null;
      }
    }
    isInitializing = false;
    notifyListeners();
  }

  bool get isAuthenticated => _token != null;

  Future<bool> login(String email, String password) async {
    final success = await apiService.login(email, password);
    if (success) {
      _token = await _authService.getToken();
      try {
        final profile = await apiService.fetchProfile(_token!);
        user = User.fromJson(profile);
      } catch (_) {
        user = User(id: 0, email: email, fullName: 'Demo User', role: 'customer');
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    user = null;
    notifyListeners();
  }

  String? get token => _token;
}
