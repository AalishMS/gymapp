import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email and password required';
      });
      return;
    }

    final success = await _authService.login(email, password);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor(context);
    final border = borderColor(context);
    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary = textPrimaryColor(context);
    final textSecondary = textSecondaryColor(context);
    final errorColor = Theme.of(context).extension<AppColorScheme>()?.error ??
        const Color(0xFFFF4444);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(accent),
                const SizedBox(height: 48),
                _buildInputContainer(
                  context,
                  bg: bg,
                  border: border,
                  accent: accent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTerminalLabel('> EMAIL:', textSecondary),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'enter email',
                        textPrimary: textPrimary,
                        border: border,
                        accent: accent,
                      ),
                      const SizedBox(height: 24),
                      _buildTerminalLabel('> PASSWORD:', textSecondary),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'enter password',
                        obscureText: true,
                        textPrimary: textPrimary,
                        border: border,
                        accent: accent,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorMessage(_errorMessage!, errorColor),
                      ],
                      const SizedBox(height: 32),
                      _buildLoginButton(accent, textPrimary),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildRegisterLink(accent, textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: accent, width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withAlpha(51),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            '> OPENGYM',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'AUTHENTICATE TO CONTINUE',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: accent.withAlpha(153),
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildInputContainer(
    BuildContext context, {
    required Color bg,
    required Color border,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildTerminalLabel(String label, Color textSecondary) {
    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        color: textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    required Color textPrimary,
    required Color border,
    required Color accent,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: textPrimary.withAlpha(102),
        ),
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: accent, width: 1),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message, Color errorColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: errorColor, width: 1),
      ),
      child: Text(
        '> ERROR: $message',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: errorColor,
        ),
      ),
    );
  }

  Widget _buildLoginButton(Color accent, Color textPrimary) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceColor(context),
          foregroundColor: accent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: accent, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              )
            : Text(
                '[ LOGIN ]',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink(Color accent, Color textSecondary) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/register'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "don't have an account? ",
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          Text(
            '[ REGISTER ]',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
