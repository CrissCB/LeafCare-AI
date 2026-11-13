class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.imageUrl,
    required this.readTime,
    required this.link,
    required this.description,
    this.saved = false,
    this.savedRecordId,
  });

  final String id;
  final String title;
  final String author;
  final String category;
  final String imageUrl;
  final String readTime;
  final String link;
  final String description;
  final bool saved;
  final String? savedRecordId;

  ArticleModel copyWith({
    bool? saved,
    String? savedRecordId,
    bool clearSavedRecordId = false,
  }) {
    return ArticleModel(
      id: id,
      title: title,
      author: author,
      category: category,
      imageUrl: imageUrl,
      readTime: readTime,
      link: link,
      description: description,
      saved: saved ?? this.saved,
      savedRecordId: clearSavedRecordId
          ? null
          : (savedRecordId ?? this.savedRecordId),
    );
  }

  /// Mapeo desde una fila de la tabla `saved_articles` en Supabase.
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final externalId = json['external_article_id'] as String? ?? '';

    return ArticleModel(
      id: externalId,
      title: json['title'] as String? ?? 'Sin título',
      author: json['author'] as String? ?? 'Redacción',
      category: json['category'] as String? ?? 'Jardinería',
      imageUrl: json['image_url'] as String? ?? '',
      readTime: json['read_time'] as String? ?? '3 min',
      link: (json['link'] as String?)?.isNotEmpty == true
          ? json['link'] as String
          : externalId,
      description: json['description'] as String? ?? '',
      saved: true,
      savedRecordId: json['id']?.toString(),
    );
  }

  /// Mapeo desde ArticleModel hacia el payload de inserción en Supabase.
  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'external_article_id': id,
      'title': title,
      'category': category,
      'author': author,
      'read_time': readTime,
      'image_url': imageUrl,
    };
  }
}
