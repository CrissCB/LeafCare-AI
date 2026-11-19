import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/features/blog/data/models/article_model.dart';
import 'package:leafcare_ia/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/blog_header.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/blog_shimmer.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/compact_card.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/hero_card.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  void _snack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _openArticle(BuildContext context, ArticleModel article) async {
    final uri = Uri.tryParse(article.link);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        _snack(context, 'No se pudo abrir el artículo', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: BlocConsumer<BlogBloc, BlogState>(
        listenWhen: (previous, current) =>
            current is BlogLoaded &&
            current.notice != null &&
            previous != current,
        listener: (context, state) {
          if (state is BlogLoaded && state.notice != null) {
            _snack(context, state.notice!, error: state.noticeIsError);
          }
        },
        builder: (context, state) {
          final isLoaded = state is BlogLoaded;
          final categories = isLoaded
              ? state.categories
              : const ['Todos', 'Guardados'];
          final selectedCategory = isLoaded ? state.selectedCategory : 'Todos';

          return Column(
            children: [
              // Cabecera Verde con Buscador y Categorías gestionadas por el BLoC
              BlogHeader(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategorySelected: (cat) =>
                    context.read<BlogBloc>().add(BlogCategorySelected(cat)),
                onSearchChanged: (query) =>
                    context.read<BlogBloc>().add(BlogSearchQueryChanged(query)),
              ),

              // Contenido Principal
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BlogState state) {
    if (state is BlogLoading || state is BlogInitial) {
      return const BlogShimmer();
    }

    if (state is BlogError) {
      return EmptyStateView(
        icon: Icons.wifi_off_rounded,
        title: 'Sin artículos por ahora',
        subtitle: state.message,
        onRetry: () => context.read<BlogBloc>().add(BlogRefreshed()),
      );
    }

    if (state is BlogLoaded) {
      final articles = state.articles;

      if (articles.isEmpty) {
        return EmptyStateView(
          icon: Icons.eco_outlined,
          title: 'No encontramos artículos',
          subtitle: state.selectedCategory == 'Guardados'
              ? 'Aún no has guardado ningún artículo en tu cuenta.'
              : 'Intenta con otros términos de búsqueda o categorías.',
          onRetry: () => context.read<BlogBloc>().add(BlogRefreshed()),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          final bloc = context.read<BlogBloc>();
          bloc.add(BlogRefreshed());
          await bloc.stream.firstWhere(
            (s) => s is BlogLoaded || s is BlogError,
          );
        },
        child: _BlogArticlesList(
          articles: articles,
          savingArticleIds: state.savingArticleIds,
          onOpenArticle: (article) => _openArticle(context, article),
          onToggleSave: (article) =>
              context.read<BlogBloc>().add(BlogSaveToggled(article)),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// =========================================================================
// LISTA DE ARTÍCULOS (WIDGET DE PRESENTACIÓN PURO)
// =========================================================================

class _BlogArticlesList extends StatelessWidget {
  const _BlogArticlesList({
    required this.articles,
    required this.savingArticleIds,
    required this.onOpenArticle,
    required this.onToggleSave,
  });

  final List<ArticleModel> articles;
  final Set<String> savingArticleIds;
  final ValueChanged<ArticleModel> onOpenArticle;
  final ValueChanged<ArticleModel> onToggleSave;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        final isSaving = savingArticleIds.contains(article.id);

        void handleSave() {
          if (!isSaving) onToggleSave(article);
        }

        void handleOpen() => onOpenArticle(article);

        // Primera tarjeta destacada (Hero)
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ARTÍCULO DEL DÍA',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              HeroCard(
                article: article,
                onOpen: handleOpen,
                onSave: handleSave,
              ),
              if (articles.length > 1) ...[
                const SizedBox(height: 20),
                Text(
                  'MÁS ARTÍCULOS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CompactCard(
            article: article,
            onOpen: handleOpen,
            onSave: handleSave,
          ),
        );
      },
    );
  }
}
