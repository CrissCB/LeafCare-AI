import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
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

  /// Pide la planta y su historial al mismo tiempo.
  Future<_PlantDetailData> _load() async {
    final results = await Future.wait([
      _datasource.fetchPlant(widget.plantId),
      _datasource.fetchScans(widget.plantId),
    ]);

    return _PlantDetailData(
      plant: results[0] as UserPlantModel,
      scans: results[1] as List<PlantScanModel>,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
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

          return CustomScrollView(
            slivers: [
              _PlantImageHeader(plant: data.plant),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PlantInfo(plant: data.plant),
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
                        for (final scan in data.scans)
                          _ScanCard(scan: scan),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Junta la planta y sus análisis en un solo objeto.
class _PlantDetailData {
  const _PlantDetailData({required this.plant, required this.scans});

  final UserPlantModel plant;
  final List<PlantScanModel> scans;
}

/// Foto grande de la planta con el botón de regresar.
class _PlantImageHeader extends StatelessWidget {
  const _PlantImageHeader({required this.plant});

  final UserPlantModel plant;

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
