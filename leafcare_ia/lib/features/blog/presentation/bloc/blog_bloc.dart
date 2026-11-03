import 'package:flutter_bloc/flutter_bloc.dart';

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

// --- ESTADOS ---
abstract class BlogState {}

class BlogInitial extends BlogState {}

class BlogLoading extends BlogState {}

class BlogLoaded extends BlogState {
  BlogLoaded(this.articles, {this.notice, this.noticeIsError = false});

  final List<ArticleModel> articles;
  final String? notice;
  final bool noticeIsError;
}

class BlogError extends BlogState {
  BlogError(this.message);
  final String message;
}

// --- BLOC ---
class BlogBloc extends Bloc<BlogEvent, BlogState> {
  BlogBloc({required this.repository}) : super(BlogInitial()) {
    on<BlogStarted>(_onLoad);
    on<BlogRefreshed>(_onLoad);
    on<BlogSaveToggled>(_onSaveToggled);
  }

  final BlogRepository repository;

  Future<void> _onLoad(BlogEvent event, Emitter<BlogState> emit) async {
    emit(BlogLoading());
    try {
      final articles = await repository.fetchArticles();
      emit(BlogLoaded(articles));
    } catch (_) {
      emit(BlogError('No se pudieron cargar los artículos. Inténtalo de nuevo.'));
    }
  }

  Future<void> _onSaveToggled(
    BlogSaveToggled event,
    Emitter<BlogState> emit,
  ) async {
    final current = state;
    if (current is! BlogLoaded) return;

    try {
      final updated = await repository.toggleSave(event.article);
      emit(
        BlogLoaded(
          _replace(current.articles, updated),
          notice: updated.saved
              ? 'Artículo guardado'
              : 'Artículo quitado de guardados',
        ),
      );
    } on BlogAuthRequiredException {
      emit(
        BlogLoaded(
          current.articles,
          notice: 'Inicia sesión para guardar artículos',
          noticeIsError: true,
        ),
      );
    } catch (_) {
      emit(
        BlogLoaded(
          current.articles,
          notice: 'No se pudo guardar el artículo',
          noticeIsError: true,
        ),
      );
    }
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
