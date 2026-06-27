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
      try {
        final profile = await apiService.fetchProfile(_token!);
        user = User.fromJson(profile);
      } catch (_) {
        // Fallback for demo tokens
        final demoUser = await _authService.getDemoUser(_token == 'owner-demo-token' 
            ? 'owner@example.com' 
            : (_token == 'rider-demo-token' ? 'rider@example.com' : (_token == 'admin-demo-token' ? 'admin@example.com' : 'customer@example.com')));
        if (demoUser != null) {
          user = User.fromJson(demoUser);
        }
      }
    }
    isInitializing = false;
    notifyListeners();
  }

  bool get isAuthenticated => _token != null;

  bool get isApproved {
    if (user == null) return false;
    if (user!.role == 'customer') return true;
    return user!.status == 'active';
  }

  Future<bool> login(String email, String password) async {
    final success = await apiService.login(email, password);
    if (success) {
      _token = await _authService.getToken();
      try {
        final profile = await apiService.fetchProfile(_token!);
        user = User.fromJson(profile);
      } catch (_) {
        final demoUser = await _authService.getDemoUser(email);
        if (demoUser != null) {
          user = User.fromJson(demoUser);
        }
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginWithPhone(String phone, String password) async {
    final success = await apiService.loginWithPhone(phone, password);
    if (success) {
      _token = await _authService.getToken();
      try {
        final profile = await apiService.fetchProfile(_token!);
        user = User.fromJson(profile);
      } catch (_) {}
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password, String name, {String? role, String? documentType, String? documentNumber, int? cityId}) async {
    final success = await apiService.register(email, password, name, role: role, documentType: documentType, documentNumber: documentNumber, cityId: cityId);
    if (success) {
      _token = await _authService.getToken();
      try {
        final profile = await apiService.fetchProfile(_token!);
        user = User.fromJson(profile);
      } catch (_) {}
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> registerWithPhone(String phone, String password, String name, {String? role, String? documentType, String? documentNumber, int? cityId}) async {
    final success = await apiService.registerWithPhone(phone, password, name, role: role, documentType: documentType, documentNumber: documentNumber, cityId: cityId);
    if (success) {
      _token = await _authService.getToken();
      try {
        final profile = await apiService.fetchProfile(_token!);
        user = User.fromJson(profile);
      } catch (_) {}
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