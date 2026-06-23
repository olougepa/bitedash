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
import 'screens/delivery_agent_screen.dart';
import 'screens/promotions_screen.dart';
import 'screens/receipt_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/kyc_screen.dart';

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
            '/': (ctx) => const HomeScreen(),
            '/login': (ctx) => const LoginScreen(),
            '/register': (ctx) => const RegisterScreen(),
            '/profile': (ctx) => const ProfileScreen(),
            '/cart': (ctx) => const CartScreen(),
            '/checkout': (ctx) => const CheckoutScreen(),
            '/order-confirmation': (ctx) => const OrderConfirmationScreen(),
            '/notifications': (ctx) => const NotificationsScreen(),
            '/delivery-tracking': (ctx) => const DeliveryTrackingScreen(),
            '/owner-pos': (ctx) => const OwnerPosScreen(),
            '/delivery-agent': (ctx) => const DeliveryAgentScreen(),
            '/promotions': (ctx) => const PromotionsScreen(),
            '/receipt': (ctx) => const ReceiptScreen(order: {}),
            '/chat': (ctx) => const ChatScreen(orderId: 0),
            '/kyc': (ctx) => const KycScreen(role: 'restaurant_owner'),
          },
        );
      }),
    );
  }
}