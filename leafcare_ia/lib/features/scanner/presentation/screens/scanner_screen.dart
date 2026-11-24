import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/scanner/data/datasources/scanner_remote_datasource.dart';
import 'package:leafcare_ia/features/scanner/data/models/scanner_models.dart';
import 'package:leafcare_ia/features/scanner/presentation/bloc/scanner_bloc.dart';
import 'package:leafcare_ia/features/scanner/presentation/widgets/camera_permission_dialog.dart';
import 'package:leafcare_ia/features/scanner/presentation/widgets/scan_result_card.dart';
import 'package:leafcare_ia/features/scanner/presentation/widgets/scan_target_selector.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key, this.args});

  final ScannerRouteArgs? args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScannerBloc(
        datasource: ScannerRemoteDatasource(
          supabaseClient: const AppSupabaseClient(),
        ),
      )..add(ScannerInitialized(args)),
      child: const _ScannerView(),
    );
  }
}

class _ScannerView extends StatefulWidget {
  const _ScannerView();

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final bloc = context.read<ScannerBloc>();
    if (!bloc.state.canCaptureOrPickImage) return;

    // Validar permiso de cámara explícitamente
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (!status.isGranted) {
        await CameraPermissionDialog.show(context);
        return;
      }
    }

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1600,
    );

    if (file != null && mounted) {
      bloc.add(ScannerImageCaptured(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Cabecera verde
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.heroStart,
                      AppColors.heroMid,
                      AppColors.heroEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escáner Botánico IA',
                      style: GoogleFonts.outfit(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Identifica especies y detecta estrés o enfermedades',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de Modalidad A / Modalidad B
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeTabButton(
                              label: 'Nueva Planta',
                              icon: Icons.add_circle_outline_rounded,
                              selected: state.mode == ScanMode.newRegistration,
                              onTap: () => context.read<ScannerBloc>().add(
                                ScannerModeChanged(ScanMode.newRegistration),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _ModeTabButton(
                              label: 'Diagnóstico Salud',
                              icon: Icons.monitor_heart_outlined,
                              selected: state.mode == ScanMode.healthDiagnosis,
                              onTap: () => context.read<ScannerBloc>().add(
                                ScannerModeChanged(ScanMode.healthDiagnosis),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: state.loadingInitial
                    ? const LoadingIndicator()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Submenú de Grupo / Planta
                            ScanTargetSelector(
                              mode: state.mode,
                              groups: state.groups,
                              selectedGroup: state.selectedGroup,
                              onGroupChanged: (g) => context
                                  .read<ScannerBloc>()
                                  .add(ScannerGroupSelected(g)),
                              groupPlants: state.groupPlants,
                              selectedPlant: state.selectedPlant,
                              loadingPlants: state.loadingPlants,
                              onPlantChanged: (p) => context
                                  .read<ScannerBloc>()
                                  .add(ScannerPlantSelected(p)),
                            ),
                            const SizedBox(height: 16),

                            // Banner de error (Umbral < 50% o Sin Conexión)
                            if (state.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: state.isLowConfidenceError
                                      ? const Color(0xFFFEF3C7)
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: state.isLowConfidenceError
                                        ? const Color(0xFFF59E0B)
                                        : AppColors.error.withValues(
                                            alpha: 0.4,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      state.isLowConfidenceError
                                          ? Icons.center_focus_weak_rounded
                                          : Icons.wifi_off_rounded,
                                      color: state.isLowConfidenceError
                                          ? const Color(0xFFB45309)
                                          : AppColors.error,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        state.errorMessage!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: state.isLowConfidenceError
                                              ? const Color(0xFF78350F)
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Estado analizando
                            if (state.analyzing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 40,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Analizando especie y salud con IA...',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.anthracite,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Consultando catálogo botánico y evaluando hojas',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.slate,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // Resultado de IA
                            else if (state.analysisResult != null)
                              ScanResultCard(
                                result: state.analysisResult!,
                                saving: state.saving,
                                onSaveNewPlant: (customName) =>
                                    context.read<ScannerBloc>().add(
                                      ScannerSaveNewPlantRequested(customName),
                                    ),
                                onCancelOrDone: () => context
                                    .read<ScannerBloc>()
                                    .add(ScannerResetResultRequested()),
                              )
                            // Botones de Cámara y Galería
                            else
                              _CaptureActionPanel(
                                enabled: state.canCaptureOrPickImage,
                                helperText: state.selectedGroup == null
                                    ? 'Selecciona un grupo arriba para habilitar la cámara'
                                    : (state.mode == ScanMode.healthDiagnosis &&
                                          state.selectedPlant == null)
                                    ? 'Selecciona la planta del grupo para continuar'
                                    : 'Enfoca bien las hojas principales con buena iluminación',
                                onCameraTap: () =>
                                    _pickImage(context, ImageSource.camera),
                                onGalleryTap: () =>
                                    _pickImage(context, ImageSource.gallery),
                              ),
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

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.primaryDark : AppColors.white,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primaryDark : AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureActionPanel extends StatelessWidget {
  const _CaptureActionPanel({
    required this.enabled,
    required this.helperText,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final bool enabled;
  final String helperText;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: enabled ? AppColors.mint : AppColors.pageBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 34,
              color: enabled ? AppColors.primary : AppColors.slateLight,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Captura o carga una imagen',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: enabled ? onCameraTap : null,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text('Abrir Cámara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.border,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: enabled ? onGalleryTap : null,
              icon: const Icon(Icons.photo_library_outlined, size: 19),
              label: const Text('Cargar desde Galería'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: BorderSide(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
