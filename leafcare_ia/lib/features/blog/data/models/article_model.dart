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

  ArticleModel copyWith({bool? saved}) {
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
    );
  }
}
