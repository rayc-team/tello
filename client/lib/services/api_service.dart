import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Автоматически определяем адрес в зависимости от платформы эмулятора
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // Извлечение ошибки валидации FastAPI
      String errorMessage = 'Произошла ошибка';
      if (data is Map && data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List) {
          errorMessage = detail.map((e) => e['msg']).join(', ');
        }
      }
      throw Exception(errorMessage);
    }
  }
}
