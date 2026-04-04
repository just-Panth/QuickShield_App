import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';

class AccountSetupStep extends StatefulWidget {
  final VoidCallback onSuccess;

  const AccountSetupStep({super.key, required this.onSuccess});

  @override
  State<AccountSetupStep> createState() => _AccountSetupStepState();
}

class _AccountSetupStepState extends State<AccountSetupStep> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters';
    return null;
  }

  int _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%\^&\*\(\)\-_=\+]'))) score++;
    return score;
  }

  String _strengthLabel(int score) {
    switch (score) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  Color _strengthColor(int score) {
    switch (score) {
      case 1:
        return QSColors.red;
      case 2:
        return QSColors.orange;
      case 3:
        return QSColors.primary;
      default:
        return QSColors.green;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.registerAccount(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (ok && mounted) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pwd = _passwordController.text;
    final strength = _passwordStrength(pwd);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QSColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: QSColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 20, color: QSColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Set up your login credentials. You'll use these to sign in.",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: QSColors.primaryDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Email
            _label('Email address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              style: GoogleFonts.inter(
                  color: QSColors.textDark, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 20),

            // Password
            _label('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              validator: _validatePassword,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(
                  color: QSColors.textDark, fontSize: 15),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
            ),

            // Password strength indicator
            if (pwd.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ...List.generate(4, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: i < strength
                              ? _strengthColor(strength)
                              : QSColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Text(
                    _strengthLabel(strength),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: strength > 0
                          ? _strengthColor(strength)
                          : QSColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],

            // Error
            if (auth.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: QSColors.redLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: QSColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: QSColors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: QSColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: QSColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create account',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: QSColors.textOnDarkMid,
      ),
    );
  }
}
