import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/dashboard/data/models/care_reminder_model.dart';
import 'package:leafcare_ia/features/dashboard/data/models/user_plant_model.dart';
import 'package:leafcare_ia/features/plant_detail/data/datasources/plant_detail_datasource.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/plant_scan_model.dart';

/// Detalle de una planta con su historial de análisis.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final PlantDetailDatasource _datasource = PlantDetailDatasource();
  late Future<_PlantDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Pide la planta, su historial y sus recordatorios al mismo tiempo.
  Future<_PlantDetailData> _load() async {
    final results = await Future.wait([
      _datasource.fetchPlant(widget.plantId),
      _datasource.fetchScans(widget.plantId),
      _datasource.fetchReminders(widget.plantId),
    ]);

    return _PlantDetailData(
      plant: results[0] as UserPlantModel,
      scans: results[1] as List<PlantScanModel>,
      reminders: results[2] as List<CareReminderModel>,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  /// Muestra un aviso corto en la parte inferior de la pantalla.
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

  /// Abre un cuadro para cambiar el nombre de la planta.
  Future<void> _editName(UserPlantModel plant) async {
    final controller = TextEditingController(text: plant.customName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Editar nombre',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Nombre de la planta'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName == null || newName.isEmpty || newName == plant.customName) {
      return;
    }

    try {
      await _datasource.updatePlantName(plant.id, newName);
      if (!mounted) return;
      _snack('Nombre actualizado');
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo cambiar el nombre', error: true);
    }
  }

  /// Copia un resumen de la planta para compartirlo.
  Future<void> _sharePlant(
    UserPlantModel plant,
    List<CareReminderModel> reminders,
  ) async {
    final pending = reminders.where((reminder) => !reminder.isCompleted).length;
    final scientific = plant.scientificName.isEmpty
        ? ''
        : '\nNombre científico: ${plant.scientificName}';

    final text =
        '🌱 ${plant.customName}$scientific\n'
        'Estado: ${plant.healthLabel}\n'
        'Cuidados pendientes: $pending\n'
        'Compartido desde LeafCare AI';

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;
    _snack('Resumen copiado. Ya puedes pegarlo donde quieras.');
  }

  /// Pregunta y elimina la planta con todo su historial.
  Future<void> _deletePlant(UserPlantModel plant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Eliminar planta',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Se eliminará "${plant.customName}" junto con sus análisis, '
          'alertas y recordatorios. Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.slate,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _datasource.deletePlant(plant.id);
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo eliminar la planta', error: true);
    }
  }

  /// Abre la hoja inferior para agregar un recordatorio.
  Future<void> _addReminder() async {
    final result = await showModalBottomSheet<_NewReminder>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddReminderSheet(),
    );

    if (result == null) return;

    try {
      await _datasource.addReminder(
        plantId: widget.plantId,
        action: result.action,
        scheduledTime: result.date,
      );
      if (!mounted) return;
      _snack('Recordatorio agregado');
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo agregar el recordatorio', error: true);
    }
  }

  /// Marca un recordatorio como hecho.
  Future<void> _completeReminder(CareReminderModel reminder) async {
    try {
      await _datasource.completeReminder(reminder.id);
      if (!mounted) return;
      _snack('${reminder.action} marcado como hecho');
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo actualizar el recordatorio', error: true);
    }
  }

  /// Elimina un recordatorio.
  Future<void> _deleteReminder(CareReminderModel reminder) async {
    try {
      await _datasource.deleteReminder(reminder.id);
      if (!mounted) return;
      _snack('Recordatorio eliminado');
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo eliminar el recordatorio', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: FutureBuilder<_PlantDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return SafeArea(
              child: Stack(
                children: [
                  EmptyStateView(
                    icon: Icons.eco_outlined,
                    title: 'No se pudo cargar la planta',
                    subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
                    onRetry: _reload,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _PlantImageHeader(
                  plant: data.plant,
                  onEdit: () => _editName(data.plant),
                  onDelete: () => _deletePlant(data.plant),
                  onShare: () => _sharePlant(data.plant, data.reminders),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PlantInfo(plant: data.plant),
                        const SizedBox(height: 24),
                        _RemindersSection(
                          reminders: data.reminders,
                          onAdd: _addReminder,
                          onComplete: _completeReminder,
                          onDelete: _deleteReminder,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Historial de análisis',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.anthracite,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (data.scans.isEmpty)
                          const _EmptyScans()
                        else
                          for (final scan in data.scans) _ScanCard(scan: scan),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Junta la planta, sus análisis y sus recordatorios en un solo objeto.
class _PlantDetailData {
  const _PlantDetailData({
    required this.plant,
    required this.scans,
    required this.reminders,
  });

  final UserPlantModel plant;
  final List<PlantScanModel> scans;
  final List<CareReminderModel> reminders;
}

/// Foto grande de la planta con el botón de regresar y el menú de opciones.
class _PlantImageHeader extends StatelessWidget {
  const _PlantImageHeader({
    required this.plant,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  final UserPlantModel plant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.white),
          tooltip: 'Opciones de la planta',
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'share') onShare();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Editar nombre',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.anthracite,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  const Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Compartir resumen',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.anthracite,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Eliminar planta',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (plant.imageUrl.isNotEmpty)
              Image.network(
                plant.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            else
              _placeholder(),
            // Degradado para que se lea bien el texto encima
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    AppColors.primaryDark.withValues(alpha: 0.55),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Text(
                plant.customName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      // Espacio para que el título no choque con la barra de estado
      title: topPadding > 0 ? null : const SizedBox.shrink(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.mint,
      child: const Center(
        child: Icon(Icons.eco_rounded, size: 64, color: AppColors.primary),
      ),
    );
  }
}

/// Nombre científico, estado y datos generales.
class _PlantInfo extends StatelessWidget {
  const _PlantInfo({required this.plant});

  final UserPlantModel plant;

  @override
  Widget build(BuildContext context) {
    final statusColor = _colorFromHex(plant.healthColorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plant.scientificName.isNotEmpty)
          Text(
            plant.scientificName,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.slate,
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                plant.healthLabel,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (plant.commonName.isNotEmpty)
          _InfoRow(
            icon: Icons.local_florist_outlined,
            label: 'Nombre común',
            value: plant.commonName,
          ),
      ],
    );
  }

  Color _colorFromHex(String hex) {
    var value = hex.replaceAll('#', '').trim();
    if (value.length == 6) value = 'FF$value';

    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? AppColors.slate : Color(parsed);
  }
}

/// Fila con ícono, etiqueta y valor.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.slate,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.anthracite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con un análisis de la IA.
class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.scan});

  final PlantScanModel scan;

  @override
  Widget build(BuildContext context) {
    final score = scan.healthScore.clamp(0, 100).toDouble();
    final scoreColor = score >= 70
        ? AppColors.primary
        : score >= 40
        ? const Color(0xFFD97706)
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Puntaje de salud en un círculo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${score.round()}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.summaryKeyword.isNotEmpty
                          ? scan.summaryKeyword
                          : scan.typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.anthracite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(scan.created)} · ${scan.typeLabel}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.slateLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${scan.confidence.round()}% IA',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (scan.diagnosis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              scan.diagnosis,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.45,
                color: AppColors.slate,
              ),
            ),
          ],
          if (scan.suggestedAction.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scan.suggestedAction,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// Aviso cuando la planta todavía no tiene análisis.
class _EmptyScans extends StatelessWidget {
  const _EmptyScans();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todavía no hay análisis de esta planta. Escanéala para conocer su estado de salud.',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección con los recordatorios de cuidado de la planta.
class _RemindersSection extends StatelessWidget {
  const _RemindersSection({
    required this.reminders,
    required this.onAdd,
    required this.onComplete,
    required this.onDelete,
  });

  final List<CareReminderModel> reminders;
  final VoidCallback onAdd;
  final ValueChanged<CareReminderModel> onComplete;
  final ValueChanged<CareReminderModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final pending = reminders.where((reminder) => !reminder.isCompleted);
    final done = reminders.where((reminder) => reminder.isCompleted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Cuidados',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pending.isEmpty)
          const _EmptyRemindersCard()
        else
          for (final reminder in pending)
            _ReminderCard(
              reminder: reminder,
              onComplete: () => onComplete(reminder),
              onDelete: () => onDelete(reminder),
            ),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Ya hechos',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.slateLight,
            ),
          ),
          const SizedBox(height: 8),
          for (final reminder in done)
            _ReminderCard(
              reminder: reminder,
              onDelete: () => onDelete(reminder),
            ),
        ],
      ],
    );
  }
}

/// Tarjeta de un recordatorio con botón para marcarlo o borrarlo.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onDelete,
    this.onComplete,
  });

  final CareReminderModel reminder;
  final VoidCallback onDelete;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final isDone = reminder.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDone ? AppColors.mint.withValues(alpha: 0.6) : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppColors.inputBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: isDone ? 'Ya está hecho' : 'Marcar como hecho',
            onPressed: isDone ? null : onComplete,
            icon: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? AppColors.primary : AppColors.slateLight,
              size: 22,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.action,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDone ? AppColors.slate : AppColors.anthracite,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatReminderDate(reminder.scheduledTime),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.slateLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar recordatorio',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.slateLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Fecha amigable: "Hoy · 08:00", "Mañana · 09:30" o "12/11/2026 · 10:00".
  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final difference = day.difference(today).inDays;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (difference == 0) return 'Hoy · $time';
    if (difference == 1) return 'Mañana · $time';
    if (difference == -1) return 'Ayer · $time';

    final dayText = date.day.toString().padLeft(2, '0');
    final monthText = date.month.toString().padLeft(2, '0');

    if (difference < 0) {
      return 'Venció el $dayText/$monthText · $time';
    }

    return '$dayText/$monthText/${date.year} · $time';
  }
}

/// Aviso cuando la planta no tiene cuidados pendientes.
class _EmptyRemindersCard extends StatelessWidget {
  const _EmptyRemindersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay cuidados pendientes. Toca "Agregar" para programar un riego, abono o poda.',
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Datos que devuelve la hoja de "Nuevo recordatorio".
class _NewReminder {
  const _NewReminder({required this.action, required this.date});

  final String action;
  final DateTime date;
}

/// Hoja inferior para elegir el cuidado y la fecha.
class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  static const List<String> _actions = [
    'Regar',
    'Abonar',
    'Pulverizar',
    'Podar',
    'Trasplantar',
    'Limpiar hojas',
  ];

  String _selectedAction = _actions.first;
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  /// Abre el calendario para elegir el día.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: '¿Cuándo hay que cuidarla?',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );

    if (picked == null) return;

    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  /// Abre el reloj para elegir la hora.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      helpText: 'Hora del recordatorio',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );

    if (picked == null) return;

    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  String get _dateText {
    final day = _date.day.toString().padLeft(2, '0');
    final month = _date.month.toString().padLeft(2, '0');
    return '$day/$month/${_date.year}';
  }

  String get _timeText {
    final hour = _date.hour.toString().padLeft(2, '0');
    final minute = _date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Nuevo recordatorio',
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elige el cuidado y cuándo quieres que te avisemos.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in _actions)
                ChoiceChip(
                  label: Text(action),
                  selected: _selectedAction == action,
                  onSelected: (_) => setState(() => _selectedAction = action),
                  showCheckmark: false,
                  selectedColor: AppColors.mint,
                  backgroundColor: AppColors.white,
                  side: BorderSide(
                    color: _selectedAction == action
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedAction == action
                        ? AppColors.primaryDark
                        : AppColors.slate,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(_dateText),
                  style: _pickerStyle(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time_rounded, size: 16),
                  label: Text(_timeText),
                  style: _pickerStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(
                _NewReminder(action: _selectedAction, date: _date),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Guardar recordatorio'),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _pickerStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      side: const BorderSide(color: AppColors.inputBorder),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
