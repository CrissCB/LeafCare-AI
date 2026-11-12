import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import 'package:leafcare_ia/core/constants/api_constants.dart';
import 'package:leafcare_ia/features/blog/data/models/article_model.dart';

class RssBlogDatasource {
  RssBlogDatasource();

  Future<List<ArticleModel>> fetchArticles() async {
    try {
      final url = kIsWeb
          ? ApiConstants.webGardeningRssProxy
          : ApiConstants.gardeningRssUrl;

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return const [];
      }

      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      return items.map(_fromXmlItem).toList(growable: false);
    } catch (e) {
      return const [];
    }
  }

  ArticleModel _fromXmlItem(xml.XmlElement node) {
    final title =
        node.findElements('title').firstOrNull?.innerText ?? 'Sin título';
    final link = node.findElements('link').firstOrNull?.innerText ?? '';
    final guid = node.findElements('guid').firstOrNull?.innerText ?? link;
    final author =
        node.findElements('dc:creator').firstOrNull?.innerText ?? 'Redacción';
    final category =
        node.findElements('category').firstOrNull?.innerText ?? 'Jardinería';
    final descriptionRaw =
        node.findElements('description').firstOrNull?.innerText ?? '';
    final contentEncoded =
        node.findElements('content:encoded').firstOrNull?.innerText ?? '';

    String imageUrl =
        _extractImageUrl(contentEncoded) ??
        _extractImageUrl(descriptionRaw) ??
        '';

    final cleanDescription = descriptionRaw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return ArticleModel(
      id: guid.trim().isNotEmpty ? guid.trim() : link.trim(),
      title: title.trim(),
      author: author.trim(),
      category: category.trim(),
      imageUrl: imageUrl.trim(),
      readTime: _readTimeFrom(
        contentEncoded.isNotEmpty ? contentEncoded : descriptionRaw,
      ),
      link: link.trim(),
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
