import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/leaf_logo.dart';
import 'package:leafcare_ia/features/profile/data/help_content_data.dart';

/// Contenido de la pestaña "Soporte y guía".
class HelpSupportSection extends StatelessWidget {
  const HelpSupportSection({super.key, required this.onCopyEmail});

  final VoidCallback onCopyEmail;

  @override
  Widget build(BuildContext context) {
    const faqs = HelpContentData.faqs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('MANUAL Y PREGUNTAS FRECUENTES'),
        // `Material` evita el error de ink splash invisible en ExpansionTile/ListTile
        Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < faqs.length; i++) ...[
                _FaqItem(entry: faqs[i]),
                if (i < faqs.length - 1)
                  const Divider(height: 1, indent: 62, color: AppColors.border),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        const _SectionLabel('CONTACTO Y ATENCIÓN'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const _ContactInfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Correo de soporte',
                value: HelpContentData.supportEmail,
              ),
              const Divider(height: 22, color: AppColors.border),
              const _ContactInfoRow(
                icon: Icons.schedule_rounded,
                label: 'Horario de trabajo',
                value: HelpContentData.supportHours,
              ),
              const Divider(height: 22, color: AppColors.border),
              const _ContactInfoRow(
                icon: Icons.forum_outlined,
                label: 'Tiempo estimado de respuesta',
                value: HelpContentData.responseTime,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCopyEmail,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar correo de la empresa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    backgroundColor: AppColors.mint.withValues(alpha: 0.45),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const _SectionLabel('TÉRMINOS Y PRIVACIDAD'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  HelpContentData.privacyDisclaimer,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Contenido de la pestaña "Acerca de la app".
class HelpAboutSection extends StatelessWidget {
  const HelpAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    const capabilities = HelpContentData.capabilities;
    const team = HelpContentData.team;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.heroStart, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const LeafLogo(size: 44),
              ),
              const SizedBox(height: 14),
              Text(
                HelpContentData.appName,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.anthracite,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  HelpContentData.appVersion,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                HelpContentData.appSummary,
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

        const _SectionLabel('LO QUE PUEDES HACER'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < capabilities.length; i++) ...[
                _IconTextRow(
                  icon: capabilities[i].icon,
                  title: capabilities[i].title,
                  subtitle: capabilities[i].subtitle,
                ),
                if (i < capabilities.length - 1)
                  const Divider(height: 1, indent: 66, color: AppColors.border),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),

        const _SectionLabel('TECNOLOGÍAS QUE USAMOS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tech in HelpContentData.technologies)
              _TechBadge(icon: tech.icon, label: tech.label),
          ],
        ),
        const SizedBox(height: 22),

        const _SectionLabel('EQUIPO DE DESARROLLO'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < team.length; i++) ...[
                _IconTextRow(
                  icon: team[i].icon,
                  title: team[i].name,
                  subtitle: team[i].role,
                ),
                if (i < team.length - 1)
                  const Divider(height: 1, indent: 66, color: AppColors.border),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Column(
            children: [
              Text(
                'Hecho con cariño para tus plantas 🌱',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.slateLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '© 2026 LeafCare AI',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.slateLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.entry});

  final FaqEntry entry;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: AppColors.mint,
        highlightColor: AppColors.mint,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.slateLight,
        leading: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(entry.icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          entry.question,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.anthracite,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              entry.answer,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  const _ContactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.slateLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.anthracite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconTextRow extends StatelessWidget {
  const _IconTextRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
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

class _TechBadge extends StatelessWidget {
  const _TechBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.anthracite,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: AppColors.slate,
        ),
      ),
    );
  }
}
