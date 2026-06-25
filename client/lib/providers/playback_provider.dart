import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/podcast_model.dart';
import '../services/api_service.dart';

class PlaybackProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PodcastModel? _currentPodcast;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  PodcastModel? get currentPodcast => _currentPodcast;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  PlaybackProvider() {
    // Подписка на изменение состояния воспроизведения.
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    // Подписка на изменение общей длительности аудиофайла.
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    // Подписка на изменение текущего положения воспроизведения.
    _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });
  }

  Future<void> play(PodcastModel podcast) async {
    // Если нажат уже выбранный подкаст, переключаем play/pause.
    if (_currentPodcast?.id == podcast.id) {
      if (_isPlaying) {
        await pause();
      } else {
        await _audioPlayer.resume();
      }
      return;
    }

    _currentPodcast = podcast;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();

    // Формируем полный URL для проигрывания аудиофайла со статического эндпоинта сервера.
    final fullUrl = '${ApiService.baseUrl}${podcast.filePath}';
    await _audioPlayer.play(UrlSource(fullUrl));
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentPodcast = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
