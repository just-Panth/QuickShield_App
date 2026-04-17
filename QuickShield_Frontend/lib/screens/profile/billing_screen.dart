import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _upiCtrl = TextEditingController();
  bool _saving   = false;
  String? _error;

  // UPI ID regex: word chars + dots, @, then word chars (e.g. name@okaxis)
  static final _upiRegex = RegExp(r'^\w[\w.]*@\w+$');

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _upiCtrl.text = auth.upiId ?? '';
  }

  @override
  void dispose() {
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final upi = _upiCtrl.text.trim();
    if (!_upiRegex.hasMatch(upi)) {
      setState(() => _error = 'Enter a valid UPI ID (e.g. name@okaxis)');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final auth  = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    try {
      final res = await ApiService.instance.put('/auth/profile', {
        'upi_id': upi,
      }, token);

      auth.updateProfile(upiId: res['worker']['upi_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI ID saved! Payouts will go here.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Save failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasUpi = auth.upiId?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Billing & UPI',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: QSColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: QSColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: QSColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All approved claim payouts will be instantly sent to this UPI ID. Make sure it is active.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Current UPI status card
            if (hasUpi) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 22),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current UPI ID',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(auth.upiId!,
                          style: GoogleFonts.inter(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                    const SizedBox(width: 12),
                    Text('No UPI ID set — claims cannot be paid out.',
                      style: GoogleFonts.inter(color: Colors.orange, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // UPI input
            Text('${hasUpi ? 'Update' : 'Set'} UPI ID',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _upiCtrl,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                hintText: 'yourname@okaxis',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white38, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _error != null ? Colors.redAccent : Colors.white12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: QSColors.primary, width: 1.5),
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'UPI format: handle@bank  (e.g. john@okaxis, 9876543210@upi)',
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
            ),
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
                  : Text('Save & Verify',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
