import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/claim_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMsg;
  Map<String, dynamic>? _data;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final data = await ClaimService.instance.fetchAdminDashboard(token);
      if (mounted) {
        setState(() {
          _data      = data;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg  = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
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
          'Admin Dashboard',
          style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: QSColors.textOnDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: QSColors.textOnDarkMid),
            onPressed: () {
              setState(() => _isLoading = true);
              _fadeController.reset();
              _fetchData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: QSColors.primary))
          : _errorMsg != null
              ? _ErrorView(message: _errorMsg!)
              : FadeTransition(
                  opacity: _fadeController,
                  child: _buildDashboard(),
                ),
    );
  }

  Widget _buildDashboard() {
    final claims      = _data!['claims']     as Map<String, dynamic>? ?? {};
    final fraud       = _data!['fraud']      as Map<String, dynamic>? ?? {};
    final financials  = _data!['financials'] as Map<String, dynamic>? ?? {};
    final workforce   = _data!['workforce']  as Map<String, dynamic>? ?? {};
    final prediction  = _data!['prediction'] as Map<String, dynamic>? ?? {};
    final recentClaims = _data!['recent_claims'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          QSSpacing.m, QSSpacing.s, QSSpacing.m, QSSpacing.xxl),
      children: [
        // ── Hero stats row ──────────────────────────────────────────────
        const SectionTitle('Overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'Total Claims',
              value: '${claims['total'] ?? 0}',
              icon: Icons.receipt_long_rounded,
              color: QSColors.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Fraud Rate',
              value: '${((fraud['detection_rate'] as num? ?? 0) * 100).toStringAsFixed(1)}%',
              icon: Icons.gpp_bad_rounded,
              color: QSColors.redVib,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Loss Ratio',
              value: '${financials['loss_ratio'] ?? 0}x',
              icon: Icons.balance_rounded,
              color: QSColors.orangeVib,
            )),
          ],
        ),

        const SizedBox(height: QSSpacing.m),

        // ── Financial strip ─────────────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _FinancialCell(
                label: 'Total Payout',
                value: '₹${_fmt(financials['total_payout_inr'])}',
                color: QSColors.green,
              )),
              _divider(),
              Expanded(child: _FinancialCell(
                label: 'Premium Collected',
                value: '₹${_fmt(financials['total_premium_collected'])}',
                color: QSColors.primary,
              )),
              _divider(),
              Expanded(child: _FinancialCell(
                label: 'Active Workers',
                value: '${workforce['total_workers'] ?? 0}',
                color: QSColors.blue,
              )),
            ],
          ),
        ),

        const SizedBox(height: QSSpacing.m),

        // ── Claim funnel bar chart ───────────────────────────────────────
        const SectionTitle('Claim Funnel'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxClaimVal(claims).toDouble() + 2,
                barGroups: [
                  _barGroup(0, (claims['approved'] as num?)?.toDouble() ?? 0, QSColors.green),
                  _barGroup(1, (claims['review']   as num?)?.toDouble() ?? 0, QSColors.orangeVib),
                  _barGroup(2, (claims['rejected'] as num?)?.toDouble() ?? 0, QSColors.redVib),
                  _barGroup(3, (claims['pending']  as num?)?.toDouble() ?? 0, QSColors.primary),
                ],
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                ),
                titlesData: FlTitlesData(
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = ['Paid', 'Review', 'Rejected', 'Pending'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[v.toInt()],
                            style: GoogleFonts.inter(fontSize: 10, color: QSColors.textLight),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: QSSpacing.m),

        // ── Fraud breakdown ──────────────────────────────────────────────
        const SectionTitle('Fraud Intelligence'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              label: 'Avg Fraud Score',
              value: '${fraud['avg_fraud_score'] ?? 0}',
              icon: Icons.analytics_rounded,
              color: QSColors.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Flagged',
              value: '${fraud['flagged'] ?? 0}',
              icon: Icons.flag_rounded,
              color: QSColors.orangeVib,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: 'Auto-Rejected',
              value: '${fraud['auto_rejected'] ?? 0}',
              icon: Icons.block_rounded,
              color: QSColors.redVib,
            )),
          ],
        ),

        const SizedBox(height: QSSpacing.m),

        // ── Predictive analytics ─────────────────────────────────────────
        const SectionTitle('Next Week Prediction'),
        const SizedBox(height: 12),
        AppCard(
          glowColor: QSColors.primary,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: QSColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: QSColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Prediction Model',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: QSColors.textDark),
                      ),
                      Text(
                        prediction['based_on']?.toString() ?? '—',
                        style: GoogleFonts.inter(fontSize: 11, color: QSColors.textLight),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PredictionChip(
                      label: 'Predicted Claims',
                      value: '${prediction['predicted_claims'] ?? 0}',
                      color: QSColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PredictionChip(
                      label: 'Predicted Payout',
                      value: '₹${_fmt(prediction['predicted_payout_inr'])}',
                      color: QSColors.orangeVib,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Confidence bar
              Row(
                children: [
                  Text(
                    'Confidence',
                    style: GoogleFonts.inter(fontSize: 12, color: QSColors.textLight),
                  ),
                  const Spacer(),
                  Text(
                    '${((prediction['confidence'] as num? ?? 0) * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: QSColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (prediction['confidence'] as num?)?.toDouble() ?? 0,
                  color: QSColors.primary,
                  backgroundColor: QSColors.primary.withOpacity(0.1),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: QSSpacing.m),

        // ── Recent claims ────────────────────────────────────────────────
        const SectionTitle('Recent Claims'),
        const SizedBox(height: 12),
        ...recentClaims.map((c) => _RecentClaimRow(claim: c)),
      ],
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 30,
            color: color.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  int _maxClaimVal(Map<String, dynamic> claims) {
    final vals = [
      claims['approved'] ?? 0,
      claims['review']   ?? 0,
      claims['rejected'] ?? 0,
      claims['pending']  ?? 0,
    ].map((v) => (v as num).toInt());
    return vals.isEmpty ? 10 : vals.reduce((a, b) => a > b ? a : b);
  }

  Widget _divider() => Container(width: 1, height: 40, color: QSColors.border);

  String _fmt(dynamic val) {
    if (val == null) return '0';
    final n = (val as num).toInt();
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000)   return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: QSColors.textLight)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FinancialCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinancialCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: QSColors.textLight)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PredictionChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PredictionChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: QSColors.textLight)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RecentClaimRow extends StatelessWidget {
  final dynamic claim;
  const _RecentClaimRow({required this.claim});

  Color _verdictColor(String? v) {
    if (v == 'AUTO_APPROVE') return QSColors.green;
    if (v == 'FLAG_FOR_REVIEW') return QSColors.orangeVib;
    if (v == 'REJECT') return QSColors.redVib;
    return QSColors.textLight;
  }

  @override
  Widget build(BuildContext context) {
    final score   = (claim['fraud_score'] as num?)?.toInt() ?? 0;
    final verdict = claim['fraud_verdict'] as String?;
    final status  = claim['status'] as String? ?? '—';
    final amount  = (claim['amount_inr'] as num?)?.toInt() ?? 0;
    final id      = (claim['id'] as String? ?? '--------').substring(0, 8).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Fraud score badge
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _verdictColor(verdict).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: _verdictColor(verdict)),
                  ),
                  Text('risk', style: GoogleFonts.inter(fontSize: 8, color: QSColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CLM-$id', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: QSColors.textDark)),
                  Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, color: QSColors.textLight)),
                ],
              ),
            ),
            Text(
              amount > 0 ? '₹$amount' : '—',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: QSColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, size: 64, color: QSColors.textMuted),
            const SizedBox(height: 20),
            Text('Admin Access Required', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: QSColors.textOnDark)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: QSColors.textLight)),
          ],
        ),
      ),
    );
  }
}
