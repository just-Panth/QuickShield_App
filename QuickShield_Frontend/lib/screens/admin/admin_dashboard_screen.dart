import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final res = await ApiService.instance.get('/admin/overview', token);
      if (mounted) setState(() { _data = res; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF59E0B);
    return Scaffold(
      backgroundColor: QSColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          color: amber,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                      QSSpacing.m, QSSpacing.m, QSSpacing.m, 120),
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded,
                              color: amber, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Dashboard',
                                style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: QSColors.textOnDark,
                                    letterSpacing: -0.6)),
                            Text('Real-time overview',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: QSColors.textOnDarkMid)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: QSSpacing.l),

                    // ── KPI Cards ────────────────────────────────────────
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _KpiCard(
                            label: 'Total Workers',
                            value: '${_data['total_workers'] ?? 0}',
                            icon: Icons.groups_rounded,
                            color: QSColors.primary,
                          ),
                          const SizedBox(width: QSSpacing.s),
                          _KpiCard(
                            label: 'Active Policies',
                            value: '${_data['active_policies'] ?? 0}',
                            icon: Icons.verified_rounded,
                            color: QSColors.green,
                          ),
                          const SizedBox(width: QSSpacing.s),
                          _KpiCard(
                            label: "Week's Payout",
                            value: '₹${_data['payout_this_week_inr'] ?? 0}',
                            icon: Icons.payments_rounded,
                            color: amber,
                          ),
                          const SizedBox(width: QSSpacing.s),
                          _KpiCard(
                            label: 'Fraud Blocked',
                            value: '${_data['fraud_blocked_count'] ?? 0}',
                            icon: Icons.shield_rounded,
                            color: QSColors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: QSSpacing.l),

                    // ── Loss Ratio Gauge ─────────────────────────────────
                    AppCard(
                      glowColor: amber,
                      child: Row(
                        children: [
                          _LossRatioGauge(lossRatio: (_data['loss_ratio'] as num?)?.toDouble() ?? 0),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Loss Ratio',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: QSColors.textDark)),
                                const SizedBox(height: 6),
                                Text(
                                  '${(_data['loss_ratio'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                                  style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: _lossRatioColor(_data['loss_ratio']),
                                      letterSpacing: -1),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lossRatioLabel(_data['loss_ratio']),
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: _lossRatioColor(_data['loss_ratio'])),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Total paid: ₹${_data['total_payout_inr'] ?? 0}',
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

                    // ── Zone Risk ────────────────────────────────────────
                    Text('Zone Risk Map',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: QSColors.textOnDarkMid,
                            letterSpacing: 0.8)),
                    const SizedBox(height: QSSpacing.s),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: _buildZoneRiskList(),
                      ),
                    ),

                    const SizedBox(height: QSSpacing.l),

                    // ── Recent Claims Feed ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Claims',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: QSColors.textOnDarkMid,
                                letterSpacing: 0.8)),
                        GestureDetector(
                          onTap: () {},
                          child: Text('See all',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: amber,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: QSSpacing.s),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: _buildRecentClaims(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _lossRatioColor(dynamic ratio) {
    final r = (ratio as num?)?.toDouble() ?? 0;
    if (r < 40) return QSColors.green;
    if (r < 70) return const Color(0xFFF59E0B);
    return QSColors.red;
  }

  String _lossRatioLabel(dynamic ratio) {
    final r = (ratio as num?)?.toDouble() ?? 0;
    if (r < 40) return '✅ Healthy margin';
    if (r < 70) return '⚠️ Monitor closely';
    return '🚨 Critical — above threshold';
  }

  List<Widget> _buildZoneRiskList() {
    final zoneMap = _data['zone_risk_map'] as Map<String, dynamic>? ?? {};
    final zones = ['BLR-SOUTH', 'BLR-NORTH', 'MUM-CENTRAL', 'DEFAULT'];
    return zones.map((zone) {
      final score = (zoneMap[zone] as num?)?.toInt() ?? 0;
      Color badgeColor;
      String level;
      if (score >= 70) { badgeColor = QSColors.red;    level = 'HIGH'; }
      else if (score >= 40) { badgeColor = const Color(0xFFF59E0B); level = 'MED'; }
      else { badgeColor = QSColors.green; level = 'LOW'; }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(blurRadius: 6, color: badgeColor.withOpacity(0.5))],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(zone,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: QSColors.textDark)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$level  $score%',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor)),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecentClaims() {
    final claims = _data['recent_claims'] as List<dynamic>? ?? [];
    if (claims.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
              child: Text('No claims yet',
                  style: GoogleFonts.inter(color: QSColors.textLight))),
        )
      ];
    }
    return claims.take(8).map((c) {
      final status = c['status'] as String? ?? 'pending';
      final worker = c['workers'] as Map<String, dynamic>?;
      Color statusColor;
      switch (status) {
        case 'paid': statusColor = QSColors.green; break;
        case 'rejected': statusColor = QSColors.red; break;
        default: statusColor = const Color(0xFFF59E0B);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  shape: BoxShape.circle),
              child: Icon(
                status == 'paid'
                    ? Icons.check_circle_rounded
                    : status == 'rejected'
                        ? Icons.cancel_rounded
                        : Icons.hourglass_top_rounded,
                color: statusColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker?['full_name'] ?? 'Unknown Worker',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: QSColors.textDark)),
                  Text(
                    '${(c['disruption_type'] as String? ?? 'claim').toUpperCase()} · ${worker?['zone_id'] ?? ''}',
                    style: GoogleFonts.inter(fontSize: 11, color: QSColors.textLight)),
                ],
              ),
            ),
            Text(
              '₹${c['amount_inr'] ?? 0}',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w800, color: statusColor),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QSColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(blurRadius: 16, color: color.withOpacity(0.08), offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: QSColors.textDark,
                  letterSpacing: -0.5)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: QSColors.textLight)),
        ],
      ),
    );
  }
}

class _LossRatioGauge extends StatelessWidget {
  final double lossRatio;
  const _LossRatioGauge({required this.lossRatio});

  Color get _color {
    if (lossRatio < 40) return QSColors.green;
    if (lossRatio < 70) return const Color(0xFFF59E0B);
    return QSColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (lossRatio / 100).clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: QSColors.surface,
            valueColor: AlwaysStoppedAnimation(_color),
          ),
          Text(
            '${lossRatio.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w900, color: _color),
          ),
        ],
      ),
    );
  }
}
