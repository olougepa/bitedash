import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class CouponManagerScreen extends StatefulWidget {
  const CouponManagerScreen({super.key});

  @override
  State<CouponManagerScreen> createState() => _CouponManagerScreenState();
}

class _CouponManagerScreenState extends State<CouponManagerScreen> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _coupons = [];
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _discountAmountController = TextEditingController();
  final _minOrderController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final token = auth.token;
    
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('${api.baseUrl}/coupon'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          setState(() {
            _coupons = (jsonDecode(response.body) as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load coupons')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createCoupon() async {
    setState(() => _isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final nextMonth = DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);
    
    final body = {
      'code': _codeController.text,
      'description': _descriptionController.text,
      'discount_percent': double.tryParse(_discountPercentController.text) ?? null,
      'discount_amount': double.tryParse(_discountAmountController.text) ?? null,
      'min_order_amount': double.tryParse(_minOrderController.text) ?? 0,
      'valid_from': now,
      'valid_until': nextMonth,
    };

    try {
      final response = await http.post(
        Uri.parse('${api.baseUrl}/coupon'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${auth.token}'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon created')));
        _codeController.clear();
        _descriptionController.clear();
        _discountPercentController.clear();
        _discountAmountController.clear();
        _loadCoupons();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create coupon')));
    }
    setState(() => _isSubmitting = false);
  }

  Future<void> _toggleActive(Map<String, dynamic> coupon) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final id = int.tryParse('${coupon['id']}') ?? 0;
    if (id == 0) return;
    
    final body = {'is_active': !(coupon['is_active'] as bool? ?? true)};
    
    try {
      await http.patch(
        Uri.parse('${api.baseUrl}/coupon/$id'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${auth.token}'},
        body: jsonEncode(body),
      );
      _loadCoupons();
    } catch (e) {}
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountPercentController.dispose();
    _discountAmountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Coupons'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Create New Coupon', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _discountPercentController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount % (optional)', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _discountAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Discount Amount XAF (optional)', border: OutlineInputBorder())),
                          const SizedBox(height: 8),
                          TextField(controller: _minOrderController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Order Amount XAF', border: OutlineInputBorder())),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, minimumSize: const Size.fromHeight(40)),
                            onPressed: _isSubmitting ? null : _createCoupon,
                            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _coupons.isEmpty
                      ? const Center(child: Text('No coupons yet'))
                      : ListView.builder(
                          itemCount: _coupons.length,
                          itemBuilder: (context, i) {
                            final c = _coupons[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.local_offer, color: Colors.deepOrange),
                                title: Text(c['code'] ?? 'Coupon'),
                                subtitle: Text(c['description'] ?? ''),
                                trailing: Switch(
                                  value: c['is_active'] as bool? ?? false,
                                  onChanged: (v) => _toggleActive(c),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}