import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/auth_provider.dart';
import 'services/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_confirmation_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/delivery_tracking_screen.dart';
import 'screens/owner_pos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  final authProvider = AuthProvider(apiService: api);
  await authProvider.init();
  runApp(BitedashApp(api: api, authProvider: authProvider));
}

class BitedashApp extends StatelessWidget {
  final ApiService api;
  final AuthProvider authProvider;
  const BitedashApp({required this.api, required this.authProvider, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ],
      child: Consumer<AuthProvider>(builder: (context, auth, _) {
        return MaterialApp(
          title: 'Bitedash',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (ctx) => AuthGate(child: const HomeScreen()),
            '/login': (ctx) => const LoginScreen(),
            '/register': (ctx) => const RegisterScreen(),
            '/profile': (ctx) => const ProfileScreen(),
            '/cart': (ctx) => const CartScreen(),
            '/checkout': (ctx) => const CheckoutScreen(),
            '/order-confirmation': (ctx) => const OrderConfirmationScreen(),
            '/notifications': (ctx) => const NotificationsScreen(),
            '/delivery-tracking': (ctx) => const DeliveryTrackingScreen(),
            '/owner-pos': (ctx) => const OwnerPosScreen(),
          },
        );
      }),
    );
  }
}

class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    return child;
  }
}
