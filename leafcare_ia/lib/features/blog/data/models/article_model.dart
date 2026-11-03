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

  ArticleModel copyWith({bool? saved, String? savedRecordId}) {
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
      savedRecordId: savedRecordId ?? this.savedRecordId,
    );
  }

  // Mapeo desde la respuesta de PocketBase a ArticleModel
  factory ArticleModel.fromPocketBase(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['external_article_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Sin título',
      author: json['author'] as String? ?? 'Redacción',
      category: json['category'] as String? ?? 'Jardinería',
      imageUrl: json['image_url'] as String? ?? '',
      readTime: json['read_time'] as String? ?? '3 min',
      link: json['external_article_id'] as String? ?? '',
      description: '',
      saved: true,
      savedRecordId: json['id'] as String?,
    );
  }

  // Mapeo desde ArticleModel a la estructura esperada por PocketBase
  Map<String, dynamic> toPocketBase(String userId) {
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
