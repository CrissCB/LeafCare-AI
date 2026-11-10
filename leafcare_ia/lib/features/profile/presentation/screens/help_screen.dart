import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';

/// Pantalla de ayuda con preguntas frecuentes y datos de contacto.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SubPageHeader(
              title: 'Ayuda y soporte',
              subtitle: 'Resolvemos tus dudas sobre el cuidado de tus plantas.',
              icon: Icons.help_outline_rounded,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- PREGUNTAS FRECUENTES ----------
                  _SectionTitle('Preguntas frecuentes'),
                  const SizedBox(height: 10),
                  const _FaqTile(
                    icon: Icons.center_focus_strong_rounded,
                    question: '¿Cómo escaneo una planta?',
                    answer:
                        'Abre la pestaña "Escanear", toma una foto o elige una '
                        'de tu galería. La inteligencia artificial identificará '
                        'la especie y te dará recomendaciones de cuidado.',
                  ),
                  const _FaqTile(
                    icon: Icons.water_drop_outlined,
                    question: '¿Cada cuánto debo regar mi planta?',
                    answer:
                        'Depende de la especie, la luz y la época del año. Revisa '
                        'la sección "Cuidados" del detalle de tu planta y toca la '
                        'tierra antes de regar: si todavía está húmeda, espera.',
                  ),
                  const _FaqTile(
                    icon: Icons.notifications_active_outlined,
                    question: '¿Qué significan las alertas?',
                    answer:
                        'Son avisos que genera la inteligencia artificial cuando '
                        'detecta algo que puede afectar la salud de una planta, '
                        'como falta de luz, exceso de riego o una posible plaga.',
                  ),
                  const _FaqTile(
                    icon: Icons.event_note_rounded,
                    question: '¿Cómo agrego un recordatorio?',
                    answer:
                        'Entra al detalle de una planta, busca la sección '
                        '"Cuidados" y toca "Agregar". Elige el tipo de cuidado y '
                        'la fecha y hora en que quieres que te avisemos.',
                  ),
                  const _FaqTile(
                    icon: Icons.delete_outline_rounded,
                    question: '¿Puedo eliminar una planta?',
                    answer:
                        'Sí. En el detalle de la planta toca el menú de tres '
                        'puntos (⋮) y elige "Eliminar planta". También se borrarán '
                        'sus análisis, alertas y recordatorios.',
                  ),
                  const _FaqTile(
                    icon: Icons.lock_outline_rounded,
                    question: '¿Mis datos están seguros?',
                    answer:
                        'Cada usuario solo puede ver y editar sus propias plantas, '
                        'alertas y recordatorios. Tu contraseña se guarda cifrada y '
                        'puedes activar la verificación en dos pasos desde Seguridad.',
                  ),
                  const SizedBox(height: 22),

                  // ---------- CONTACTO ----------
                  _SectionTitle('Contacto'),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ContactRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Correo de soporte',
                          value: 'soporte@leafcare.ai',
                        ),
                        const Divider(height: 20),
                        const _ContactRow(
                          icon: Icons.schedule_rounded,
                          label: 'Horario de atención',
                          value: 'Lunes a viernes · 8:00 a 18:00',
                        ),
                        const Divider(height: 20),
                        const _ContactRow(
                          icon: Icons.forum_outlined,
                          label: 'Tiempo de respuesta',
                          value: 'Entre 24 y 48 horas',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _copyEmail(context),
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 18,
                            ),
                            label: const Text('Copiar correo de soporte'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ---------- TÉRMINOS ----------
                  _SectionTitle('Términos y privacidad'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'LeafCare AI es una aplicación educativa para el cuidado de '
                      'plantas. Las recomendaciones de la inteligencia artificial '
                      'son orientativas y no reemplazan la asesoría de un experto. '
                      'Usamos tus datos únicamente para mostrarte tus plantas, '
                      'recordatorios y alertas.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '¿No encontraste lo que buscabas? Escríbenos 💚',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.slateLight,
                      ),
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

  /// Copia el correo de soporte al portapapeles.
  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: 'soporte@leafcare.ai'),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Correo copiado al portapapeles'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

/// Pregunta frecuente que se abre y se cierra al tocarla.
class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.icon,
    required this.question,
    required this.answer,
  });

  final IconData icon;
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppColors.mint,
          highlightColor: AppColors.mint,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
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
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          title: Text(
            question,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.anthracite,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.slate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila con un dato de contacto.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
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
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.mint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.slateLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
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
