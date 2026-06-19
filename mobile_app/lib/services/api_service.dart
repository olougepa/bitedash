import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://127.0.0.1:8000/v1';
  final String baseUrl;
  final AuthService _auth = AuthService();

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

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
    final uri = Uri.parse('$baseUrl/auth/profile');
    String? access = token.isNotEmpty ? token : null;
    if (access == null) {
      access = await _auth.getAccessToken();
    }
    if (access == null) throw Exception('no token');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $access'});
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    if (res.statusCode == 401) {
      final ok = await _auth.refreshAccessToken();
      if (ok) {
        final newAccess = await _auth.getAccessToken();
        final res2 = await http.get(uri, headers: {'Authorization': 'Bearer $newAccess'});
        if (res2.statusCode == 200) return jsonDecode(res2.body) as Map<String, dynamic>;
      }
    }
    throw Exception('Profile fetch failed');
  }

  Future<List<dynamic>> fetchDeliveryOrders() async {
    final token = await _auth.getAccessToken();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(
      Uri.parse('$baseUrl/order?status=accepted'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load delivery orders');
  }

  Future<dynamic> updateDeliveryStatus(int orderId, String status) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.patch(
      Uri.parse('$baseUrl/order/$orderId'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update order status');
  }

  Future<void> updateDeliveryLocation(Map<String, dynamic> location) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.patch(
      Uri.parse('$baseUrl/delivery-agent/location'),
      headers: headers,
      body: jsonEncode(location),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update location');
    }
  }

  Future<void> updateCustomerLocation(int orderId, Map<String, dynamic> location) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.patch(
      Uri.parse('$baseUrl/order/$orderId/customer-location'),
      headers: headers,
      body: jsonEncode(location),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update customer location');
    }
  }

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      body: {'email': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await _auth.saveTokens(
          data['access_token'],
          data['refresh_token'],
        );
        return true;
      }
    }
    return false;
  }

  Future<bool> register(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      body: {'email': email, 'password': password, 'name': name},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await _auth.saveTokens(
          data['access_token'],
          data['refresh_token'],
        );
        return true;
      }
    }
    return false;
  }
}