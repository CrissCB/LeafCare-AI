import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/features/blog/data/models/article_model.dart';
import 'package:leafcare_ia/features/blog/presentation/bloc/blog_bloc.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/blog_header.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/compact_card.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/hero_card.dart';
import 'package:leafcare_ia/features/blog/presentation/widgets/blog_shimmer.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  void _snack(String message, {bool error = false}) {
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

  Future<void> _openArticle(ArticleModel article) async {
    final uri = Uri.tryParse(article.link);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _snack('No se pudo abrir el artículo', error: true);
    }
  }

  List<ArticleModel> _filterArticles(List<ArticleModel> articles) {
    return articles.where((article) {
      final matchesSearch =
          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      bool matchesCategory = true;
      if (_selectedCategory == 'Guardados') {
        matchesCategory = article.saved;
      } else if (_selectedCategory != 'Todos') {
        matchesCategory =
            article.category.trim().toLowerCase() ==
            _selectedCategory.trim().toLowerCase();
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: BlocConsumer<BlogBloc, BlogState>(
        listenWhen: (_, current) =>
            current is BlogLoaded && current.notice != null,
        listener: (context, state) {
          if (state is BlogLoaded && state.notice != null) {
            _snack(state.notice!, error: state.noticeIsError);
          }
        },
        builder: (context, state) {
          List<String> categories = const ['Todos', 'Guardados'];
          List<ArticleModel> articles = const [];

          // Extraer categorías dinámicamente cuando el BLoC entrega los artículos
          if (state is BlogLoaded) {
            final rawArticles = state.articles;

            final rssCategories = rawArticles
                .map((a) => a.category.trim())
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();

            categories = ['Todos', ...rssCategories, 'Guardados'];
            articles = _filterArticles(rawArticles);

            // Respaldo por si se actualizan los datos y la categoría seleccionada ya no existe
            if (!categories.contains(_selectedCategory)) {
              _selectedCategory = 'Todos';
            }
          }

          return Column(
            children: [
              // Cabecera Verde con Buscador y Categorías Dinámicas
              BlogHeader(
                categories: categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (cat) =>
                    setState(() => _selectedCategory = cat),
                onSearchChanged: (query) =>
                    setState(() => _searchQuery = query),
              ),

              // Contenido Principal
              Expanded(child: _buildBody(context, state, articles)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BlogState state,
    List<ArticleModel> articles,
  ) {
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

    if (articles.isEmpty) {
      return EmptyStateView(
        icon: Icons.eco_outlined,
        title: 'No encontramos artículos',
        subtitle: _selectedCategory == 'Guardados'
            ? 'Aún no has guardado ningún artículo en tu cuenta.'
            : 'Intenta con otros términos de búsqueda o categorías.',
        onRetry: () => context.read<BlogBloc>().add(BlogRefreshed()),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<BlogBloc>().add(BlogRefreshed());
        await context.read<BlogBloc>().stream.firstWhere(
          (s) => s is BlogLoaded || s is BlogError,
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          void onSave() =>
              context.read<BlogBloc>().add(BlogSaveToggled(article));
          void onOpen() => _openArticle(article);

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
                HeroCard(article: article, onOpen: onOpen, onSave: onSave),
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
              onOpen: onOpen,
              onSave: onSave,
            ),
          );
        },
      ),
    );
  }
}
