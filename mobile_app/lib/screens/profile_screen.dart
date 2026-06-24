import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _cities = [];
  bool _loadingCities = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final cities = await api.fetchCities();
    setState(() {
      _cities = cities;
      _loadingCities = false;
    });
  }

  Future<void> _updateCity(int? cityId) async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.updateUserCity(cityId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('City preference saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save city')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile ${user?.role == 'restaurant_owner' || user?.role == 'delivery_agent' ? (auth.isApproved ? '(Verified)' : '(Pending)') : ''}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(user?.fullName ?? '—'),
            subtitle: Text('${user?.role ?? '—'} ${auth.isApproved ? '✓ Verified' : ''}'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(user?.email ?? '—'),
          ),
          if (user?.phone != null)
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(user!.phone!),
            ),
          const SizedBox(height: 16),
          const Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loadingCities)
            const LinearProgressIndicator()
          else
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Preferred City', border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: user?.cityId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select City')),
                    ..._cities.map((c) => DropdownMenuItem(value: int.tryParse('${c['id']}') ?? 0, child: Text('${c['name']}, ${c['country']}')),
                    ).toList(),
                  ],
                  onChanged: (v) => _updateCity(v),
                ),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ]),
      ),
    );
  }
}