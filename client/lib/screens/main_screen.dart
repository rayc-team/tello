import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/playback_provider.dart';
import '../providers/podcast_provider.dart';
import '../widgets/player_bottom_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      context.read<PodcastProvider>().fetchPodcasts(token: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final podcastProvider = context.watch<PodcastProvider>();
    final playbackProvider = context.watch<PlaybackProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TELLO'),
        leading: const Icon(Icons.waves, color: Color(0xFF9E77FA)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white70),
            onPressed: () {
              context.read<PlaybackProvider>().stop();
              authProvider.logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Поисковая строка.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: TextField(
              controller: _searchController,
              maxLength: 255,
              decoration: InputDecoration(
                hintText: 'Поиск подкастов...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1A1A22),
                counterText: '',
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          podcastProvider.setSearchQuery(
                            '',
                            authProvider.token,
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                podcastProvider.setSearchQuery(value, authProvider.token);
              },
            ),
          ),

          // 2. Блок фильтрации по категориям.
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: podcastProvider.categories.length,
              itemBuilder: (context, index) {
                final category = podcastProvider.categories[index];
                final isSelected = podcastProvider.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF7C4DFF),
                    backgroundColor: const Color(0xFF1A1A22),
                    onSelected: (selected) {
                      if (selected) {
                        podcastProvider.selectCategory(
                          category,
                          authProvider.token,
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 3. Список доступных подкастов в виде карточек.
          Expanded(
            child: podcastProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : podcastProvider.podcasts.isEmpty
                ? const Center(
                    child: Text(
                      'Нет доступных подкастов',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: podcastProvider.podcasts.length,
                    itemBuilder: (context, index) {
                      final podcast = podcastProvider.podcasts[index];
                      final isCurrent =
                          playbackProvider.currentPodcast?.id == podcast.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          elevation: isCurrent ? 4 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: isCurrent
                              ? const Color(0xFF241E3A)
                              : const Color(0xFF1A1A22),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => playbackProvider.play(podcast),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Проигрыватель/Иконка состояния
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isCurrent
                                        ? const Color(
                                            0xFF00E676,
                                          ).withValues(alpha: 0.15)
                                        : const Color(
                                            0xFF7C4DFF,
                                          ).withValues(alpha: 0.15),
                                    child: Icon(
                                      isCurrent && playbackProvider.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isCurrent
                                          ? const Color(0xFF00E676)
                                          : const Color(0xFF9E77FA),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Информация.
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Бейдж категории.
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            podcast.category,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          podcast.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isCurrent
                                                ? const Color(0xFF00E676)
                                                : Colors.white,
                                          ),
                                        ),
                                        if (podcast.description != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            podcast.description!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white38,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (playbackProvider.currentPodcast != null)
            const SizedBox(height: 90),
        ],
      ),
      bottomSheet: playbackProvider.currentPodcast != null
          ? const PlayerBottomSheet()
          : null,
    );
  }
}
