import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'claim_progress_screen.dart';

class ClaimFilingSheet extends StatefulWidget {
  /// Pass active_coverage from the ClaimsScreen so we can grab a policy_id.
  final List<dynamic> activeCoverage;

  const ClaimFilingSheet({super.key, required this.activeCoverage});

  @override
  State<ClaimFilingSheet> createState() => _ClaimFilingSheetState();
}

class _ClaimFilingSheetState extends State<ClaimFilingSheet> {
  int _step = 0; // 0=type, 1=proof, 2=earnings, 3=confirm
  String _disruptionType = '';
  double _earnedToday = 200;
  bool _collectingProof = false;
  String _photoHash = '';
  List<Map<String, dynamic>> _gpsTrail = [];
  List<Map<String, dynamic>> _zAxisTrail = [];

  // ── Step A helpers ─────────────────────────────────────────────────────────
  void _selectType(String type) {
    setState(() {
      _disruptionType = type;
      _step = 1;
    });
    _collectProof();
  }

  // ── Step B — simulate proof collection ────────────────────────────────────
  Future<void> _collectProof() async {
    setState(() => _collectingProof = true);

    // Simulated GPS trail (3 waypoints near Bangalore South)
    await Future.delayed(const Duration(milliseconds: 800));
    final now = DateTime.now();
    _gpsTrail = [
      {'lat': 12.9165, 'lng': 77.6010, 'timestamp': now.subtract(const Duration(minutes: 10)).toIso8601String()},
      {'lat': 12.9172, 'lng': 77.6025, 'timestamp': now.subtract(const Duration(minutes: 5)).toIso8601String()},
      {'lat': 12.9180, 'lng': 77.6031, 'timestamp': now.toIso8601String()},
    ];

    // Simulated Z-axis (altitude) data
    _zAxisTrail = [
      {'altitude_m': 900.0, 'timestamp': now.subtract(const Duration(minutes: 10)).toIso8601String()},
      {'altitude_m': 902.4, 'timestamp': now.toIso8601String()},
    ];

    // Photo hash: sha256(timestamp + workerId)
    final auth = context.read<AuthProvider>();
    final raw = '${now.toIso8601String()}${auth.token ?? 'qs'}';
    _photoHash = sha256.convert(utf8.encode(raw)).toString();

    setState(() => _collectingProof = false);
  }

  // ── Submit claim ──────────────────────────────────────────────────────────
  void _submit() {
    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null) return;
    if (widget.activeCoverage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active policy found. Purchase a plan first.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final policyId = widget.activeCoverage.first['policy_id'];

    final future = ApiService.instance.post('/claim/submit', {
      'policy_id':        policyId,
      'disruption_type':  _disruptionType,
      'gps_trail':        _gpsTrail,
      'z_axis_trail':     _zAxisTrail,
      'photo_hash':       _photoHash,
      'earned_today_inr': _earnedToday.round(),
    }, token);

    Navigator.pop(context); // close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClaimProgressScreen(claimFuture: future),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Step indicator
          _StepIndicator(currentStep: _step),
          const SizedBox(height: 28),

          // Step content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:  return _buildTypeStep();
      case 1:  return _buildProofStep();
      case 2:  return _buildEarningsStep();
      case 3:  return _buildConfirmStep();
      default: return const SizedBox.shrink();
    }
  }

  // ── Step A: Disruption Type ───────────────────────────────────────────────
  Widget _buildTypeStep() {
    return Column(
      key: const ValueKey('step-type'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What caused the disruption?',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Select the type of disruption that affected your work',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
        const SizedBox(height: 24),
        Row(
          children: [
            _TypeCard(icon: '🌧', label: 'Weather',  onTap: () => _selectType('weather')),
            const SizedBox(width: 12),
            _TypeCard(icon: '🚗', label: 'Traffic',  onTap: () => _selectType('traffic')),
            const SizedBox(width: 12),
            _TypeCard(icon: '🎉', label: 'Event',    onTap: () => _selectType('event')),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step B: Proof Collection ──────────────────────────────────────────────
  Widget _buildProofStep() {
    return Column(
      key: const ValueKey('step-proof'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Collecting proof...',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 24),
        _ProofTile(
          icon: Icons.location_on,
          label: 'GPS trail',
          done: !_collectingProof && _gpsTrail.isNotEmpty,
          loading: _collectingProof,
        ),
        const SizedBox(height: 12),
        _ProofTile(
          icon: Icons.photo_camera,
          label: 'Photo hash',
          done: !_collectingProof && _photoHash.isNotEmpty,
          loading: _collectingProof,
        ),
        const SizedBox(height: 12),
        _ProofTile(
          icon: Icons.sensors,
          label: 'Z-axis sensor',
          done: !_collectingProof && _zAxisTrail.isNotEmpty,
          loading: _collectingProof,
        ),
        const SizedBox(height: 28),
        AnimatedOpacity(
          opacity: _collectingProof ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _collectingProof ? null : () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: QSColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Continue', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step C: Earnings Input ────────────────────────────────────────────────
  Widget _buildEarningsStep() {
    return Column(
      key: const ValueKey('step-earnings'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How much did you earn today?',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Enter what you earned before the disruption stopped your work',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white54)),
        const SizedBox(height: 32),
        Center(
          child: Text(
            '₹${_earnedToday.round()}',
            style: GoogleFonts.inter(
              fontSize: 48, fontWeight: FontWeight.w900,
              color: QSColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: QSColors.primary,
            inactiveTrackColor: Colors.white12,
            thumbColor: QSColors.primary,
            overlayColor: QSColors.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: _earnedToday,
            min: 0,
            max: 1000,
            divisions: 100,
            onChanged: (v) => setState(() => _earnedToday = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₹0', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            Text('₹1,000', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 3),
            style: ElevatedButton.styleFrom(
              backgroundColor: QSColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Review Claim', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step D: Confirm & Submit ──────────────────────────────────────────────
  Widget _buildConfirmStep() {
    return Column(
      key: const ValueKey('step-confirm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your claim',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Disruption type', value: _disruptionType.toUpperCase()),
              const SizedBox(height: 12),
              _SummaryRow(label: 'GPS waypoints collected', value: '${_gpsTrail.length} points'),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Photo hash', value: _photoHash.substring(0, 12) + '...'),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Earned before disruption', value: '₹${_earnedToday.round()}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: QSColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QSColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: QSColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your payout = ⅔ of your avg daily earnings − what you earned today',
                  style: GoogleFonts.inter(fontSize: 13, color: QSColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: QSColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Submit Claim', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 0),
            child: Text('Start over', style: GoogleFonts.inter(color: Colors.white38)),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = ['Type', 'Proof', 'Earnings', 'Confirm'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active  = i == currentStep;
        final done    = i < currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                          ? Colors.green
                          : active
                            ? QSColors.primary
                            : Colors.white12,
                      ),
                      child: Center(
                        child: done
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text('${i + 1}',
                              style: TextStyle(
                                color: active ? Colors.white : Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              )),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: active ? QSColors.primary : Colors.white38,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      )),
                  ],
                ),
              ),
              if (i < labels.length - 1)
                Container(width: 20, height: 1, color: Colors.white12),
            ],
          ),
        );
      }),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _TypeCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(label,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final bool loading;
  const _ProofTile({required this.icon, required this.label, required this.done, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done
          ? Colors.green.withOpacity(0.08)
          : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done ? Colors.green.withOpacity(0.3) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: done ? Colors.green : Colors.white38, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
            style: GoogleFonts.inter(color: done ? Colors.white : Colors.white60, fontSize: 15))),
          if (loading)
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
            )
          else if (done)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            const Icon(Icons.schedule, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
        Text(value,  style: GoogleFonts.inter(color: Colors.white,   fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
