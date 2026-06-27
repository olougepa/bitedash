import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';

class KycScreen extends StatefulWidget {
  final String role;
  const KycScreen({required this.role, super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _documentNumberController = TextEditingController();
  String _documentType = 'id_card';
  bool _loading = false;
  bool _uploading = false;
  String? _documentImageUrl;
  String? _documentFilePath;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        final mimeType = file.extension?.toLowerCase() == 'pdf' ? 'application/pdf' : 'image/${file.extension}';
        final api = Provider.of<ApiService>(context, listen: false);
        setState(() => _uploading = true);
        try {
          final url = await api.uploadFile(file.bytes!, file.name, mimeType);
          setState(() {
            _documentImageUrl = url;
            _documentFilePath = file.path;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
          }
        }
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _submitKyc() async {
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await api.updateKyc(auth.token!, widget.role, _documentType, _documentNumberController.text, documentImageUrl: _documentImageUrl);
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KYC submitted, awaiting approval')));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.verified_user, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 20),
            Text('${widget.role == 'restaurant_owner' ? 'Restaurant Owner' : 'Delivery Agent'} Verification', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Please provide your identification documents for verification', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            DropdownMenu<String>(
              label: const Text('Document Type'),
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: 'id_card', label: 'ID Card'),
                DropdownMenuEntry(value: 'passport', label: 'Passport'),
                DropdownMenuEntry(value: 'driver_license', label: 'Driver License'),
                DropdownMenuEntry(value: 'business_license', label: 'Business License'),
              ],
              onSelected: (v) => setState(() => _documentType = v ?? 'id_card'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _documentNumberController,
              decoration: const InputDecoration(labelText: 'Document Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            _uploading
                ? const CircularProgressIndicator()
                : OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(_documentImageUrl != null ? 'Document Uploaded (${_documentFilePath?.split('.').last ?? 'file'})' : 'Upload Document (Image or PDF)'),
                    onPressed: _loading ? null : _pickDocument,
                  ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, minimumSize: const Size.fromHeight(48)),
              onPressed: _loading ? null : _submitKyc,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit for Verification'),
            ),
          ],
        ),
      ),
    );
  }
}