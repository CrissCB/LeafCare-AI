import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:leafcare_ia/features/blog/data/models/article_model.dart';
import 'package:leafcare_ia/features/blog/data/repositories/blog_repository.dart';

// --- EVENTOS ---
abstract class BlogEvent {}

class BlogStarted extends BlogEvent {}

class BlogRefreshed extends BlogEvent {}

class BlogSaveToggled extends BlogEvent {
  BlogSaveToggled(this.article);
  final ArticleModel article;
}

class BlogCategorySelected extends BlogEvent {
  BlogCategorySelected(this.category);
  final String category;
}

class BlogSearchQueryChanged extends BlogEvent {
  BlogSearchQueryChanged(this.query);
  final String query;
}

// --- ESTADOS ---
abstract class BlogState {}

class BlogInitial extends BlogState {}

class BlogLoading extends BlogState {}

class BlogLoaded extends BlogState {
  BlogLoaded(
    this.allArticles, {
    this.selectedCategory = 'Todos',
    this.searchQuery = '',
    this.savingArticleIds = const {},
    this.notice,
    this.noticeIsError = false,
  });

  /// Lista completa (RSS en vivo + artículos guardados en Supabase).
  final List<ArticleModel> allArticles;
  final String selectedCategory;
  final String searchQuery;

  /// IDs de artículos cuya operación de guardado está en curso.
  final Set<String> savingArticleIds;

  final String? notice;
  final bool noticeIsError;

  /// Lista visible ya filtrada por categoría y búsqueda.
  List<ArticleModel> get articles {
    final query = searchQuery.trim().toLowerCase();

    return allArticles
        .where((article) {
          final matchesCategory = switch (selectedCategory) {
            'Todos' => true,
            'Guardados' => article.saved,
            _ =>
              article.category.toLowerCase() == selectedCategory.toLowerCase(),
          };

          if (!matchesCategory) return false;
          if (query.isEmpty) return true;

          return article.title.toLowerCase().contains(query) ||
              article.description.toLowerCase().contains(query) ||
              article.author.toLowerCase().contains(query) ||
              article.category.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  /// Categorías disponibles dinámicamente a partir de los artículos cargados.
  List<String> get categories {
    final dynamicCategories = allArticles
        .map((a) => a.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    return ['Todos', 'Guardados', ...dynamicCategories];
  }

  int get savedCount => allArticles.where((a) => a.saved).length;

  BlogLoaded copyWith({
    List<ArticleModel>? allArticles,
    String? selectedCategory,
    String? searchQuery,
    Set<String>? savingArticleIds,
    String? notice,
    bool noticeIsError = false,
    bool clearNotice = false,
  }) {
    return BlogLoaded(
      allArticles ?? this.allArticles,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      savingArticleIds: savingArticleIds ?? this.savingArticleIds,
      notice: clearNotice ? null : notice,
      noticeIsError: clearNotice ? false : noticeIsError,
    );
  }
}

class BlogError extends BlogState {
  BlogError(this.message);
  final String message;
}

// --- BLOC ---
class BlogBloc extends Bloc<BlogEvent, BlogState> {
  BlogBloc({required this.repository}) : super(BlogInitial()) {
    on<BlogStarted>(_onLoad);
    on<BlogRefreshed>(_onRefresh);
    on<BlogSaveToggled>(_onSaveToggled);
    on<BlogCategorySelected>(_onCategorySelected);
    on<BlogSearchQueryChanged>(_onSearchChanged);
  }

  final BlogRepository repository;

  Future<void> _onLoad(BlogStarted event, Emitter<BlogState> emit) async {
    emit(BlogLoading());
    await _fetchAndEmit(emit, isRefresh: false);
  }

  Future<void> _onRefresh(BlogRefreshed event, Emitter<BlogState> emit) async {
    if (state is! BlogLoaded) {
      emit(BlogLoading());
    }
    await _fetchAndEmit(emit, isRefresh: state is BlogLoaded);
  }

  Future<void> _fetchAndEmit(
    Emitter<BlogState> emit, {
    required bool isRefresh,
  }) async {
    try {
      final results = await Future.wait([
        repository.fetchArticles(),
        repository.fetchSavedArticles(),
      ]);

      final rssArticles = results[0];
      final savedArticles = results[1];
      final merged = _mergeArticles(rssArticles, savedArticles);

      if (merged.isEmpty) {
        emit(
          BlogError(
            'No hay artículos disponibles en este momento. Verifica tu conexión.',
          ),
        );
        return;
      }

      final previous = state;
      if (isRefresh && previous is BlogLoaded) {
        emit(previous.copyWith(allArticles: merged, clearNotice: true));
      } else {
        emit(BlogLoaded(merged));
      }
    } catch (_) {
      final previous = state;
      if (isRefresh && previous is BlogLoaded) {
        emit(
          previous.copyWith(
            notice: 'No se pudo actualizar el feed.',
            noticeIsError: true,
          ),
        );
      } else {
        emit(
          BlogError('No se pudieron cargar los artículos. Inténtalo de nuevo.'),
        );
      }
    }
  }

  Future<void> _onSaveToggled(
    BlogSaveToggled event,
    Emitter<BlogState> emit,
  ) async {
    final current = state;
    if (current is! BlogLoaded) return;

    final targetId = event.article.id;
    // Evita envíos duplicados si el usuario pulsa varias veces rápido
    if (current.savingArticleIds.contains(targetId)) return;

    emit(
      current.copyWith(
        savingArticleIds: {...current.savingArticleIds, targetId},
        clearNotice: true,
      ),
    );

    try {
      final updated = await repository.toggleSave(event.article);
      final latestState = state is BlogLoaded ? state as BlogLoaded : current;
      final remainingSaving = {...latestState.savingArticleIds}
        ..remove(targetId);

      emit(
        latestState.copyWith(
          allArticles: _replace(latestState.allArticles, updated),
          savingArticleIds: remainingSaving,
          notice: updated.saved
              ? 'Artículo guardado'
              : 'Artículo quitado de guardados',
          noticeIsError: false,
        ),
      );
    } on BlogAuthRequiredException {
      final latestState = state is BlogLoaded ? state as BlogLoaded : current;
      final remainingSaving = {...latestState.savingArticleIds}
        ..remove(targetId);

      emit(
        latestState.copyWith(
          savingArticleIds: remainingSaving,
          notice: 'Inicia sesión para guardar artículos',
          noticeIsError: true,
        ),
      );
    } on PostgrestException {
      final latestState = state is BlogLoaded ? state as BlogLoaded : current;
      final remainingSaving = {...latestState.savingArticleIds}
        ..remove(targetId);

      emit(
        latestState.copyWith(
          savingArticleIds: remainingSaving,
          notice: 'Error de permisos o base de datos al guardar.',
          noticeIsError: true,
        ),
      );
    } catch (_) {
      final latestState = state is BlogLoaded ? state as BlogLoaded : current;
      final remainingSaving = {...latestState.savingArticleIds}
        ..remove(targetId);

      emit(
        latestState.copyWith(
          savingArticleIds: remainingSaving,
          notice: 'No se pudo guardar el artículo',
          noticeIsError: true,
        ),
      );
    }
  }

  void _onCategorySelected(
    BlogCategorySelected event,
    Emitter<BlogState> emit,
  ) {
    final current = state;
    if (current is! BlogLoaded) return;

    emit(current.copyWith(selectedCategory: event.category, clearNotice: true));
  }

  void _onSearchChanged(BlogSearchQueryChanged event, Emitter<BlogState> emit) {
    final current = state;
    if (current is! BlogLoaded) return;

    emit(current.copyWith(searchQuery: event.query, clearNotice: true));
  }

  /// Combina los artículos actuales del RSS con favoritos antiguos de Supabase.
  List<ArticleModel> _mergeArticles(
    List<ArticleModel> rssArticles,
    List<ArticleModel> savedArticles,
  ) {
    final rssIds = rssArticles.map((a) => a.id).toSet();
    final olderSaved = savedArticles
        .where((saved) => !rssIds.contains(saved.id))
        .toList(growable: false);

    return [...rssArticles, ...olderSaved];
  }

  List<ArticleModel> _replace(
    List<ArticleModel> articles,
    ArticleModel updated,
  ) {
    return articles
        .map((article) => article.id == updated.id ? updated : article)
        .toList(growable: false);
  }
}
