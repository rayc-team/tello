import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/podcast_model.dart';
import '../services/api_service.dart';

class PodcastProvider with ChangeNotifier {
  List<PodcastModel> _podcasts = [];
  final List<String> _categories = [
    'Все',
    'Научные лекции для расширения знаний',
    'Искусство и культура',
    'Технологии',
  ];
  String _selectedCategory = 'Все';
  String _searchQuery = '';
  bool _isLoading = false;

  List<PodcastModel> get podcasts => _podcasts;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> fetchPodcasts({String? token}) async {
    if (token == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      String url = '${ApiService.baseUrl}/podcasts/';
      List<String> queryParams = [];

      // Добавляем фильтр по категории (если выбрана не 'Все')
      if (_selectedCategory != 'Все') {
        queryParams.add('category=${Uri.encodeComponent(_selectedCategory)}');
      }
      // Добавляем поисковый запрос (если он заполнен)
      if (_searchQuery.isNotEmpty) {
        queryParams.add('q=${Uri.encodeComponent(_searchQuery)}');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _podcasts = data.map((json) => PodcastModel.fromJson(json)).toList();
      } else {
        throw Exception('Не удалось загрузить подкасты');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке подкастов: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category, String? token) {
    _selectedCategory = category;
    fetchPodcasts(token: token);
  }

  void setSearchQuery(String query, String? token) {
    _searchQuery = query;
    fetchPodcasts(token: token);
  }
}
