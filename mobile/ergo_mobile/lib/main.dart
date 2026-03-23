import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/landlord/dashboard_screen.dart';

void main() {
  runApp(const ErgoApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/landlord/dashboard',
      builder: (context, state) => const LandlordDashboardScreen(),
    ),
  ],
);

class ErgoApp extends StatelessWidget {
  const ErgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ergo Mobile',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
