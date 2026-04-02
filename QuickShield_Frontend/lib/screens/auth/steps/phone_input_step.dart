import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';

class PhoneInputStep extends StatefulWidget {
  final VoidCallback onSuccess;

  const PhoneInputStep({super.key, required this.onSuccess});

  @override
  State<PhoneInputStep> createState() => _PhoneInputStepState();
}

class _PhoneInputStepState extends State<PhoneInputStep> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.sendOtp(phone);
    if (ok && mounted) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QSColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: QSColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android_rounded,
                    size: 20, color: QSColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "We'll send a one-time verification code to your phone number.",
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

          Text(
            'Phone number',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: QSColors.textMid,
            ),
          ),
          const SizedBox(height: 8),

          // Phone field with +91 prefix
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            style: GoogleFonts.inter(
              color: QSColors.textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '9876543210',
              prefixIcon: Container(
                width: 72,
                alignment: Alignment.center,
                child: Text(
                  '+91',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: QSColors.textDark,
                  ),
                ),
              ),
            ),
          ),

          // Error message
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        fontSize: 13,
                        color: QSColors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Send OTP button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _sendOtp,
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
                          'Send OTP',
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
    );
  }
}
