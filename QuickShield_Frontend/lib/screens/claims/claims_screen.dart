import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';
import 'claim_filing_sheet.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _claims = [];
  List<dynamic> _activeCoverage = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClaims();
    });
  }

  Future<void> _fetchClaims() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      // Fetch claims and policies in parallel
      final results = await Future.wait([
        ApiService.instance.get('/claim', token),
        ApiService.instance.get('/policy', token),
      ]);
      final claimRes  = results[0];
      final policyRes = results[1];
      if (mounted) {
        setState(() {
          _summary = claimRes['summary'] ?? {};
          _claims  = claimRes['claims']  ?? [];
          // Grab active policies for the filing sheet
          _activeCoverage = (policyRes['active_coverage'] as List? ?? []);
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
                      "Claims",
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: QSColors.textOnDark,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Track your claim status",
                      style: GoogleFonts.inter(
                          fontSize: 14, color: QSColors.textOnDarkMid),
                    ),
                  ],
                ),
                _FileButton(activeCoverage: _activeCoverage),
              ],
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Summary strip (White Cards) ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                      label: "Total",
                      value: "₹${(_summary['total_inr'] as num?)?.toInt() ?? 0}",
                      color: QSColors.primary,
                      glowColor: QSColors.primary),
                ),
                const SizedBox(width: QSSpacing.s),
                Expanded(
                  child: _SummaryChip(
                      label: "Paid",
                      value: "₹${(_summary['paid_inr'] as num?)?.toInt() ?? 0}",
                      color: QSColors.green,
                      glowColor: QSColors.green),
                ),
                const SizedBox(width: QSSpacing.s),
                Expanded(
                  child: _SummaryChip(
                      label: "Pending",
                      value: "₹${(_summary['pending_inr'] as num?)?.toInt() ?? 0}",
                      color: QSColors.orangeVib,
                      glowColor: QSColors.orangeVib),
                ),
              ],
            ),

            const SizedBox(height: QSSpacing.xl),

            const SectionTitle("Recent claims"),
            const SizedBox(height: QSSpacing.s),

            if (_claims.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text("No claims filed yet.",
                    style: GoogleFonts.inter(fontSize: 16, color: QSColors.textLight)),
              )
            else
              ..._claims.map((c) {
                // format date string 
                String dStr = c['created_at'] ?? '';
                if (dStr.length > 10) dStr = dStr.substring(0, 10);
                
                String displayId = (c['id'] as String).substring(0, 8).toUpperCase();
                num amount = c['amount_inr'] ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ClaimCard(
                    id: "CLM-$displayId",
                    amount: "₹${amount.toInt()}",
                    statusIndex: c['status_index'] ?? 0,
                    date: dStr,
                    type: (c['disruption_type'] as String).toUpperCase(),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FileButton extends StatelessWidget {
  final List<dynamic> activeCoverage;
  const _FileButton({required this.activeCoverage});

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
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ClaimFilingSheet(activeCoverage: activeCoverage),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  "File",
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

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color glowColor;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      margin: EdgeInsets.zero,
      glowColor: glowColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: QSColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ClaimCard extends StatelessWidget {
  final String id;
  final String amount;
  final int statusIndex;
  final String date;
  final String type;

  static const List<String> _steps = [
    "Submitted",
    "Verified",
    "Approved",
    "Paid",
  ];

  static const List<IconData> _stepIcons = [
    Icons.upload_file_rounded,
    Icons.fact_check_rounded,
    Icons.verified_rounded,
    Icons.payments_rounded,
  ];

  const _ClaimCard({
    required this.id,
    required this.amount,
    required this.statusIndex,
    required this.date,
    required this.type,
  });

  Color get _statusColor {
    if (statusIndex < 0) return QSColors.redVib;
    if (statusIndex >= 3) return QSColors.green;
    if (statusIndex >= 2) return QSColors.primary;
    return QSColors.orangeVib;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glowColor: _statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.receipt_rounded, size: 24, color: _statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: QSColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: QSColors.textLight),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.inter(
                      color: _statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Timeline ───────────────────────────────────────────────────
          Row(
            children: List.generate(_steps.length, (i) {
              final isActive = i <= statusIndex;
              final isCurrent = i == statusIndex;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _statusColor
                                    : QSColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isCurrent ? 34 : 26,
                          height: isCurrent ? 34 : 26,
                          decoration: BoxDecoration(
                            color: isActive ? _statusColor : QSColors.surface,
                            shape: BoxShape.circle,
                            border: isActive ? null : Border.all(color: QSColors.border, width: 1.5),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      blurRadius: 16,
                                      color: _statusColor.withOpacity(0.5),
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _stepIcons[i],
                            size: isCurrent ? 16 : 12,
                            color: isActive
                                ? Colors.white
                                : QSColors.textMuted,
                          ),
                        ),
                        if (i < _steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: i < statusIndex
                                    ? _statusColor
                                    : QSColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _steps[i],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isActive
                            ? QSColors.textDark
                            : QSColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}