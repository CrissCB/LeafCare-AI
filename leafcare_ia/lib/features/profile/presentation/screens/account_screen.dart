import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/network/supabase_client.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/features/profile/data/datasources/profile_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/user_profile_model.dart';
import 'package:leafcare_ia/features/profile/presentation/widgets/account_widgets.dart';

/// Subpantalla de identidad del usuario (`/account`).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ProfileDatasource _datasource = ProfileDatasource(
    supabaseClient: const AppSupabaseClient(),
  );
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late Future<UserProfileModel> _profileFuture;
  bool _initializedForm = false;

  Uint8List? _selectedAvatarBytes;
  String _selectedAvatarExt = 'jpg';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _datasource.fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _initializedForm = false;
      _selectedAvatarBytes = null;
      _profileFuture = _datasource.fetchProfile();
    });
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  Future<void> _showAvatarSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cambiar foto de perfil',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.anthracite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'JPG, PNG o WEBP · Tamaño máximo 15 MB',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.slateLight,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Tomar una foto'),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _pickAndValidateImage(source);
  }

  Future<void> _pickAndValidateImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 88);
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      // Validación estricta de límite máximo de 15 MB
      if (bytes.lengthInBytes > ProfileDatasource.maxAvatarBytes) {
        final sizeMb = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
        _snack(
          'La imagen pesa $sizeMb MB y supera el límite de 15 MB.',
          isError: true,
        );
        return;
      }

      final parts = picked.name.split('.');
      final ext = parts.length > 1 ? parts.last.toLowerCase() : 'jpg';

      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarExt = ext;
      });
    } catch (_) {
      if (mounted) {
        _snack('No se pudo cargar la imagen seleccionada.', isError: true);
      }
    }
  }

  Future<void> _saveChanges(UserProfileModel profile) async {
    if (profile.isGoogleAccount || _isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newName = _nameController.text.trim();
    final hasNameChange = newName != profile.name;
    final hasAvatarChange = _selectedAvatarBytes != null;

    if (!hasNameChange && !hasAvatarChange) {
      _snack('No hay cambios pendientes por guardar.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _datasource.updateProfileDetails(
        name: newName,
        avatarBytes: _selectedAvatarBytes,
        fileExtension: _selectedAvatarExt,
      );

      if (!mounted) return;
      _snack('Datos de cuenta actualizados');
      _reload();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _snack(msg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: FutureBuilder<UserProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return EmptyStateView(
              icon: Icons.person_off_rounded,
              title: 'No se pudo cargar tu cuenta',
              subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
              onRetry: _reload,
            );
          }

          final profile = snapshot.data!;
          if (!_initializedForm) {
            _nameController.text = profile.name;
            _initializedForm = true;
          }

          final isGoogle = profile.isGoogleAccount;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccountHeroHeader(
                  profile: profile,
                  previewAvatarBytes: _selectedAvatarBytes,
                  onPickAvatar: isGoogle ? null : _showAvatarSourceSheet,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isGoogle) ...[
                          const GoogleManagedAccountBanner(),
                          const SizedBox(height: 18),
                        ],

                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'DATOS DE IDENTIDAD',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.slate,
                            ),
                          ),
                        ),

                        // Tarjeta blanca de información
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nombre completo',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.anthracite,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                enabled: !isGoogle && !_isSaving,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: isGoogle
                                      ? const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 18,
                                          color: AppColors.slateLight,
                                        )
                                      : null,
                                  hintText: 'Tu nombre',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tu nombre';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              Text(
                                'Correo electrónico',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.anthracite,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: profile.email,
                                enabled: false,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                    color: AppColors.slateLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Botón Guardar cambios (solo visible para cuentas con correo)
                        if (!isGoogle) ...[
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveChanges(profile),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : Text(
                                      'Guardar cambios',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
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
