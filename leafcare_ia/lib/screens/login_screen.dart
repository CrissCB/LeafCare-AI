import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';

import '../services/pocketbase_client.dart';
import '../theme/app_theme.dart';
import '../widgets/leaf_logo.dart';

const String _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
  <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
</svg>
''';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;

  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
        ),
      );
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = email.isEmpty
        ? 'Ingresa tu correo electrónico'
        : (!_emailRegExp.hasMatch(email) ? 'Ingresa un correo válido' : null);
    final passwordError = password.isEmpty ? 'Ingresa tu contraseña' : null;

    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
      _loading = true;
    });

    try {
      await pocketBase.collection('users').authWithPassword(email, password);
      if (!mounted) return;
      _snack('Bienvenido, sesión iniciada correctamente');
    } on ClientException catch (e) {
      if (!mounted) return;
      _snack(_friendlyError(e), error: true);
    } catch (_) {
      if (!mounted) return;
      _snack(
        'No se pudo conectar con el servidor. Verifica que PocketBase esté activo.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(ClientException e) {
    final raw = (e.response['message'] as String?)?.trim();
    if (raw == null || raw.isEmpty || raw == 'Failed to authenticate.') {
      return 'Correo o contraseña incorrectos';
    }
    return raw;
  }

  void _comingSoon(String label) => _snack('$label: próximamente');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            final content = ColoredBox(color: AppColors.white, child: _form());

            if (!isWide) return content;

            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.mint, AppColors.pageBg],
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 860,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: content,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      children: [
        const _LoginHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Iniciar Sesión',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.anthracite,
                  ),
                ),
                const SizedBox(height: 20),
                const _Label('Correo Electrónico'),
                const SizedBox(height: 6),
                _LeafInput(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  icon: Icons.mail_outline_rounded,
                  hint: 'usuario@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  errorText: _emailError,
                  onChanged: () {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 14),
                const _Label('Contraseña'),
                const SizedBox(height: 6),
                _LeafInput(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  icon: Icons.lock_outline_rounded,
                  hint: '••••••••',
                  obscure: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  errorText: _passwordError,
                  onChanged: () {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  onSubmitted: (_) => _signIn(),
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.slateLight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _comingSoon('Recuperar contraseña'),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _PrimaryButton(
                  label: 'Iniciar Sesión',
                  loading: _loading,
                  onTap: _loading ? null : _signIn,
                ),
                const SizedBox(height: 12),
                _SecondaryButton(
                  label: 'Continuar con Google',
                  onTap: () => _comingSoon('Continuar con Google'),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿No tienes cuenta? ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.slate,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _comingSoon('Registro'),
                      child: Text(
                        'Regístrate aquí',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -60, right: -60, child: _circle(180, AppColors.neon06)),
          Positioned(bottom: -30, left: -40, child: _circle(120, AppColors.neon05)),
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 36),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.neon12,
                    border: Border.all(color: AppColors.neon35, width: 1.5),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(child: LeafLogo(size: 40)),
                ),
                const SizedBox(height: 12),
                Text(
                  'LeafCare AI',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Diagnóstico inteligente para tus plantas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.slate,
        letterSpacing: 0.66,
      ),
    );
  }
}

class _LeafInput extends StatefulWidget {
  const _LeafInput({
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.suffix,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onChanged;

  @override
  State<_LeafInput> createState() => _LeafInputState();
}

class _LeafInputState extends State<_LeafInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AppColors.error
        : (focused ? AppColors.primary : AppColors.inputBorder);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: focused ? AppColors.white : AppColors.inputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onSubmitted: widget.onSubmitted,
                  onChanged: (_) => widget.onChanged?.call(),
                  cursorColor: AppColors.primary,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.anthracite,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.slateLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 8),
                widget.suffix!,
              ],
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 0.16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.string(_googleLogoSvg, width: 20, height: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.anthracite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
