import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

class AuthService {
  final String baseUrl = 'https://api.bitedash.example.com';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    try {
      final res = await http.post(uri, body: {'email': email, 'password': password});
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final access = j['access_token'] as String?;
        final refresh = j['refresh_token'] as String?;
        if (access != null) {
          await _storage.write(key: 'access_token', value: access);
          if (refresh != null) await _storage.write(key: 'refresh_token', value: refresh);
          return access;
        }
      }
    } catch (_) {}
    // fallback: local dev mock
    if (email == 'demo@demo.com' && password == 'password') {
      const token = 'demo-token';
      await _storage.write(key: 'access_token', value: token);
      return token;
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'access_token');
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: 'refresh_token');
  }

  Future<bool> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    final uri = Uri.parse('$baseUrl/auth/refresh');
    try {
      final res = await http.post(uri, body: {'refresh_token': refresh});
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        final access = j['access_token'] as String?;
        final newRefresh = j['refresh_token'] as String?;
        if (access != null) {
          await _storage.write(key: 'access_token', value: access);
          if (newRefresh != null) await _storage.write(key: 'refresh_token', value: newRefresh);
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) print('refresh failed: $e');
    }
    return false;
  }
}
