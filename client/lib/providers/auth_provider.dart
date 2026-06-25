import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  String? _token;
  String? _role;
  bool _isLoading = false;

  String? get token => _token;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadTokenFromStorage();
  }

  // Проверяем, сохранен ли токен на устройстве при запуске приложения
  Future<void> _loadTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    _role = prefs.getString('user_role');
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.register(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.login(email, password);
      _token = data['access_token'];
      _role = data['role'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _token!);
      await prefs.setString('user_role', _role!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    notifyListeners();
  }
}
