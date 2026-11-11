import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:leafcare_ia/app/config/app_theme.dart';
import 'package:leafcare_ia/core/widgets/empty_state_view.dart';
import 'package:leafcare_ia/core/widgets/loading_indicator.dart';
import 'package:leafcare_ia/core/widgets/sub_page_header.dart';
import 'package:leafcare_ia/features/profile/data/datasources/account_datasource.dart';
import 'package:leafcare_ia/features/profile/data/models/account_model.dart';

/// Pantalla "Mi cuenta": permite cambiar el nombre y la contraseña.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AccountDatasource _datasource = AccountDatasource();
  final TextEditingController _nameController = TextEditingController();

  late Future<AccountModel> _accountFuture;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _accountFuture = _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Pide los datos al servidor y llena el campo del nombre.
  Future<AccountModel> _load() async {
    final account = await _datasource.fetchAccount();
    _nameController.text = account.name;
    return account;
  }

  void _reload() {
    setState(() {
      _accountFuture = _load();
    });
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

  /// Guarda el nombre nuevo en PocketBase.
  Future<void> _saveName() async {
    final name = _nameController.text.trim();

    if (name.length < 2) {
      _snack('Escribe un nombre de al menos 2 letras', error: true);
      return;
    }

    setState(() => _savingName = true);

    try {
      await _datasource.updateName(name);
      if (!mounted) return;
      _snack('Nombre actualizado correctamente');
      _reload();
    } catch (_) {
      if (!mounted) return;
      _snack('No se pudo guardar el nombre', error: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  /// Abre la ventana para cambiar la contraseña.
  Future<void> _openPasswordDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(datasource: _datasource),
    );

    if (saved == true && mounted) {
      _snack('Contraseña actualizada correctamente');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: FutureBuilder<AccountModel>(
        future: _accountFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return SafeArea(
              child: Column(
                children: [
                  const SubPageHeader(
                    title: 'Mi cuenta',
                    icon: Icons.person_outline_rounded,
                  ),
                  Expanded(
                    child: EmptyStateView(
                      icon: Icons.person_off_rounded,
                      title: 'No se pudo cargar tu cuenta',
                      subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
                      onRetry: _reload,
                    ),
                  ),
                ],
              ),
            );
          }

          final account = snapshot.data!;

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SubPageHeader(
                  title: 'Mi cuenta',
                  subtitle: 'Actualiza tu nombre y tu contraseña.',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccountSummary(account: account),
                      const SizedBox(height: 22),
                      _SectionLabel('Datos personales'),
                      const SizedBox(height: 10),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nombre',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Tu nombre',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _savingName ? null : _saveName,
                                icon: _savingName
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  _savingName
                                      ? 'Guardando...'
                                      : 'Guardar cambios',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel('Correo electrónico'),
                      const SizedBox(height: 10),
                      _Card(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mail_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.email.isEmpty
                                        ? 'Sin correo'
                                        : account.email,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.anthracite,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'El correo no se puede cambiar desde aquí.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.slateLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel('Contraseña'),
                      const SizedBox(height: 10),
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Usa una contraseña segura que no compartas con nadie.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.slate,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openPasswordDialog,
                                icon: const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 18,
                                ),
                                label: const Text('Cambiar contraseña'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

/// Tarjeta verde con el avatar, el nombre y el correo.
class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.heroMid, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                account.initial,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(text: 'Cuenta con ${account.providerLabel}'),
                    if (account.memberSince != null)
                      _Chip(text: 'Desde ${_monthYear(account.memberSince!)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthYear(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

/// Etiqueta pequeña y semitransparente sobre el fondo verde.
class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Título pequeño que separa las secciones.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

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

/// Tarjeta blanca con borde, usada para agrupar campos.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Ventana para cambiar la contraseña con validaciones en español.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.datasource});

  final AccountDatasource datasource;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.datasource.changePassword(
        oldPassword: _currentController.text,
        newPassword: _newController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ClientException catch (error) {
      final raw = error.response['message']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _error = raw.isNotEmpty
            ? 'No se pudo cambiar: $raw'
            : 'La contraseña actual no es correcta.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cambiar la contraseña. Inténtalo de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Cambiar contraseña',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Escribe tu contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña nueva',
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Debe tener al menos 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repite la contraseña nueva',
                ),
                validator: (value) {
                  if (value != _newController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
