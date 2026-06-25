class PodcastModel {
  final int id;
  final String title;
  final String category;
  final String? description;
  final String filePath;
  final DateTime createdAt;

  PodcastModel({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    required this.filePath,
    required this.createdAt,
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    return PodcastModel(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      description: json['description'],
      filePath: json['file_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
