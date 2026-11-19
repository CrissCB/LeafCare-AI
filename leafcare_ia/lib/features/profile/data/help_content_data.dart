import 'package:flutter/material.dart';

class FaqEntry {
  const FaqEntry({
    required this.icon,
    required this.question,
    required this.answer,
  });

  final IconData icon;
  final String question;
  final String answer;
}

class CapabilityEntry {
  const CapabilityEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class TechEntry {
  const TechEntry({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class TeamMemberEntry {
  const TeamMemberEntry({
    required this.icon,
    required this.name,
    required this.role,
  });

  final IconData icon;
  final String name;
  final String role;
}

/// Contenido centralizado de la vista Ayuda y LeafCare AI.
abstract final class HelpContentData {
  static const String appName = 'LeafCare AI';
  static const String appVersion = 'Versión 1.0.0';
  static const String appSummary =
      'Tu asistente inteligente para el cuidado integral de tus plantas. '
      'Identifica especies al instante, evalúa su estado fitosanitario con IA y '
      'organiza todos tus recordatorios en un solo lugar.';

  static const String supportEmail = 'soporte@leafcare.ai';
  static const String supportHours =
      'Lunes a viernes · 8:00 a. m. – 6:00 p. m.';
  static const String responseTime = 'Entre 24 y 48 horas hábiles';

  static const String privacyDisclaimer =
      'LeafCare AI es una herramienta de apoyo para el cuidado botánico. '
      'Los diagnósticos generados por inteligencia artificial son orientativos '
      'y no sustituyen el criterio de un agrónomo o especialista. Tus fotografías '
      'y registros se emplean exclusivamente para brindarte seguimiento personalizado.';

  static const List<FaqEntry> faqs = [
    FaqEntry(
      icon: Icons.center_focus_strong_rounded,
      question: '¿Cómo escaneo una planta?',
      answer: 'Toca el botón central de escaneo, toma una foto clara de la hoja o elige una de tu galería. La IA identificará la especie, calculará su porcentaje de salud y generará recomendaciones.',
    ),
    FaqEntry(
      icon: Icons.auto_awesome_outlined,
      question: '¿Qué significan las alertas de IA?',
      answer: 'Son diagnósticos automáticos generados cuando un análisis detecta déficit hídrico, exceso de riego, falta de luz o posibles plagas. Puedes revisar el detalle clínico tocando cada alerta.',
    ),
    FaqEntry(
      icon: Icons.event_note_rounded,
      question: '¿Cómo programo recordatorios de cuidado?',
      answer: 'Desde el detalle de tu planta o en el Centro de Alertas selecciona "Nuevo recordatorio", elige la planta o grupo, el tipo de cuidado (riego, abono, poda) y su frecuencia.',
    ),
    FaqEntry(
      icon: Icons.water_drop_outlined,
      question: '¿Cada cuánto debo regar mis plantas?',
      answer: 'Varía según la especie, iluminación y temperatura. Revisa la ficha de cuidados de cada planta y comprueba la humedad de los primeros centímetros del sustrato antes de regar.',
    ),
    FaqEntry(
      icon: Icons.lock_outline_rounded,
      question: '¿Cómo se protegen mis datos?',
      answer: 'Cada cuenta está aislada mediante políticas de seguridad en Supabase. Solo tú puedes consultar o modificar tus plantas, escaneos y recordatorios.',
    ),
  ];

  static const List<CapabilityEntry> capabilities = [
    CapabilityEntry(
      icon: Icons.center_focus_strong_rounded,
      title: 'Identificación y ficha botánica',
      subtitle: 'Pl@ntNet reconoce la especie por foto y Perenual aporta su guía detallada de cuidados.',
    ),
    CapabilityEntry(
      icon: Icons.auto_awesome_rounded,
      title: 'Alertas preventivas',
      subtitle: 'Detecta señales tempranas de riego inadecuado, plagas o estrés lumínico.',
    ),
    CapabilityEntry(
      icon: Icons.task_alt_rounded,
      title: 'Rutinas y grupos de cuidado',
      subtitle: 'Programa riego, fertilización y poda por planta individual o por ambientes.',
    ),
    CapabilityEntry(
      icon: Icons.bar_chart_rounded,
      title: 'Estadísticas de tu jardín',
      subtitle:
          'Visualiza la evolución de salud y el cumplimiento de tus cuidados.',
    ),
  ];

  static const List<TechEntry> technologies = [
    TechEntry(icon: Icons.flutter_dash_rounded, label: 'Flutter'),
    TechEntry(icon: Icons.storage_rounded, label: 'Supabase'),
    TechEntry(icon: Icons.center_focus_strong_outlined, label: 'Pl@ntNet'),
    TechEntry(icon: Icons.menu_book_outlined, label: 'Perenual'),
    TechEntry(icon: Icons.psychology_outlined, label: 'Visión IA'),
  ];

  static const List<TeamMemberEntry> team = [
    TeamMemberEntry(
      icon: Icons.person_outline_rounded,
      name: 'Karen',
      role: 'Diseño y desarrollo de la aplicación',
    ),
    TeamMemberEntry(
      icon: Icons.code_rounded,
      name: 'Cristian',
      role: 'Arquitectura, backend e integración IA',
    ),
  ];
}
