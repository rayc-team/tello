import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // Автоматически определяем адрес в зависимости от платформы.
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

  Future<List<dynamic>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/users'),
      headers: {'Authorization': 'Bearer $token', 'accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Не удалось загрузить список пользователей');
    }
  }

  Future<void> deletePodcast(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/podcasts/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Не удалось удалить подкаст на сервере');
    }
  }

  Future<Map<String, dynamic>> uploadPodcast({
    required String token,
    required String title,
    required String category,
    String? description,
    required String filePath,
  }) async {
    final uri = Uri.parse('$baseUrl/podcasts/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = title
      ..fields['category'] = category;

    if (description != null) {
      request.fields['description'] = description;
    }

    // Создаем multipart-файл с явным указанием типа audio/mpeg.
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType('audio', 'mpeg'),
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // Извлечение ошибки валидации FastAPI.
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
