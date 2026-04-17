import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class AdminClaimDetailScreen extends StatefulWidget {
  final String claimId;
  const AdminClaimDetailScreen({super.key, required this.claimId});

  @override
  State<AdminClaimDetailScreen> createState() => _AdminClaimDetailScreenState();
}

class _AdminClaimDetailScreenState extends State<AdminClaimDetailScreen> {
  bool _loading = true;
  bool _approving = false;
  Map<String, dynamic> _claim = {};

  static const _amber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final res = await ApiService.instance.get('/admin/claims/${widget.claimId}', token);
      if (mounted) setState(() { _claim = res['claim'] ?? {}; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _approving = true);
    try {
      await ApiService.instance.post(
        '/admin/claims/${widget.claimId}/approve', {}, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Claim manually approved'),
          backgroundColor: QSColors.green,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: QSColors.red,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _approving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: QSColors.bg,
        body: Center(child: CircularProgressIndicator(color: _amber)),
      );
    }

    final status   = _claim['status'] as String? ?? '';
    final worker   = _claim['workers'] as Map<String, dynamic>? ?? {};
    final gates    = _claim['gate_results'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: QSColors.bg,
      appBar: AppBar(
        backgroundColor: QSColors.bg,
        elevation: 0,
        leading: BackButton(color: QSColors.textOnDark),
        title: Text('Claim Audit Trail',
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w800, color: QSColors.textOnDark)),
        actions: [
          if (status != 'paid')
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _approving ? null : _approve,
                icon: _approving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _amber))
                    : const Icon(Icons.check_rounded, color: _amber, size: 18),
                label: Text('Approve',
                    style: GoogleFonts.inter(
                        color: _amber, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSSpacing.m, 0, QSSpacing.m, 40),
        children: [
          // Worker info
          AppCard(
            glowColor: _amber,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _amber.withOpacity(0.15),
                  radius: 24,
                  child: Text(
                    (worker['full_name'] as String? ?? 'W')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w900, color: _amber),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker['full_name'] ?? 'Unknown',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w800,
                              color: QSColors.textDark)),
                      Text('${worker['email'] ?? ''} · ${worker['zone_id'] ?? ''}',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: QSColors.textLight)),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),

          const SizedBox(height: QSSpacing.m),

          // Claim info row
          Row(
            children: [
              Expanded(child: _InfoTile(label: 'Disruption', value: (_claim['disruption_type'] as String? ?? '—').toUpperCase())),
              const SizedBox(width: 8),
              Expanded(child: _InfoTile(label: 'Payout', value: '₹${_claim['amount_inr'] ?? 0}', highlight: true)),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: _InfoTile(label: 'Earned Today', value: '₹${_claim['earned_today_inr'] ?? 0}')),
              const SizedBox(width: 8),
              Expanded(child: _InfoTile(
                  label: 'Claim ID',
                  value: (widget.claimId).substring(0, 8).toUpperCase(),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.claimId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Copied!'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1)));
                  })),
            ],
          ),

          const SizedBox(height: QSSpacing.l),

          Text('GATE AUDIT TRAIL',
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: QSColors.textOnDarkMid, letterSpacing: 1.2)),
          const SizedBox(height: QSSpacing.s),

          // Gate 1
          _GateCard(
            gateNumber: 1,
            title: 'Parametric Trigger',
            subtitle: 'Disruption detection',
            gateData: gates['gate1'] as Map<String, dynamic>? ?? {},
          ),
          const SizedBox(height: QSSpacing.s),

          // Gate 2
          _GateCard(
            gateNumber: 2,
            title: 'Anti-Fraud Engine',
            subtitle: '6-layer fraud detection',
            gateData: gates['gate2'] as Map<String, dynamic>? ?? {},
          ),
          const SizedBox(height: QSSpacing.s),

          // Gate 3
          _GateCard(
            gateNumber: 3,
            title: 'Payout Calculation',
            subtitle: 'UPI disbursement',
            gateData: gates['gate3'] as Map<String, dynamic>? ?? {},
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case 'paid': c = QSColors.green; break;
      case 'rejected': c = QSColors.red; break;
      default: c = const Color(0xFFF59E0B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(status.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w800, color: c)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onTap;
  const _InfoTile({required this.label, required this.value, this.highlight = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(fontSize: 11, color: QSColors.textLight)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: highlight ? QSColors.green : QSColors.textDark)),
          ],
        ),
      ),
    );
  }
}

class _GateCard extends StatefulWidget {
  final int gateNumber;
  final String title;
  final String subtitle;
  final Map<String, dynamic> gateData;
  const _GateCard({
    required this.gateNumber,
    required this.title,
    required this.subtitle,
    required this.gateData,
  });
  @override
  State<_GateCard> createState() => _GateCardState();
}

class _GateCardState extends State<_GateCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final passed = widget.gateData['passed'] as bool? ?? false;
    final reason = widget.gateData['reason'] as String? ?? '';
    final layers = widget.gateData['layers'] as Map<String, dynamic>?;
    final color  = passed ? QSColors.green : QSColors.red;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text('G${widget.gateNumber}',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w900, color: color)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: QSColors.textDark)),
                        Text(widget.subtitle,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: QSColors.textLight)),
                      ],
                    ),
                  ),
                  Icon(passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: color, size: 22),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: QSColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: QSColors.border.withOpacity(0.4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reason,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: QSColors.textMid)),
                  if (layers != null) ...[
                    const SizedBox(height: 12),
                    ...layers.entries.map((e) {
                      final layerPassed = (e.value as Map<String, dynamic>?)?['passed'] as bool? ?? false;
                      final detail      = (e.value as Map<String, dynamic>?)?['detail'] as String? ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              layerPassed ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                              size: 14,
                              color: layerPassed ? QSColors.green : QSColors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${e.key}: $detail',
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: QSColors.textLight)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
