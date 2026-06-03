import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Email: ${auth.user?.email ?? '—'}'),
          const SizedBox(height: 8),
          Text('Name: ${auth.user?.fullName ?? '—'}'),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () async { await auth.logout(); }, child: const Text('Sign out')),
        ]),
      ),
    );
  }
}
