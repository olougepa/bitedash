import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  final String baseUrl = 'https://api.bitedash.example.com';
  final AuthService _auth = AuthService();

  Future<List<dynamic>> fetchRestaurants() async {
    final response = await http.get(Uri.parse('$baseUrl/restaurant'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load restaurants');
  }

  Future<List<dynamic>> fetchMenuForRestaurant(int restaurantId) async {
    final response = await http.get(Uri.parse('$baseUrl/menu-item?restaurant_id=$restaurantId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load menu');
  }

  Future<dynamic> submitOrder(Map<String, dynamic> payload) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.post(
      Uri.parse('$baseUrl/order'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Order creation failed');
  }

  Future<dynamic> fetchOrder(int id) async {
    final token = await _auth.getAccessToken();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/order/$id'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load order');
  }

  Future<dynamic> updateOrder(int id, Map<String, dynamic> payload) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.put(
      Uri.parse('$baseUrl/order/$id'),
      headers: headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Order update failed');
  }

  Future<dynamic> markNotificationRead(int notificationId) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.patch(
      Uri.parse('$baseUrl/notification/$notificationId'),
      headers: headers,
      body: jsonEncode({'is_read': true}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to mark notification as read');
  }

  Future<List<dynamic>> fetchNotifications({String? category}) async {
    final token = await _auth.getAccessToken();
    final query = category != null ? '?category=$category' : '';
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/notification$query'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load notifications');
  }

  Future<List<dynamic>> fetchOwnerOrders() async {
    final token = await _auth.getAccessToken();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/order?status=pending'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load owner orders');
  }

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    // profile endpoint under auth
    final uri = Uri.parse('$baseUrl/auth/profile');
    try {
      String? access = token;
      if (access == null) access = await _auth.getAccessToken();
      if (access == null) throw Exception('no token');
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $access'});
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      if (res.statusCode == 401) {
        // try refresh
        final ok = await _auth.refreshAccessToken();
        if (ok) {
          final newAccess = await _auth.getAccessToken();
          final res2 = await http.get(uri, headers: {'Authorization': 'Bearer $newAccess'});
          if (res2.statusCode == 200) return jsonDecode(res2.body) as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    throw Exception('Profile fetch failed');
  }
}
