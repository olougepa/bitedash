import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/l10n.dart';

class MenuScanScreen extends StatefulWidget {
  const MenuScanScreen({super.key});

  @override
  State<MenuScanScreen> createState() => _MenuScanScreenState();
}

class _MenuScanScreenState extends State<MenuScanScreen> {
  File? _image;
  bool _processing = false;
  List<Map<String, dynamic>> _extractedItems = [];
  final _picker = ImagePicker();
  int? _restaurantId;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final restaurant = await api.fetchMyRestaurant();
    if (mounted && restaurant != null) {
      _restaurantId = restaurant['id'] as int?;
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _scanMenu() async {
    if (_image == null) return;
    setState(() => _processing = true);
    
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final result = await api.scanMenu(base64Image);
      setState(() {
        _extractedItems = (result['items'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    }
    
    setState(() => _processing = false);
  }

  Future<void> _saveMenuItems() async {
    final api = Provider.of<ApiService>(context, listen: false);
    for (final item in _extractedItems) {
      if (item['selected'] == true) {
        await api.createMenuItem({
          'restaurant_id': _restaurantId,
          'name': item['name'],
          'description': item['description'] ?? '',
          'price': item['price'],
        });
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.t('menu_items_saved'))));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.t('scan_menu'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover)
            else
              Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.camera_alt, size: 64, color: Colors.grey)),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload),
              label: Text(L10n.t('pick_image')),
            ),
            if (_image != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _processing ? null : _scanMenu,
                icon: const Icon(Icons.document_scanner),
                label: _processing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(L10n.t('scan_menu')),
              ),
            ],
            const SizedBox(height: 16),
            if (_extractedItems.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _extractedItems.length,
                  itemBuilder: (context, i) {
                    final item = _extractedItems[i];
                    return Card(
                      child: CheckboxListTile(
                        value: item['selected'] == true,
                        onChanged: (v) => setState(() => item['selected'] = v),
                        title: Text(item['name'] ?? 'Item'),
                        subtitle: Text('${item['price'] ?? 0} XAF'),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(onPressed: _saveMenuItems, child: Text(L10n.t('save_selected'))),
            ],
          ],
        ),
      ),
    );
  }
}