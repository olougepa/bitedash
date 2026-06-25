import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  bool _loadingList = false;
  List<Map<String, dynamic>> _myPromotions = [];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    _loadMyPromotions();
  }

  Future<void> _loadMyPromotions() async {
    setState(() => _loadingList = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token != null) {
      final response = await http.get(
        Uri.parse('${api.baseUrl}/ad'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _myPromotions = data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    }
    setState(() => _loadingList = false);
  }

  Future<void> _submitRequest() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final response = await http.post(
      Uri.parse('${api.baseUrl}/ad'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${auth.token}'},
      body: jsonEncode({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'budget': double.tryParse(_budgetController.text) ?? 0,
        'target_type': auth.user?.role == 'restaurant_owner' ? 'restaurant' : 'rider',
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      }),
    );
    setState(() => _loading = false);
    if (mounted && response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion request submitted')));
      _titleController.clear();
      _descriptionController.clear();
      _budgetController.clear();
      _loadMyPromotions();
    }
  }

  void _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _viewPromotionDetail(Map<String, dynamic> promo) {
    final targetType = promo['target_type'] as String?;
    if (targetType == 'restaurant') {
      final restaurantId = promo['owner_id'] as int?;
      if (restaurantId != null) {
        Navigator.pushNamed(context, '/store', arguments: {'id': restaurantId});
      }
    } else if (targetType == 'rider') {
      final agentId = promo['agent_id'] as int?;
      if (agentId != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery Agent ID: $agentId')));
      }
    }
  }

  int _calculateDurationDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: Text(isAdmin ? 'Manage Promotions' : 'Request Promotion'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!isAdmin) ...[
              const Icon(Icons.campaign, size: 64, color: Colors.deepOrange),
              const SizedBox(height: 20),
              const Text('Request Ad Campaign', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Submit your promotion request for admin approval', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Campaign Title', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _budgetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budget (USD)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectStartDate,
                      child: Text('Start: ${_startDate?.toLocal().toString().split(' ')[0] ?? 'Select'}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectEndDate,
                      child: Text('End: ${_endDate?.toLocal().toString().split(' ')[0] ?? 'Select'}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Duration: ${_calculateDurationDays()} days', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, minimumSize: const Size.fromHeight(48)),
                onPressed: _loading ? null : _submitRequest,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request'),
              ),
            ],
            const Divider(),
            const SizedBox(height: 16),
            Text(isAdmin ? 'All Promotion Requests' : 'My Promotion Requests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: _buildPromotionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsList() {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.user?.role == 'admin';

    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myPromotions.isEmpty) {
      return const Center(child: Text('No promotion requests yet'));
    }
    return ListView.builder(
      itemCount: _myPromotions.length,
      itemBuilder: (context, index) {
        final promo = _myPromotions[index];
        final status = promo['status'] as String? ?? 'pending';
        final color = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
        final requesterName = promo['requester_name'] as String? ?? '';
        final durationDays = promo['duration_days'] as int? ?? 7;
        final budget = promo['budget'] as num?;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(promo['title'] ?? 'Untitled'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${promo['description'] ?? ''}'),
                if (isAdmin && requesterName.isNotEmpty) Text('Requester: $requesterName', style: const TextStyle(color: Colors.blue)),
                if (budget != null) Text('Budget: \$${budget.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                Text('Duration: $durationDays days', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            trailing: Chip(
              label: Text(status.toUpperCase()),
              backgroundColor: color.withOpacity(0.2),
            ),
            onTap: () => _viewPromotionDetail(promo),
          ),
        );
      },
    );
  }
}