import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiCtrl = TextEditingController();
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Pre-fill existing UPI id if stored in userData
    final auth = context.read<AuthProvider>();
    _upiCtrl.text = auth.userData.upiId ?? '';
  }

  @override
  void dispose() {
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() { _saving = true; _successMsg = null; _errorMsg = null; });
    try {
      await ApiService.instance.put('/auth/profile', {
        'upi_id': _upiCtrl.text.trim(),
      }, token);
      if (mounted) {
        setState(() {
          _saving = false;
          _successMsg = 'UPI ID saved! Payouts will be credited here.';
        });
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

  String? _validateUpi(String? v) {
    if (v == null || v.trim().isEmpty) return 'UPI ID is required';
    final upiRegex = RegExp(r'^[\w.\-]+@[\w.\-]+$');
    if (!upiRegex.hasMatch(v.trim())) return 'Invalid UPI ID format (e.g., name@upi)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
          'Billing & Payments',
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
                // Info banner
                AppCard(
                  glowColor: QSColors.primary,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: QSColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            color: QSColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant Payouts via UPI',
                              style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: QSColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Approved claims are transferred to your UPI ID within seconds.',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: QSColors.textLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: QSSpacing.l),

                Text(
                  'YOUR UPI ID',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: QSColors.textOnDarkMid, letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: QSSpacing.s),

                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _upiCtrl,
                        validator: _validateUpi,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(
                          fontSize: 15, color: QSColors.textDark, fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText: 'UPI ID',
                          hintText: 'yourname@paytm',
                          labelStyle: GoogleFonts.inter(fontSize: 13, color: QSColors.textLight),
                          prefixIcon: const Icon(Icons.currency_rupee_rounded,
                              size: 20, color: QSColors.primary),
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
                            borderSide: const BorderSide(color: QSColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: QSColors.redVib),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 14, color: QSColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Supports Paytm, PhonePe, GPay, BHIM UPI',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: QSColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: QSSpacing.m),

                // Supported apps row
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supported payment apps',
                        style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: QSColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: ['PhonePe', 'Paytm', 'Google Pay', 'BHIM', 'Amazon Pay']
                            .map((app) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: QSColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: QSColors.border),
                                  ),
                                  child: Text(
                                    app,
                                    style: GoogleFonts.inter(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: QSColors.textMid,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: QSSpacing.m),

                if (_successMsg != null)
                  _Banner(message: _successMsg!, color: QSColors.green),
                if (_errorMsg != null)
                  _Banner(message: _errorMsg!, color: QSColors.redVib),
                if (_successMsg != null || _errorMsg != null)
                  const SizedBox(height: QSSpacing.m),

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
                                  'Save & Verify',
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

class _Banner extends StatelessWidget {
  final String message;
  final Color color;
  const _Banner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(
                    fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
