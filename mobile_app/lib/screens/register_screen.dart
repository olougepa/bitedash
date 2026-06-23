import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  String _role = 'customer';
  bool _usePhone = false;
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool ok;
    if (_usePhone) {
      ok = await auth.registerWithPhone(_phone.text.trim(), _password.text.trim(), _name.text, role: _role);
    } else {
      ok = await auth.register(_email.text.trim(), _password.text.trim(), _name.text, role: _role);
    }
    setState(() => _loading = false);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.delivery_dining, size: 80, color: Colors.deepOrange),
              const SizedBox(height: 20),
              const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Join BiteDash', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Email'), icon: Icon(Icons.email)),
                  ButtonSegment(value: true, label: Text('Phone'), icon: Icon(Icons.phone)),
                ],
                selected: {_usePhone},
                onSelectionChanged: (modes) => setState(() => _usePhone = modes.first),
              ),
              const SizedBox(height: 16),
              if (!_usePhone)
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                )
              else
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownMenu<String>(
                label: const Text('I want to sign up as'),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'customer', label: 'Customer'),
                  DropdownMenuEntry(value: 'restaurant_owner', label: 'Restaurant Owner'),
                  DropdownMenuEntry(value: 'delivery_agent', label: 'Delivery Agent'),
                ],
                onSelected: (v) => setState(() => _role = v ?? 'customer'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, minimumSize: const Size.fromHeight(48)),
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account'),
              ),
              TextButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Already have an account? Sign In')),
            ],
          ),
        ),
      ),
    );
  }
}