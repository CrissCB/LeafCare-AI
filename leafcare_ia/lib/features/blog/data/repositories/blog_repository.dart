import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/core/network/pocketbase_client.dart';
import 'package:leafcare_ia/features/blog/data/datasources/rss_blog_datasource.dart';
import 'package:leafcare_ia/features/blog/data/models/article_model.dart';

class BlogAuthRequiredException implements Exception {
  const BlogAuthRequiredException();
}

class BlogRepository {
  BlogRepository({required this.rssDatasource});

  final RssBlogDatasource rssDatasource;

  static const _collection = 'saved_blog_articles';

  Future<List<ArticleModel>> fetchArticles() async {
    final articles = await rssDatasource.fetchArticles();
    final savedIds = await _savedExternalIds();
    if (savedIds.isEmpty) return articles;

    return articles
        .map(
          (article) => article.copyWith(saved: savedIds.contains(article.id)),
        )
        .toList(growable: false);
  }

  Future<ArticleModel> toggleSave(ArticleModel article) async {
    final pb = await PocketBaseClient.getInstance();
    final userId = pb.authStore.record?.id;
    if (!pb.authStore.isValid || userId == null) {
      throw const BlogAuthRequiredException();
    }

    if (article.saved) {
      final existing = await pb
          .collection(_collection)
          .getFirstListItem(
            'external_article_id = "${_escape(article.id)}" && user_id = "$userId"',
          );
      await pb.collection(_collection).delete(existing.id);
      return article.copyWith(saved: false);
    }

    await pb
        .collection(_collection)
        .create(
          body: {
            'external_article_id': article.id,
            'title': article.title,
            'author': article.author,
            'category': article.category,
            'image_url': article.imageUrl,
            'read_time': article.readTime,
            'user_id': userId,
          },
        );
    return article.copyWith(saved: true);
  }

  Future<Set<String>> _savedExternalIds() async {
    try {
      final pb = await PocketBaseClient.getInstance();
      final userId = pb.authStore.record?.id;
      if (!pb.authStore.isValid || userId == null) return const {};

      final records = await pb
          .collection(_collection)
          .getFullList(filter: 'user_id = "$userId"');

      return records
          .map((record) => record.get<String>('external_article_id', ''))
          .where((id) => id.isNotEmpty)
          .toSet();
    } on ClientException {
      return const {};
    } catch (_) {
      return const {};
    }
  }

  String _escape(String value) =>
      value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}
