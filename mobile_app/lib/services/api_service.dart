import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String _defaultBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000/v1');
  final String baseUrl;
  final AuthService _auth = AuthService();

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

Future<List<dynamic>> fetchRestaurants({int? cityId}) async {
    final query = cityId != null ? '?status=active&city_id=$cityId' : '?status=active';
    final response = await http.get(Uri.parse('$baseUrl/restaurant$query'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load restaurants');
  }

  Future<List<dynamic>> fetchNearbyRiders(double lat, double lng, {int? cityId}) async {
    final query = cityId != null ? '?lat=$lat&lng=$lng&city_id=$cityId' : '?lat=$lat&lng=$lng';
    final response = await http.get(Uri.parse('$baseUrl/delivery-agent/nearby$query'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<dynamic> fetchRestaurant(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/restaurants/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load restaurant');
  }

  Future<List<dynamic>> fetchMenuForRestaurant(int restaurantId) async {
    final response = await http.get(Uri.parse('$baseUrl/menu-item?restaurant_id=$restaurantId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load menu');
  }

  Future<dynamic> fetchMyRestaurant() async {
    final token = await _auth.getAccessToken();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/restaurant?status=draft'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (data.isNotEmpty) return data[0] as Map<String, dynamic>;
      return null;
    }
    return null;
  }

  Future<void> updateRestaurant(int id, Map<String, dynamic> data) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.patch(
      Uri.parse('$baseUrl/restaurant/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  Future<List<dynamic>> fetchAllMenuItems({int? cityId}) async {
    final query = cityId != null ? '?city_id=$cityId' : '';
    final response = await http.get(Uri.parse('$baseUrl/menu-item$query'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load menu items');
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
      Uri.parse('$baseUrl/notifications/$notificationId'),
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
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

  Future<bool> loginWithPhone(String phone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
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

  Future<bool> register(String email, String password, String name, {String? role, String? documentType, String? documentNumber, int? cityId}) async {
    final body = {'email': email, 'password': password, 'name': name};
    if (role != null) body['role'] = role;
    if (documentType != null) body['document_type'] = documentType;
    if (documentNumber != null) body['document_number'] = documentNumber;
    if (cityId != null) body['city_id'] = cityId.toString();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
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

  Future<bool> registerWithPhone(String phone, String password, String name, {String? role, String? documentType, String? documentNumber, int? cityId}) async {
    final body = {'phone': phone, 'password': password, 'name': name, 'email': '$phone@bitedash.temp'};
    if (role != null) body['role'] = role;
    if (documentType != null) body['document_type'] = documentType;
    if (documentNumber != null) body['document_number'] = documentNumber;
    if (cityId != null) body['city_id'] = cityId.toString();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
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

  Future<List<dynamic>> fetchCoupons(int? restaurantId, {int? agentId}) async {
    final queryParams = [];
    if (restaurantId != null) queryParams.add('restaurant_id=$restaurantId');
    if (agentId != null) queryParams.add('agent_id=$agentId');
    final query = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    final response = await http.get(
      Uri.parse('$baseUrl/coupon$query'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> fetchCouponsByAgent(int agentId) async {
    return fetchCoupons(null, agentId: agentId);
  }

  Future<dynamic> validateCoupon(String code) async {
    final response = await http.get(Uri.parse('$baseUrl/coupon/check?code=$code'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'valid': false};
  }

  Future<void> createRiderRequest(int orderId, Map<String, dynamic> data) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.post(
      Uri.parse('$baseUrl/rider-request'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  Future<void> applyForRider(int riderRequestId, double? priceOffer) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.post(
      Uri.parse('$baseUrl/rider-request/apply'),
      headers: headers,
      body: jsonEncode({'rider_request_id': riderRequestId, 'price_offer': priceOffer}),
    );
  }

  Future<void> acceptRiderApplication(int applicationId) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.post(
      Uri.parse('$baseUrl/rider-request/accept-application'),
      headers: headers,
      body: jsonEncode({'application_id': applicationId}),
    );
  }

  Future<List<dynamic>> listRiderApplications(int riderRequestId) async {
    final token = await _auth.getAccessToken();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(
      Uri.parse('$baseUrl/rider-request/$riderRequestId/applications'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<void> createReview(Map<String, dynamic> data) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.post(
      Uri.parse('$baseUrl/review'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  Future<void> updateKyc(String token, String role, String documentType, String documentNumber) async {
    final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
    await http.post(
      Uri.parse('$baseUrl/kyc'),
      headers: headers,
      body: jsonEncode({'entity_type': role == 'restaurant_owner' ? 'restaurant' : 'delivery_agent', 'document_type': documentType, 'document_number': documentNumber}),
    );
  }

  Future<List<dynamic>> fetchChats() async {
    final token = await _auth.getAccessToken();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/chat'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<void> sendMessage(int orderId, String message) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: headers,
      body: jsonEncode({'order_id': orderId, 'message': message}),
    );
  }

  Future<List<dynamic>> fetchAds() async {
    final response = await http.get(Uri.parse('$baseUrl/ad?status=approved'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<void> updateMenuItem(int id, Map<String, dynamic> data) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.patch(
      Uri.parse('$baseUrl/menu-items/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  Future<void> updateDeliveryAgentPrice(int id, double pricePerKm) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.patch(
      Uri.parse('$baseUrl/delivery-agent/price?id=$id'),
      headers: headers,
      body: jsonEncode({'price_per_km': pricePerKm}),
    );
  }

  Future<void> createMenuItem(Map<String, dynamic> data) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.post(
      Uri.parse('$baseUrl/menu-items'),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  Future<List<dynamic>?> fetchChatsForOrder(int orderId, String? token) async {
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/chat?order_id=$orderId'), headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchSystemSettings() async {
    final response = await http.get(Uri.parse('$baseUrl/settings'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data as List<dynamic>).fold<Map<String, dynamic>>({}, (map, item) {
        final Map<String, dynamic> settingsItem = item as Map<String, dynamic>;
        map[settingsItem['setting_key'] as String] = settingsItem['setting_value'];
        return map;
      });
    }
    return {};
  }

  Future<List<dynamic>> fetchCities() async {
    final response = await http.get(Uri.parse('$baseUrl/cities'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  Future<void> updateUserCity(int? cityId) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.put(
      Uri.parse('$baseUrl/user-city-preference'),
      headers: headers,
      body: jsonEncode({'city_id': cityId}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update city');
  }

  Future<dynamic> fetchMyDeliveryAgent() async {
    final token = await _auth.getAccessToken();
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final response = await http.get(Uri.parse('$baseUrl/delivery-agent'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (data.isNotEmpty) return data[0] as Map<String, dynamic>;
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> scanMenu(String base64Image) async {
    final token = await _auth.getAccessToken();
    final headers = {"Content-Type": "application/json"};
    if (token != null) headers["Authorization"] = "Bearer $token";
    final response = await http.post(
      Uri.parse("$baseUrl/menu-scan"),
      headers: headers,
      body: jsonEncode({"image": base64Image}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Menu scan failed");
  }

  Future<void> updateDeliveryAgent(int id, Map<String, dynamic> data) async {
    final token = await _auth.getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    await http.patch(
      Uri.parse('$baseUrl/delivery-agent/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
  }
}