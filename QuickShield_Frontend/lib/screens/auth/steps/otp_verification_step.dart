import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';

class OtpVerificationStep extends StatefulWidget {
  final VoidCallback onSuccess;

  const OtpVerificationStep({super.key, required this.onSuccess});

  @override
  State<OtpVerificationStep> createState() => _OtpVerificationStepState();
}

class _OtpVerificationStepState extends State<OtpVerificationStep>
    with SingleTickerProviderStateMixin {
  static const _otpLength = 4;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  Timer? _resendTimer;
  int _resendSeconds = 30;
  bool _canResend = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < _otpLength) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.verifyOtp(otp);
    if (ok && mounted) {
      widget.onSuccess();
    } else if (mounted) {
      // Shake animation on error
      _shakeController.forward().then((_) => _shakeController.reverse());
      // Clear fields
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    final auth = context.read<AuthProvider>();
    final phone = auth.userData.phoneNumber ?? '';
    await auth.sendOtp(phone);
    if (mounted) {
      _startResendTimer();
    }
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-submit when all filled
    if (_otpValue.length == _otpLength) {
      _verifyOtp();
    }
  }

  void _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final phone = auth.userData.phoneNumber ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(fontSize: 14, color: QSColors.textMid, height: 1.5),
            children: [
              const TextSpan(text: 'Enter the 4-digit code sent to '),
              TextSpan(
                text: '+91 $phone',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: QSColors.textDark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // OTP fields with shake animation
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _shakeAnim.value *
                    (_shakeController.status == AnimationStatus.forward
                        ? 1
                        : -1),
                0,
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_otpLength, (i) {
              return Container(
                width: 60,
                height: 64,
                margin: EdgeInsets.only(right: i < _otpLength - 1 ? 14 : 0),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (e) => _onKey(i, e),
                  child: TextFormField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (v) => _onChanged(i, v),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: QSColors.textDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _focusNodes[i].hasFocus
                          ? QSColors.primaryLight
                          : QSColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _focusNodes[i].hasFocus
                              ? QSColors.primary
                              : QSColors.border,
                          width: _focusNodes[i].hasFocus ? 1.5 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: QSColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: QSColors.primary, width: 1.5),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 20),

        // Loading indicator
        if (auth.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: QSColors.primary,
                ),
              ),
            ),
          ),

        // Error message
        if (auth.error != null && !auth.isLoading) ...[
          const SizedBox(height: 4),
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
                    style: GoogleFonts.inter(fontSize: 13, color: QSColors.red),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Resend row
        Center(
          child: _canResend
              ? GestureDetector(
                  onTap: _resendOtp,
                  child: Text(
                    'Resend OTP',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: QSColors.primary,
                    ),
                  ),
                )
              : RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        fontSize: 14, color: QSColors.textMuted),
                    children: [
                      const TextSpan(text: 'Resend code in '),
                      TextSpan(
                        text: '${_resendSeconds}s',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: QSColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 16),

        // Hint
        Center(
          child: Text(
            'Demo OTP: 1234',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: QSColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
