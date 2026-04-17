import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey   = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.fullName ?? '');
    _cityCtrl = TextEditingController(text: auth.city    ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final auth  = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    try {
      final res = await ApiService.instance.put('/auth/profile', {
        'full_name': _nameCtrl.text.trim(),
        'city':      _cityCtrl.text.trim(),
      }, token);

      // Update local auth state
      auth.updateProfile(
        fullName: res['worker']['full_name'],
        city:     res['worker']['city'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Personal Details',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QSColors.primary.withOpacity(0.2),
                    border: Border.all(color: QSColors.primary.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      (auth.fullName?.isNotEmpty == true)
                        ? auth.fullName![0].toUpperCase()
                        : '?',
                      style: GoogleFonts.inter(
                        fontSize: 32, fontWeight: FontWeight.w900,
                        color: QSColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Full name field
              _label('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDeco('Enter your full name', Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),

              // City field
              _label('City'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: _inputDeco('Enter your city', Icons.location_city_outlined),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: 20),

              // Phone (read-only)
              _label('Phone Number'),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: auth.phone ?? '',
                readOnly: true,
                style: GoogleFonts.inter(color: Colors.white54),
                decoration: _inputDeco('Phone number', Icons.phone_outlined).copyWith(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  suffixIcon: const Icon(Icons.lock_outline, color: Colors.white24, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              Text('Phone number cannot be changed',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QSColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text('Save Changes',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
    style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500));

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: Colors.white24),
    prefixIcon: Icon(icon, color: Colors.white38, size: 20),
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: QSColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}
