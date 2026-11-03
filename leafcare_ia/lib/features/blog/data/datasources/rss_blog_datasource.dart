import 'package:leafcare_ia/core/constants/api_constants.dart';
import 'package:leafcare_ia/core/network/http_client.dart';
import 'package:leafcare_ia/features/blog/data/models/article_model.dart';

class RssBlogDatasource {
  RssBlogDatasource({AppHttpClient? httpClient})
    : _httpClient = httpClient ?? const AppHttpClient();

  final AppHttpClient _httpClient;

  Future<List<ArticleModel>> fetchArticles() async {
    final uri = Uri.parse(
      '${ApiConstants.rssToJasonUrl}${Uri.encodeComponent(ApiConstants.gardeningRssUrl)}',
    );

    final json = await _httpClient.getJson(uri);
    if (json['status'] != 'ok') {
      throw Exception('No se pudieron cargar los artículos');
    }

    final items = json['items'];
    if (items is! List) return const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(_fromRssItem)
        .toList(growable: false);
  }

  ArticleModel _fromRssItem(Map<String, dynamic> item) {
    final content = (item['content'] as String?) ?? '';
    final description = (item['description'] as String?) ?? '';
    final categories = item['categories'];
    final category = categories is List && categories.isNotEmpty
        ? '${categories.first}'
        : 'Jardinería';

    String imageUrl = (item['thumbnail'] as String?)?.trim() ?? '';

    if (imageUrl.isEmpty) {
      imageUrl =
          _extractImageUrl(content) ?? _extractImageUrl(description) ?? '';
    }

    final cleanDescription = description
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .trim();

    return ArticleModel(
      id: (item['guid'] as String?)?.trim().isNotEmpty == true
          ? item['guid'] as String
          : (item['link'] as String? ?? ''),
      title: (item['title'] as String?)?.trim() ?? 'Sin título',
      author: (item['author'] as String?)?.trim().isNotEmpty == true
          ? item['author'] as String
          : 'Redacción',
      category: category,
      imageUrl: imageUrl,
      readTime: _readTimeFrom(content),
      link: (item['link'] as String?) ?? '',
      description: cleanDescription,
    );
  }

  String? _extractImageUrl(String html) {
    final regExp = RegExp(r'<img[^>]+src="([^">]+)"');
    final match = regExp.firstMatch(html);
    return match?.group(1);
  }

  String _readTimeFrom(String html) {
    final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final minutes = (words / 200).ceil().clamp(1, 30);
    return '$minutes min';
  }
}
