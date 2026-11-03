import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/blog/data/models/article_model.dart';
import 'package:leafcare_ia/features/blog/presentation/bloc/blog_bloc.dart';

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
      body: Column(
        children: [
          const _BlogHeader(),
          Expanded(
            child: BlocConsumer<BlogBloc, BlogState>(
              listenWhen: (_, current) =>
                  current is BlogLoaded && current.notice != null,
              listener: (context, state) {
                if (state is BlogLoaded && state.notice != null) {
                  _snack(context, state.notice!, error: state.noticeIsError);
                }
              },
              builder: (context, state) {
                if (state is BlogLoading || state is BlogInitial) {
                  return const _ShimmerList();
                }

                if (state is BlogError) {
                  return _EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Sin artículos por ahora',
                    subtitle: state.message,
                    onRetry: () =>
                        context.read<BlogBloc>().add(BlogRefreshed()),
                  );
                }

                final articles = (state as BlogLoaded).articles;
                if (articles.isEmpty) {
                  return _EmptyState(
                    icon: Icons.eco_outlined,
                    title: 'Todavía no hay artículos',
                    subtitle:
                        'Vuelve más tarde para ver novedades de jardinería.',
                    onRetry: () =>
                        context.read<BlogBloc>().add(BlogRefreshed()),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<BlogBloc>().add(BlogRefreshed());
                    await context
                        .read<BlogBloc>()
                        .stream
                        .firstWhere(
                          (s) => s is BlogLoaded || s is BlogError,
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      void onSave() => context
                          .read<BlogBloc>()
                          .add(BlogSaveToggled(article));
                      void onOpen() => _openArticle(context, article);

                      // Primera tarjeta destacada (hero)
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _HeroCard(
                            article: article,
                            onOpen: onOpen,
                            onSave: onSave,
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CompactCard(
                          article: article,
                          onOpen: onOpen,
                          onSave: onSave,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────

class _BlogHeader extends StatelessWidget {
  const _BlogHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conocimiento Verde',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Artículos y guías de expertos',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  // Badge LIVE RSS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neon.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.neon.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.neon,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE RSS',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neon,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero card (primer artículo)
// ─────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.article,
    required this.onOpen,
    required this.onSave,
  });

  final ArticleModel article;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen / fallback (altura fija 200)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  article.imageUrl.isNotEmpty
                      ? Image.network(
                          article.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _CategoryFallback(category: article.category),
                        )
                      : _CategoryFallback(category: article.category),
                  // Gradiente oscuro en la parte inferior
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC0A3320)],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  // Badge "Artículo del día"
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neon,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Artículo del día',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // Botón guardar
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _SaveButton(
                      saved: article.saved,
                      onTap: onSave,
                      large: true,
                    ),
                  ),
                  // Título sobre la imagen
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info inferior
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.description.isNotEmpty) ...[
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.slate,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      _CategoryChip(label: article.category),
                      const SizedBox(width: 8),
                      Text(
                        '· ${article.readTime} de lectura',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.slateLight,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Leer',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: AppColors.neon,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Compact card (resto de artículos)
// ─────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  const _CompactCard({
    required this.article,
    required this.onOpen,
    required this.onSave,
  });

  final ArticleModel article;
  final VoidCallback onOpen;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Thumbnail cuadrado 90x90
            SizedBox(
              width: 90,
              height: 90,
              child: article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _CategoryFallback(category: article.category),
                    )
                  : _CategoryFallback(category: article.category),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            article.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.anthracite,
                              height: 1.3,
                            ),
                          ),
                        ),
                        _SaveButton(saved: article.saved, onTap: onSave),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _CategoryChip(label: article.category, small: true),
                        const SizedBox(width: 6),
                        Text(
                          article.readTime,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.slateLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.author,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.slateLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Fallback de imagen por categoría
// ─────────────────────────────────────────────

class _CategoryFallback extends StatelessWidget {
  const _CategoryFallback({required this.category});

  final String category;

  static IconData _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('riego') || c.contains('agua')) {
      return Icons.water_drop_outlined;
    } else if (c.contains('plaga') || c.contains('enfermed')) {
      return Icons.bug_report_outlined;
    } else if (c.contains('luz') || c.contains('iluminac')) {
      return Icons.wb_sunny_outlined;
    } else if (c.contains('fertili') || c.contains('abono')) {
      return Icons.science_outlined;
    } else if (c.contains('trasplant') || c.contains('maceta')) {
      return Icons.yard_outlined;
    } else if (c.contains('poda')) {
      return Icons.content_cut_rounded;
    } else {
      return Icons.eco_rounded;
    }
  }

  static List<Color> _gradientFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('riego') || c.contains('agua')) {
      return [const Color(0xFF0369A1), const Color(0xFF0EA5E9)];
    } else if (c.contains('plaga') || c.contains('enfermed')) {
      return [const Color(0xFF991B1B), const Color(0xFFDC2626)];
    } else if (c.contains('luz') || c.contains('iluminac')) {
      return [const Color(0xFFB45309), const Color(0xFFF59E0B)];
    } else if (c.contains('fertili') || c.contains('abono')) {
      return [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)];
    } else if (c.contains('trasplant') || c.contains('maceta')) {
      return [const Color(0xFF92400E), const Color(0xFFD97706)];
    } else {
      return [AppColors.heroStart, AppColors.heroMid];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(category);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(category),
              color: Colors.white.withValues(alpha: 0.85),
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              category,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Chip de categoría
// ─────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, this.small = false});

  final String label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Botón guardar
// ─────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saved,
    required this.onTap,
    this.large = false,
  });

  final bool saved;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (large) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? AppColors.neon : Colors.white,
            size: 20,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 0),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: saved ? AppColors.primary : AppColors.slateLight,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer de carga
// ─────────────────────────────────────────────

class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, animation) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _shimmerBox(height: 200, radius: 20),
            const SizedBox(height: 14),
            ...[90.0, 90.0, 90.0, 90.0].map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _shimmerBox(height: h, radius: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shimmerBox({required double height, required double radius}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_anim.value, 0),
          end: Alignment(_anim.value + 1.5, 0),
          colors: const [
            Color(0xFFE8F5E9),
            Color(0xFFD1FAE5),
            Color(0xFFE8F5E9),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Estado vacío / error
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
