import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';

class CameraPermissionDialog extends StatelessWidget {
  const CameraPermissionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const CameraPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.no_photography_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Permiso de cámara requerido',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.anthracite,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Para tomar fotografías de tus plantas y analizarlas con IA necesitamos acceso a la cámara. Puedes habilitarlo desde la configuración del dispositivo.',
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.45,
          color: AppColors.slate,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await openAppSettings();
          },
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Configuración del Dispositivo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
