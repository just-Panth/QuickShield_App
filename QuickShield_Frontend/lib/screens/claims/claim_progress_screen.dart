import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import 'payment_success_screen.dart';

class ClaimProgressScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> claimFuture;

  const ClaimProgressScreen({super.key, required this.claimFuture});

  @override
  State<ClaimProgressScreen> createState() => _ClaimProgressScreenState();
}

class _ClaimProgressScreenState extends State<ClaimProgressScreen>
    with TickerProviderStateMixin {

  final List<_GateStep> _steps = [
    _GateStep(icon: '🔍', label: 'Checking disruption in your zone...', sublabel: 'Gate 1 — Parametric Trigger'),
    _GateStep(icon: '🛡️', label: 'Running anti-fraud checks...',        sublabel: 'Gate 2 — Fraud Engine'),
    _GateStep(icon: '💰', label: 'Calculating your payout...',           sublabel: 'Gate 3 — Payout Formula'),
    _GateStep(icon: '📲', label: 'Sending to your UPI...',               sublabel: 'Payment Transfer'),
  ];

  int _currentStep = 0;
  bool _done = false;
  bool _failed = false;
  String _failReason = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _runPipeline();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPipeline() async {
    // Animate steps while waiting for the real API call
    for (int i = 0; i < _steps.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
    }

    // Now wait for the real result
    try {
      final result = await widget.claimFuture;
      if (!mounted) return;
      setState(() {
        _done = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(result: result)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Try to parse backend rejection reason
      final reasonMatch = RegExp(r'"reason":"([^"]+)"').firstMatch(msg);
      setState(() {
        _failed     = true;
        _failReason = reasonMatch?.group(1) ?? 'Claim could not be processed at this time.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                _failed ? 'Claim Rejected' : _done ? 'Claim Approved! 🎉' : 'Processing Claim',
                style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  color: _failed ? Colors.redAccent : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _failed
                  ? 'Your claim did not pass verification'
                  : 'We are verifying your claim in real-time',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // Gate steps
              ...List.generate(_steps.length, (i) => _buildStepTile(i)),

              if (_failed) ...[
                const SizedBox(height: 32),
                _FailureCard(reason: _failReason),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Back to Claims',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],

              const Spacer(),

              // Bottom pulsing indicator when running
              if (!_done && !_failed)
                Center(
                  child: ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: QSColors.primary.withOpacity(0.15),
                        border: Border.all(color: QSColors.primary.withOpacity(0.4), width: 2),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28, height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(QSColors.primary),
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
    );
  }

  Widget _buildStepTile(int index) {
    final step     = _steps[index];
    final isActive = index == _currentStep && !_done && !_failed;
    final isDone   = index < _currentStep || _done;
    final isFailed = _failed && index == _currentStep;

    return AnimatedOpacity(
      opacity: index <= _currentStep || _done ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDone && !_failed
            ? Colors.green.withOpacity(0.08)
            : isFailed
              ? Colors.redAccent.withOpacity(0.08)
              : isActive
                ? QSColors.primary.withOpacity(0.08)
                : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone && !_failed
              ? Colors.green.withOpacity(0.25)
              : isFailed
                ? Colors.redAccent.withOpacity(0.3)
                : isActive
                  ? QSColors.primary.withOpacity(0.3)
                  : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Text(step.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.label,
                    style: GoogleFonts.inter(
                      color: isDone || isActive ? Colors.white : Colors.white38,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    )),
                  const SizedBox(height: 2),
                  Text(step.sublabel,
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            if (isActive && !_failed)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: QSColors.primary),
              )
            else if (isFailed)
              const Icon(Icons.cancel, color: Colors.redAccent, size: 22)
            else if (isDone)
              const Icon(Icons.check_circle, color: Colors.green, size: 22)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 22),
          ],
        ),
      ),
    );
  }
}

class _GateStep {
  final String icon;
  final String label;
  final String sublabel;
  const _GateStep({required this.icon, required this.label, required this.sublabel});
}

class _FailureCard extends StatelessWidget {
  final String reason;
  const _FailureCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(reason,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
