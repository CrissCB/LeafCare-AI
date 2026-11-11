import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/plant_detail/data/models/health_scan_model.dart';

class PlantHealthTimeline extends StatefulWidget {
  const PlantHealthTimeline({
    super.key,
    required this.scans,
    required this.fallbackImageUrl,
  });

  final List<HealthScanModel> scans;
  final String fallbackImageUrl;

  @override
  State<PlantHealthTimeline> createState() => _PlantHealthTimelineState();
}

class _PlantHealthTimelineState extends State<PlantHealthTimeline> {
  int _expandedIndex = 0;

  Color _scoreColor(double score) {
    if (score >= 75) return const Color(0xFF16A34A);
    if (score >= 50) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color _scoreBgColor(double score) {
    if (score >= 75) return const Color(0xFFDCFCE7);
    if (score >= 50) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  String _formatDate(DateTime date) {
    const m = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${m[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scans.isEmpty) {
      return const SizedBox.shrink();
    }

    final latestScore = widget.scans.first.healthScore.toInt();
    final chartScores = widget.scans.reversed
        .map((s) => s.healthScore)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.insert_chart_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '3. Historial y Cronología de Salud',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Gráfica de Tendencia
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tendencia de salud',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.anthracite,
                    ),
                  ),
                  Text(
                    '$latestScore%',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(latestScore.toDouble()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HealthTrendPainter(scores: chartScores),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cronología Vertical
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.scans.length,
          itemBuilder: (context, index) {
            final scan = widget.scans[index];
            final isFirst = index == 0;
            final isLast = index == widget.scans.length - 1;
            final isExpanded = _expandedIndex == index;
            final color = _scoreColor(scan.healthScore);
            final bgColor = _scoreBgColor(scan.healthScore);
            final img = scan.scannedImageUrl.isNotEmpty
                ? scan.scannedImageUrl
                : widget.fallbackImageUrl;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nodo y Línea conectora
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: isFirst ? 18 : 14,
                          height: isFirst ? 18 : 14,
                          margin: const EdgeInsets.only(top: 18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst ? AppColors.neon : AppColors.white,
                            border: Border.all(
                              color: isFirst
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isFirst ? 3 : 2,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tarjeta Expandible
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _expandedIndex = isExpanded ? -1 : index,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isExpanded
                                ? AppColors.primary
                                : AppColors.border,
                            width: isExpanded ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: img.isNotEmpty
                                        ? Image.network(img, fit: BoxFit.cover)
                                        : Container(
                                            color: AppColors.mint,
                                            child: const Icon(
                                              Icons.eco,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Título e Información
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _formatDate(scan.createdAt),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppColors.slateLight,
                                            ),
                                          ),
                                          if (isFirst) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.mint,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'RECIENTE',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        scan.healthDiagnosisText.isNotEmpty
                                            ? scan.healthDiagnosisText
                                            : scan.summaryKeyword,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.anthracite,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          scan.summaryKeyword,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Porcentaje
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${scan.healthScore.toInt()}%',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: AppColors.slateLight,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Contenido Expandido: Sugerencia
                            if (isExpanded &&
                                scan.suggestedActionText.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.pageBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        scan.suggestedActionText,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.anthracite,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HealthTrendPainter extends CustomPainter {
  _HealthTrendPainter({required this.scores});
  final List<double> scores;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    final stepX = scores.length > 1
        ? size.width / (scores.length - 1)
        : size.width / 2;

    for (int i = 0; i < scores.length; i++) {
      final normalizedY = 1.0 - (scores[i].clamp(0.0, 100.0) / 100.0);
      final y = 8 + normalizedY * (size.height - 16);
      final x = scores.length > 1 ? i * stepX : size.width / 2;
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }

    for (int i = 0; i < points.length; i++) {
      final score = scores[i];
      final dotColor = score >= 75
          ? const Color(0xFF16A34A)
          : (score >= 50 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

      canvas.drawCircle(points[i], 4.5, Paint()..color = AppColors.white);
      canvas.drawCircle(
        points[i],
        4.5,
        Paint()
          ..color = dotColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HealthTrendPainter oldDelegate) =>
      oldDelegate.scores != scores;
}
