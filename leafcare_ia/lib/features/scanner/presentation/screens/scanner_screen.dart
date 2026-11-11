import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/features/scanner/data/datasources/plantnet_datasource.dart';
import 'package:leafcare_ia/features/scanner/data/datasources/scanner_datasource.dart';
import 'package:leafcare_ia/features/scanner/data/models/plant_identification_model.dart';

/// Pantalla del escáner: toma una foto y la identifica con Pl@ntNet.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final PlantNetDatasource _plantNet = PlantNetDatasource();
  final ScannerDatasource _saver = ScannerDatasource();
  final TextEditingController _nameController = TextEditingController();

  Uint8List? _imageBytes;
  String _fileName = 'planta.jpg';
  bool _identifying = false;
  bool _saving = false;
  String? _error;
  List<PlantIdentificationModel> _results = [];
  int _selectedIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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

  /// Abre la cámara o la galería y guarda la foto elegida.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _fileName = file.name.isEmpty ? 'planta.jpg' : file.name;
        _results = [];
        _error = null;
        _selectedIndex = 0;
      });
    } catch (_) {
      _snack('No se pudo abrir la cámara o la galería', error: true);
    }
  }

  /// Envía la foto a Pl@ntNet y muestra las especies candidatas.
  Future<void> _identify() async {
    final bytes = _imageBytes;
    if (bytes == null) return;

    setState(() {
      _identifying = true;
      _error = null;
    });

    try {
      final results = await _plantNet.identify(
        imageBytes: bytes,
        fileName: _fileName,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
        _selectedIndex = 0;

        if (results.isNotEmpty) {
          final first = results.first;
          _nameController.text = first.commonName.isNotEmpty
              ? first.commonName
              : first.scientificName;
        } else {
          _error = 'No se reconoció ninguna planta en la foto.';
        }
      });
    } on PlantNetException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'No se pudo conectar con el servicio de identificación.',
      );
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
  }

  /// Guarda la planta elegida en PocketBase.
  Future<void> _save() async {
    if (_results.isEmpty) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Escribe un nombre para tu planta', error: true);
      return;
    }

    setState(() => _saving = true);

    try {
      await _saver.savePlant(
        customName: name,
        identification: _results[_selectedIndex],
      );

      if (!mounted) return;
      _snack('Planta guardada. Ya aparece en Inicio.');

      setState(() {
        _imageBytes = null;
        _results = [];
        _error = null;
        _nameController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo guardar la planta', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            sliver: SliverToBoxAdapter(child: _content()),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 18,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.neon,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Escanear planta',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Toma una foto de la hoja y la inteligencia artificial te dirá qué planta es.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    // 1) Todavía no hay foto
    if (_imageBytes == null) {
      return _PickerCard(
        onCamera: () => _pickImage(ImageSource.camera),
        onGallery: () => _pickImage(ImageSource.gallery),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2) Vista previa de la foto
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            _imageBytes!,
            height: 230,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),

        // Botones para cambiar la foto
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _identifying || _saving
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Cambiar foto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.inputBorder),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _identifying || _saving ? null : _identify,
                icon: _identifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(_identifying ? 'Analizando...' : 'Identificar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),

        // 3) Mensaje de error
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 4) Resultados de la IA
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            '¿Cuál es tu planta?',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca la opción correcta. La IA puede equivocarse.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < _results.length; index++)
            _ResultCard(
              identification: _results[index],
              selected: index == _selectedIndex,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                  final item = _results[index];
                  _nameController.text = item.commonName.isNotEmpty
                      ? item.commonName
                      : item.scientificName;
                });
              },
            ),
          const SizedBox(height: 16),
          Text(
            'Nombre para tu planta',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Por ejemplo: Monstera de la sala',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_saving ? 'Guardando...' : 'Guardar planta'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta inicial con los botones de cámara y galería.
class _PickerCard extends StatelessWidget {
  const _PickerCard({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.center_focus_strong_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enfoca una hoja',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.anthracite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Procura buena luz y que la hoja ocupe la mayor parte de la foto.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text('Tomar foto'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Elegir de la galería'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.inputBorder),
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

/// Tarjeta con una especie candidata.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.identification,
    required this.selected,
    required this.onTap,
  });

  final PlantIdentificationModel identification;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: identification.imageUrl.isNotEmpty
                  ? Image.network(
                      identification.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.eco_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    identification.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.anthracite,
                    ),
                  ),
                  if (identification.commonName.isNotEmpty)
                    Text(
                      identification.commonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.slate,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${identification.scorePercent}% de coincidencia'
                    '${identification.family.isNotEmpty ? ' · ${identification.family}' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.slateLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.slateLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
