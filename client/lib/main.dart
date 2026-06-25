import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/admin_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Podcasts App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Маршрутизация на основе статуса авторизации и роли пользователя
      home: _getHomeScreen(authProvider),
    );
  }

  Widget _getHomeScreen(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }
    if (authProvider.role == 'admin') {
      return const AdminScreen();
    }
    return const MainScreen();
  }
}
