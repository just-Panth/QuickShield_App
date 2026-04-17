import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/claim_service.dart';
import '../../widgets/app_card.dart';
import 'payout_screen.dart';

class FileClaimScreen extends StatefulWidget {
  const FileClaimScreen({super.key});

  @override
  State<FileClaimScreen> createState() => _FileClaimScreenState();
}

class _FileClaimScreenState extends State<FileClaimScreen> {
  String _selectedDisruption = 'weather';
  final _earnedController = TextEditingController();
  bool _isSubmitting = false;

  final List<_DisruptionOption> _options = const [
    _DisruptionOption('weather',  'Bad Weather',    Icons.thunderstorm_rounded,   Color(0xFF60A5FA)),
    _DisruptionOption('traffic',  'Traffic Block',  Icons.traffic_rounded,         Color(0xFFFBBF24)),
    _DisruptionOption('platform', 'App Outage',     Icons.phonelink_erase_rounded, Color(0xFFF87171)),
    _DisruptionOption('other',    'Other',           Icons.more_horiz_rounded,      Color(0xFFA78BFA)),
  ];

  @override
  void dispose() {
    _earnedController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final earned = double.tryParse(_earnedController.text) ?? 0.0;
    final token  = context.read<AuthProvider>().token;

    if (token == null) {
      _showError('Please log in again.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Fetch the worker's active policy ID first
      final policyId = await ClaimService.instance.fetchActivePolicyId(token);

      if (policyId == null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showError('No active policy found. Please purchase a policy first.');
        }
        return;
      }

      if (mounted) {
        // Navigate to payout screen which handles the actual submission
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PayoutScreen(
              policyId:       policyId,
              disruptionType: _selectedDisruption,
              earnedToday:    earned,
              token:          token,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: QSColors.redVib,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'File a Claim',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: QSColors.textOnDark,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(QSSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ────────────────────────────────────────────────
            AppCard(
              glowColor: QSColors.primary,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: QSColors.gradHero),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income Protection Claim',
                          style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: QSColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI fraud check + instant payout',
                          style: GoogleFonts.inter(fontSize: 12, color: QSColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Disruption Type ────────────────────────────────────────────
            Text(
              'What happened?',
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: QSColors.textOnDark,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.6,
              children: _options.map((opt) {
                final selected = _selectedDisruption == opt.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDisruption = opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? opt.color.withOpacity(0.15)
                          : QSColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? opt.color : QSColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(opt.icon, color: selected ? opt.color : QSColors.textLight, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          opt.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? opt.color : QSColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Earnings today ─────────────────────────────────────────────
            Text(
              "Today's earnings before disruption",
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: QSColors.textOnDark,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _earnedController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: QSColors.textDark),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w700, color: QSColors.primary,
                  ),
                  hintText: '0',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.w700, color: QSColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter ₹0 if you earned nothing today',
              style: GoogleFonts.inter(fontSize: 12, color: QSColors.textMuted),
            ),

            const SizedBox(height: QSSpacing.xl),

            // ── Pipeline info card ─────────────────────────────────────────
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _PipelineStep(
                    step: '1', label: 'Disruption Verified',
                    detail: 'Live weather/traffic check',
                    color: QSColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _PipelineStep(
                    step: '2', label: 'AI Fraud Analysis',
                    detail: 'GPS + weather + history scored',
                    color: QSColors.orangeVib,
                  ),
                  const SizedBox(height: 12),
                  _PipelineStep(
                    step: '3', label: 'Instant Payout',
                    detail: 'UPI transfer in 1–2 seconds',
                    color: QSColors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.xl),

            // ── Submit button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: QSColors.gradHero),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: QSColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isSubmitting ? null : _submit,
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Submit Claim',
                                  style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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

class _DisruptionOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _DisruptionOption(this.value, this.label, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────

class _PipelineStep extends StatelessWidget {
  final String step;
  final String label;
  final String detail;
  final Color color;

  const _PipelineStep({
    required this.step,
    required this.label,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w800, color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: QSColors.textDark)),
              Text(detail, style: GoogleFonts.inter(fontSize: 11, color: QSColors.textLight)),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, size: 16, color: color.withOpacity(0.6)),
      ],
    );
  }
}
