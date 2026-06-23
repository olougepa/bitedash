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
  bool _loading = false;

  Future<void> _submitRequest() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await http.post(
      Uri.parse('${api.baseUrl}/ad'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${auth.token}'},
      body: jsonEncode({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'budget': double.tryParse(_budgetController.text) ?? 0,
        'target_type': auth.user?.role == 'restaurant_owner' ? 'restaurant' : 'rider',
      }),
    );
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion request submitted')));
      Navigator.pop(context);
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Request Promotion'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, minimumSize: const Size.fromHeight(48)),
              onPressed: _loading ? null : _submitRequest,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}