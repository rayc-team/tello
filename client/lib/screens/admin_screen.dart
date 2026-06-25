import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/podcast_provider.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0; // Для переключения вкладок BottomNavigationBar.
  bool _isShowingPodcasts = true; // Переключатель внутри вкладки "Каталог".

  final ApiService _apiService = ApiService();
  List<dynamic> _usersList = [];
  bool _isLoadingUsers = false;

  // Поля формы публикации подкаста.
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Научные лекции для расширения знаний';
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;

  final List<String> _predefinedCategories = [
    'Научные лекции для расширения знаний',
    'Искусство и культура',
    'Технологии',
  ];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final token = context.read<AuthProvider>().token;
    // Обновляем список подкастов в провайдере.
    context.read<PodcastProvider>().fetchPodcasts(token: token);
    _fetchUsers();
  }

  // Загрузка пользователей с сервера.
  Future<void> _fetchUsers() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isLoadingUsers = true);
    try {
      final list = await _apiService.getUsers(token);
      setState(() => _usersList = list);
    } catch (e) {
      debugPrint('Ошибка при получении пользователей: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  // Метод выбора MP3 файла.
  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  // Метод публикации подкаста на FastAPI.
  void _submitPodcast() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите файл подкаста (.mp3)'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    final token = context.read<AuthProvider>().token;

    try {
      await _apiService.uploadPodcast(
        token: token!,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        filePath: _selectedFilePath!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подкаст успешно опубликован!')),
        );
        // Сбрасываем форму.
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedFilePath = null;
          _selectedFileName = null;
        });
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Запрос на удаление подкаста с подтверждением.
  void _confirmDelete(int id, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: Text('Вы действительно хотите удалить подкаст "$title"?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(context);
                final token = context.read<AuthProvider>().token;
                try {
                  await _apiService.deletePodcast(id, token!);
                  _refreshData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Подкаст удален')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка удаления: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildCatalogTab() : _buildPublishTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Каталог',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload),
            label: 'Публикация',
          ),
        ],
      ),
    );
  }

  // Вкладка 1: Просмотр каталога подкастов и пользователей.
  Widget _buildCatalogTab() {
    final podcastProvider = context.watch<PodcastProvider>();

    return Column(
      children: [
        // Селектор: Подкасты / Пользователи.
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Подкасты'),
                icon: Icon(Icons.audiotrack),
              ),
              ButtonSegment(
                value: false,
                label: Text('Пользователи'),
                icon: Icon(Icons.people),
              ),
            ],
            selected: {_isShowingPodcasts},
            onSelectionChanged: (value) {
              setState(() => _isShowingPodcasts = value.first);
            },
          ),
        ),
        Expanded(
          child: _isShowingPodcasts
              ? (podcastProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : podcastProvider.podcasts.isEmpty
                    ? const Center(child: Text('Подкастов пока нет'))
                    : ListView.builder(
                        itemCount: podcastProvider.podcasts.length,
                        itemBuilder: (context, index) {
                          final podcast = podcastProvider.podcasts[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.music_video,
                              color: Colors.deepPurple,
                            ),
                            title: Text(podcast.title),
                            subtitle: Text(podcast.category),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _confirmDelete(podcast.id, podcast.title),
                            ),
                          );
                        },
                      ))
              : (_isLoadingUsers
                    ? const Center(child: CircularProgressIndicator())
                    : _usersList.isEmpty
                    ? const Center(child: Text('Пользователей нет'))
                    : ListView.builder(
                        itemCount: _usersList.length,
                        itemBuilder: (context, index) {
                          final user = _usersList[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(user['email']),
                            subtitle: Text('Роль: ${user['role']}'),
                          );
                        },
                      )),
        ),
      ],
    );
  }

  // Вкладка 2: Форма публикации подкаста.
  Widget _buildPublishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Опубликовать новый подкаст',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название подкаста *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Поле является обязательным';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категория *',
                border: OutlineInputBorder(),
              ),
              items: _predefinedCategories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() => _selectedCategory = newValue!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание подкаста',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Выбор аудиофайла.
            InkWell(
              onTap: _isUploading ? null : _pickAudioFile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? 'Выберите аудиофайл .mp3 *',
                        style: TextStyle(
                          color: _selectedFileName == null
                              ? Colors.black54
                              : Colors.black,
                          fontWeight: _selectedFileName == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_selectedFileName != null)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitPodcast,
                      child: const Text('Опубликовать'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
