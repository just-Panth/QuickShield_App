import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../services/claim_service.dart';
import '../../widgets/app_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PayoutScreen — Animated claim processing + result display
//
// States (in order):
//   1. submitting  — spinning shield + "Processing your claim…"
//   2. fraud_check — animated fraud score meter
//   3. result      — approved / review / rejected card with all details
// ─────────────────────────────────────────────────────────────────────────────

enum _PayoutState { submitting, fraudCheck, result }

class PayoutScreen extends StatefulWidget {
  final String policyId;
  final String disruptionType;
  final double earnedToday;
  final String token;

  const PayoutScreen({
    super.key,
    required this.policyId,
    required this.disruptionType,
    required this.earnedToday,
    required this.token,
  });

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen>
    with TickerProviderStateMixin {
  _PayoutState _state = _PayoutState.submitting;

  Map<String, dynamic>? _result;
  String? _errorMsg;

  // Animation controllers
  late AnimationController _spinController;
  late AnimationController _scoreController;
  late AnimationController _resultController;

  int _displayedScore = 0;
  Timer? _scoreTimer;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Start pipeline immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPipeline());
  }

  @override
  void dispose() {
    _spinController.dispose();
    _scoreController.dispose();
    _resultController.dispose();
    _scoreTimer?.cancel();
    super.dispose();
  }

  Future<void> _runPipeline() async {
    try {
      // ── Step 1: Submit (shows spinner for at least 1.5s) ────────────────
      final resultFuture = ClaimService.instance.submitClaim(
        token:          widget.token,
        policyId:       widget.policyId,
        disruptionType: widget.disruptionType,
        earnedTodayInr: widget.earnedToday,
      );

      // Wait at least 1.5s to show the spinner dramatically
      final result = await Future.wait([
        resultFuture,
        Future.delayed(const Duration(milliseconds: 1500)),
      ]).then((v) => v[0] as Map<String, dynamic>);

      if (!mounted) return;

      // ── Step 2: Fraud check animation ────────────────────────────────────
      setState(() => _state = _PayoutState.fraudCheck);
      _spinController.stop();
      _scoreController.forward();

      final targetScore = (result['fraud_score'] as num?)?.toInt() ?? 0;
      _animateScore(targetScore);

      // Show fraud check state for 2.5s
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;

      // ── Step 3: Show result ───────────────────────────────────────────────
      setState(() {
        _state  = _PayoutState.result;
        _result = result;
      });
      _resultController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state    = _PayoutState.result;
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
        _result   = {'status': 'error'};
      });
      _resultController.forward();
    }
  }

  void _animateScore(int target) {
    int current = 0;
    const step = 1;
    const intervalMs = 20;
    _scoreTimer = Timer.periodic(
      const Duration(milliseconds: intervalMs),
      (t) {
        if (current >= target) {
          t.cancel();
          return;
        }
        current = (current + step).clamp(0, target);
        if (mounted) setState(() => _displayedScore = current);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      appBar: _state == _PayoutState.result
          ? AppBar(
              backgroundColor: QSColors.bg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: QSColors.textOnDark),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Claim Result',
                style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: QSColors.textOnDark,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _PayoutState.submitting:
        return _SubmittingView(spinController: _spinController);
      case _PayoutState.fraudCheck:
        return _FraudCheckView(score: _displayedScore);
      case _PayoutState.result:
        return _ResultView(
          result: _result,
          errorMsg: _errorMsg,
          controller: _resultController,
          onDone: () => Navigator.pop(context),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Submitting spinner
// ─────────────────────────────────────────────────────────────────────────────

class _SubmittingView extends StatelessWidget {
  final AnimationController spinController;
  const _SubmittingView({required this.spinController});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: spinController,
            child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: QSColors.gradHero),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: QSColors.primary.withOpacity(0.5),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Processing your claim…',
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w700, color: QSColors.textOnDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Running 3-gate verification pipeline',
            style: GoogleFonts.inter(fontSize: 14, color: QSColors.textOnDarkMid),
          ),
          const SizedBox(height: 40),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              color: QSColors.primary,
              backgroundColor: QSColors.cardDark,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Fraud score animation
// ─────────────────────────────────────────────────────────────────────────────

class _FraudCheckView extends StatelessWidget {
  final int score;
  const _FraudCheckView({required this.score});

  Color get _scoreColor {
    if (score < 40)  return QSColors.green;
    if (score <= 70) return QSColors.orangeVib;
    return QSColors.redVib;
  }

  String get _scoreLabel {
    if (score < 40)  return 'Low Risk';
    if (score <= 70) return 'Medium Risk';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield with score inside
            Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                color: _scoreColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _scoreColor.withOpacity(0.4), width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.inter(
                      fontSize: 48, fontWeight: FontWeight.w900, color: _scoreColor,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: GoogleFonts.inter(fontSize: 14, color: QSColors.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Fraud Analysis',
              style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w800, color: QSColors.textOnDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _scoreLabel,
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: _scoreColor,
              ),
            ),
            const SizedBox(height: 32),
            // Score bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100,
                color: _scoreColor,
                backgroundColor: _scoreColor.withOpacity(0.1),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Checking GPS location, weather data\nand claim history…',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: QSColors.textOnDarkMid),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Result card (approved / review / rejected / error)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final Map<String, dynamic>? result;
  final String? errorMsg;
  final AnimationController controller;
  final VoidCallback onDone;

  const _ResultView({
    required this.result,
    required this.errorMsg,
    required this.controller,
    required this.onDone,
  });

  String get _status => result?['status'] ?? 'error';
  bool get _isApproved  => _status == 'paid';
  bool get _isReview    => _status == 'review';
  bool get _isRejected  => _status == 'rejected';
  bool get _isError     => _status == 'error';

  Color get _statusColor {
    if (_isApproved) return QSColors.green;
    if (_isReview)   return QSColors.orangeVib;
    return QSColors.redVib;
  }

  IconData get _statusIcon {
    if (_isApproved) return Icons.check_circle_rounded;
    if (_isReview)   return Icons.hourglass_top_rounded;
    return Icons.cancel_rounded;
  }

  String get _statusTitle {
    if (_isApproved) return 'Payment Successful!';
    if (_isReview)   return 'Claim Under Review';
    if (_isRejected) return 'Claim Rejected';
    return 'Something went wrong';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QSSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // ── Status icon ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _statusColor.withOpacity(0.4), width: 2),
                ),
                child: Icon(_statusIcon, size: 52, color: _statusColor),
              ),
            ),
            const SizedBox(height: 20),

            // ── Status title ─────────────────────────────────────────────
            Text(
              _statusTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w800, color: QSColors.textOnDark,
              ),
            ),
            const SizedBox(height: QSSpacing.m),

            // ── Payout amount (if approved) ───────────────────────────────
            if (_isApproved) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [QSColors.green.withOpacity(0.15), QSColors.green.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: QSColors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '₹${(result!['payout_inr'] as num?)?.toInt() ?? 0}',
                        style: GoogleFonts.inter(
                          fontSize: 40, fontWeight: FontWeight.w900,
                          color: QSColors.green, letterSpacing: -1,
                        ),
                      ),
                      Text(
                        'Amount Credited',
                        style: GoogleFonts.inter(fontSize: 13, color: QSColors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Transaction ID
              if (result!['payout'] != null) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.receipt_long_rounded,
                        label: 'Transaction ID',
                        value: result!['payout']['txn_id']?.toString() ?? '—',
                        valueColor: QSColors.primary,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.payments_rounded,
                        label: 'Gateway',
                        value: result!['payout']['gateway'] ?? 'Razorpay',
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Processed in',
                        value: '${result!['payout']['processing_ms'] ?? 1200} ms',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // ── Review message ────────────────────────────────────────────
            if (_isReview)
              AppCard(
                glowColor: QSColors.orangeVib,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What happens next?',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: QSColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our team will review your claim within 24 hours. '
                      'You will receive a notification once the decision is made.',
                      style: GoogleFonts.inter(fontSize: 13, color: QSColors.textLight),
                    ),
                  ],
                ),
              ),

            // ── Fraud explanation ──────────────────────────────────────────
            const SizedBox(height: QSSpacing.m),
            _FraudExplanationCard(result: result),

            // ── Error message ─────────────────────────────────────────────
            if (_isError && errorMsg != null)
              AppCard(
                glowColor: QSColors.redVib,
                padding: const EdgeInsets.all(16),
                child: Text(
                  errorMsg!,
                  style: GoogleFonts.inter(fontSize: 13, color: QSColors.textLight),
                ),
              ),

            const SizedBox(height: QSSpacing.xl),

            // ── Done button ────────────────────────────────────────────────
            SizedBox(
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isApproved
                        ? [QSColors.green, const Color(0xFF059669)]
                        : QSColors.gradHero,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onDone,
                    child: Center(
                      child: Text(
                        _isApproved ? 'Done' : 'Back to Claims',
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: QSSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FraudExplanationCard extends StatelessWidget {
  final Map<String, dynamic>? result;
  const _FraudExplanationCard({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    final score       = (result!['fraud_score'] as num?)?.toInt();
    final verdict     = result!['fraud_verdict'] as String?;
    final explanation = result!['fraud_explanation'] as String?;

    if (score == null || verdict == null) return const SizedBox.shrink();

    Color verdictColor = QSColors.green;
    if (verdict == 'FLAG_FOR_REVIEW') verdictColor = QSColors.orangeVib;
    if (verdict == 'REJECT')          verdictColor = QSColors.redVib;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, size: 16, color: QSColors.primary),
              const SizedBox(width: 8),
              Text(
                'AI Fraud Analysis',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: QSColors.textDark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: verdictColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: $score/100',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: verdictColor),
                ),
              ),
            ],
          ),
          if (explanation != null) ...[
            const SizedBox(height: 10),
            Text(
              explanation,
              style: GoogleFonts.inter(fontSize: 12, color: QSColors.textLight),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: QSColors.textLight),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: QSColors.textLight),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: valueColor ?? QSColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
