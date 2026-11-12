import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/features/blog/data/datasources/rss_blog_datasource.dart';
import 'package:leafcare_ia/features/blog/data/models/article_model.dart';

class BlogAuthRequiredException implements Exception {
  const BlogAuthRequiredException();
}

class BlogRepository {
  BlogRepository({required this.rssDatasource, required this.supabaseClient});

  final RssBlogDatasource rssDatasource;
  final AppSupabaseClient supabaseClient;

  static const _table = 'saved_blog_articles';

  SupabaseClient get _client => supabaseClient.client;

  /// Obtiene los artículos del RSS y los cruza con los guardados en PostgreSQL
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

  /// Alterna el estado de guardado (Insertar o Eliminar registro)
  Future<ArticleModel> toggleSave(ArticleModel article) async {
    final userId = supabaseClient.currentUserId;
    if (!supabaseClient.isAuthenticated || userId == null) {
      throw const BlogAuthRequiredException();
    }

    if (article.saved) {
      // Eliminar artículo de marcadores
      await _client
          .from(_table)
          .delete()
          .eq('external_article_id', article.id)
          .eq('user_id', userId);

      return article.copyWith(saved: false);
    }

    // Insertar artículo en marcadores
    await _client.from(_table).insert({
      'external_article_id': article.id,
      'title': article.title,
      'author': article.author,
      'category': article.category,
      'image_url': article.imageUrl,
      'read_time': article.readTime,
      'user_id': userId,
    });

    return article.copyWith(saved: true);
  }

  /// Consulta los IDs de los artículos guardados por el usuario
  Future<Set<String>> _savedExternalIds() async {
    try {
      final userId = supabaseClient.currentUserId;
      if (!supabaseClient.isAuthenticated || userId == null) return const {};

      final response = await _client
          .from(_table)
          .select('external_article_id')
          .eq('user_id', userId);

      final List<dynamic> data = response as List<dynamic>;

      return data
          .map((row) => row['external_article_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } on PostgrestException {
      return const {};
    } catch (_) {
      return const {};
    }
  }
}
