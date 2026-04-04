import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  bool _isLoading = true;
  List<dynamic> _policies = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPolicies();
    });
  }

  Future<void> _fetchPolicies() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final res = await ApiService.instance.get('/policy', token);
      if (mounted) {
        setState(() {
          _policies = res['policies'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: QSColors.bg,
        body: Center(child: CircularProgressIndicator(color: QSColors.primary)),
      );
    }

    double totalWeeklyPremium = 0;
    for (var p in _policies) {
      if (p['status'] == 'active') {
        totalWeeklyPremium += (p['premium_inr'] ?? 0);
      }
    }

    return Scaffold(
      backgroundColor: QSColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              QSSpacing.m, QSSpacing.m, QSSpacing.m, QSSpacing.xxl + 40),
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Policies",
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: QSColors.textOnDark,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_policies.where((p) => p['status'] == 'active').length} active policies",
                      style: GoogleFonts.inter(
                          fontSize: 14, color: QSColors.textOnDarkMid),
                    ),
                  ],
                ),
                const _AddButton(label: "Add New"),
              ],
            ),

            const SizedBox(height: QSSpacing.l),

            const SectionTitle("Active Policies"),
            const SizedBox(height: QSSpacing.s),

            if (_policies.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text("No policies found.",
                    style: GoogleFonts.inter(fontSize: 16, color: QSColors.textLight)),
              )
            else
              ..._policies.map((p) {
                Color color = QSColors.green;
                IconData ic = Icons.flash_on_rounded;
                String subtitle = "Income protection";
                
                if (p['plan_type'] == 'monsoon_surge_cover') {
                  color = QSColors.orangeVib;
                  ic = Icons.water_drop_rounded;
                  subtitle = "Weather-based income protection";
                } else if (p['plan_type'] == 'traffic_disruption') {
                  color = QSColors.redVib;
                  ic = Icons.car_crash_rounded;
                  subtitle = "Traffic block protection";
                } else {
                  color = QSColors.blue;
                  subtitle = "Covers daily income loss";
                }

                if (p['status'] != 'active') {
                  color = QSColors.textMuted;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PolicyCard(
                    title: (p['plan_type'] as String).replaceAll('_', ' ').toUpperCase(),
                    subtitle: subtitle,
                    amount: "₹${p['premium_inr']}/week",
                    status: (p['status'] as String).toUpperCase(),
                    statusColor: color,
                    icon: ic,
                    glowColor: color,
                  ),
                );
              }),

            const SizedBox(height: QSSpacing.l),

            const SectionTitle("Coverage Summary"),
            const SizedBox(height: QSSpacing.s),

            AppCard(
              child: Column(
                children: [
                  _SummaryRow(
                    label: "Total weekly premium",
                    value: "₹${totalWeeklyPremium.toInt()} / week",
                    valueColor: QSColors.textDark,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  const _SummaryRow(
                    label: "Max weekly payout",
                    value: "₹1,400",
                    valueColor: QSColors.primary,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  _SummaryRow(
                    label: "Total policies history",
                    value: "${_policies.length} logged",
                    valueColor: QSColors.textMid,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String label;
  const _AddButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QSColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: QSColors.primary.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PolicyCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color glowColor;

  const _PolicyCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glowColor: glowColor,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Color indicator top strip
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 24, color: statusColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: QSColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: QSColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: QSColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: QSColors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments_rounded,
                              size: 16, color: QSColors.textMid),
                          const SizedBox(width: 8),
                          Text(
                            amount,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: QSColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 14, color: QSColors.textLight, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}