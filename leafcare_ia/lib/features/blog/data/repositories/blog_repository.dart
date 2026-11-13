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

  /// Obtiene los artículos del RSS y los cruza con los guardados en Supabase.
  Future<List<ArticleModel>> fetchArticles() async {
    final articles = await rssDatasource.fetchArticles();
    final savedMap = await _savedArticlesIndex();
    if (savedMap.isEmpty) return articles;

    return articles
        .map((article) {
          final recordId = savedMap[article.id];
          if (recordId == null) return article;
          return article.copyWith(saved: true, savedRecordId: recordId);
        })
        .toList(growable: false);
  }

  /// Obtiene únicamente los artículos guardados por el usuario desde Supabase.
  Future<List<ArticleModel>> fetchSavedArticles() async {
    final userId = supabaseClient.currentUserId;
    if (!supabaseClient.isAuthenticated || userId == null) {
      return const [];
    }

    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      return (response as List<dynamic>)
          .map((row) => ArticleModel.fromJson(row as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Alterna el estado de guardado (Insertar/Upsert o Eliminar registro).
  Future<ArticleModel> toggleSave(ArticleModel article) async {
    final userId = supabaseClient.currentUserId;
    if (!supabaseClient.isAuthenticated || userId == null) {
      throw const BlogAuthRequiredException();
    }

    if (article.saved) {
      await _client
          .from(_table)
          .delete()
          .eq('external_article_id', article.id)
          .eq('user_id', userId);

      return article.copyWith(saved: false, clearSavedRecordId: true);
    }

    final inserted = await _client
        .from(_table)
        .upsert(
          article.toJson(userId),
          onConflict: 'user_id,external_article_id',
        )
        .select('id')
        .single();

    return article.copyWith(
      saved: true,
      savedRecordId: inserted['id']?.toString(),
    );
  }

  /// Mapa `{ external_article_id: record_uuid }` de los artículos guardados.
  Future<Map<String, String>> _savedArticlesIndex() async {
    try {
      final userId = supabaseClient.currentUserId;
      if (!supabaseClient.isAuthenticated || userId == null) return const {};

      final response = await _client
          .from(_table)
          .select('id, external_article_id')
          .eq('user_id', userId);

      final result = <String, String>{};
      for (final row in response as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final externalId = map['external_article_id'] as String? ?? '';
        final recordId = map['id']?.toString() ?? '';
        if (externalId.isNotEmpty && recordId.isNotEmpty) {
          result[externalId] = recordId;
        }
      }
      return result;
    } on PostgrestException {
      return const {};
    } catch (_) {
      return const {};
    }
  }
}
