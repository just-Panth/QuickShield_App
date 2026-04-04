import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import 'steps/phone_input_step.dart';
import 'steps/otp_verification_step.dart';
import 'steps/account_setup_step.dart';
import 'steps/work_details_step.dart';
import 'steps/location_permission_step.dart';

/// 5-step registration / onboarding flow.
///
/// On final step completion the user is **automatically authenticated**
/// and navigated to the Dashboard. No redirect to login.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _step = 0;
  static const _totalSteps = 5;

  final List<String> _stepTitles = const [
    'Phone verification',
    'Enter OTP',
    'Account setup',
    'Work details',
    'Location access',
  ];

  final List<String> _stepSubtitles = const [
    'Step 1 of 5 — Verify your number',
    'Step 2 of 5 — Confirm the code',
    'Step 3 of 5 — Create credentials',
    'Step 4 of 5 — Tell us about your work',
    'Step 5 of 5 — Enable smart protection',
  ];

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  void _onComplete() {
    // Auth provider already set isLoggedIn = true in completeOnboarding().
    // Navigator pops back; Consumer<AuthProvider> in main.dart rebuilds
    // to show AppShell (dashboard).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goBack() {
    // Clear any lingering errors when stepping back
    context.read<AuthProvider>().clearError();

    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: QSColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: QSColors.border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 20, color: QSColors.textDark),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_step + 1} / $_totalSteps',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: QSColors.textOnDarkMid,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Progress segments
                  Row(
                    children: List.generate(_totalSteps, (i) {
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: 5,
                          margin: EdgeInsets.only(
                              right: i < _totalSteps - 1 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? QSColors.primary
                                : QSColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(_step),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stepTitles[_step],
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: QSColors.textOnDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _stepSubtitles[_step],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: QSColors.textOnDarkMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Step content ───────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return PhoneInputStep(onSuccess: _nextStep);
      case 1:
        return OtpVerificationStep(onSuccess: _nextStep);
      case 2:
        return AccountSetupStep(onSuccess: _nextStep);
      case 3:
        return WorkDetailsStep(onSuccess: _nextStep);
      case 4:
        return LocationPermissionStep(onSuccess: _onComplete);
      default:
        return const SizedBox();
    }
  }
}