import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.fullName ?? '');
    _cityCtrl = TextEditingController(text: auth.userProfile.city ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() { _saving = true; _successMsg = null; _errorMsg = null; });
    try {
      await ApiService.instance.put('/auth/profile', {
        'full_name': _nameCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      }, token);
      if (mounted) {
        setState(() { _saving = false; _successMsg = 'Profile updated successfully'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: QSColors.bg,
      appBar: AppBar(
        backgroundColor: QSColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: QSColors.textOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: QSColors.textOnDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(QSSpacing.m),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: QSColors.gradHero),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: QSColors.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
                  ),
                ),
                const SizedBox(height: QSSpacing.l),

                // Read-only fields
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReadOnlyField(
                        label: 'Email',
                        value: auth.userData.email ?? '—',
                        icon: Icons.email_rounded,
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(
                        label: 'Worker ID',
                        value: auth.userProfile.workerId ?? '—',
                        icon: Icons.badge_rounded,
                      ),
                      const SizedBox(height: 16),
                      _ReadOnlyField(
                        label: 'Platform',
                        value: auth.userData.platform ?? '—',
                        icon: Icons.store_rounded,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: QSSpacing.m),

                // Editable fields
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _EditField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      _EditField(
                        controller: _cityCtrl,
                        label: 'City',
                        icon: Icons.location_city_rounded,
                        validator: (v) => null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: QSSpacing.m),

                if (_successMsg != null)
                  _StatusBanner(message: _successMsg!, isError: false),
                if (_errorMsg != null)
                  _StatusBanner(message: _errorMsg!, isError: true),
                if (_successMsg != null || _errorMsg != null)
                  const SizedBox(height: QSSpacing.m),

                // Save button
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: QSColors.gradHero),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _saving ? null : _save,
                        child: Center(
                          child: _saving
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReadOnlyField({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: QSColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: QSColors.textMid),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(fontSize: 11, color: QSColors.textLight)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: QSColors.textMid,
                  )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: QSColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Read only',
            style: GoogleFonts.inter(fontSize: 10, color: QSColors.textMuted),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: QSColors.textDark, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: QSColors.textLight),
        prefixIcon: Icon(icon, size: 20, color: QSColors.primary),
        filled: true,
        fillColor: QSColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: QSColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: QSColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: QSColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: QSColors.redVib),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _StatusBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? QSColors.redVib : QSColors.green;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_rounded : Icons.check_circle_rounded,
            size: 18, color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
