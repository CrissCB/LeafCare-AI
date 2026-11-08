import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';

/// Pantalla "Acerca de LeafCare AI" con la información del proyecto.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SubPageHeader(
              title: 'Acerca de LeafCare AI',
              subtitle: 'Conoce la aplicación y lo que hay detrás.',
              icon: Icons.info_outline_rounded,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- PRESENTACIÓN ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const LeafLogo(size: 46),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'LeafCare AI',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.anthracite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versión 1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.slateLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Tu asistente inteligente para cuidar las plantas. '
                          'Identifica especies, revisa su salud y recibe '
                          'recordatorios de cuidado, todo en un solo lugar.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ---------- QUÉ PUEDES HACER ----------
                  _SectionTitle('Qué puedes hacer'),
                  const SizedBox(height: 10),
                  const _FeatureTile(
                    icon: Icons.center_focus_strong_rounded,
                    title: 'Escanear plantas',
                    subtitle:
                        'Toma una foto y la inteligencia artificial reconoce la especie.',
                  ),
                  const _FeatureTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Alertas inteligentes',
                    subtitle:
                        'Recibe avisos cuando una planta necesite atención.',
                  ),
                  const _FeatureTile(
                    icon: Icons.task_alt_rounded,
                    title: 'Recordatorios de cuidado',
                    subtitle:
                        'Organiza el riego, el abono y la poda de cada planta.',
                  ),
                  const _FeatureTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Blog de jardinería',
                    subtitle:
                        'Aprende con artículos y consejos para tus plantas.',
                  ),
                  const SizedBox(height: 22),

                  // ---------- TECNOLOGÍA ----------
                  _SectionTitle('Tecnología'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _TechChip('Flutter'),
                      _TechChip('PocketBase'),
                      _TechChip('Pl@ntNet'),
                      _TechChip('Cloudflare R2'),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ---------- EQUIPO ----------
                  _SectionTitle('Equipo'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Karen · Desarrollo de la aplicación',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.anthracite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.code_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cristian · Desarrollo de la aplicación',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.anthracite,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---------- PIE ----------
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Hecho con cariño para tus plantas 🌱',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.slateLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2026 LeafCare AI',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.slateLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.anthracite,
      ),
    );
  }
}

/// Fila con un ícono y una función de la aplicación.
class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.35,
                    color: AppColors.slateLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de una tecnología usada.
class _TechChip extends StatelessWidget {
  const _TechChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
