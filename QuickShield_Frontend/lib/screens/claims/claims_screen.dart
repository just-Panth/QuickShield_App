import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                _FileButton(),
              ],
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Summary strip (White Cards) ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryChip(
                      label: "Total",
                      value: "₹850",
                      color: QSColors.primary,
                      glowColor: QSColors.primary),
                ),
                const SizedBox(width: QSSpacing.s),
                Expanded(
                  child: _SummaryChip(
                      label: "Paid",
                      value: "₹350",
                      color: QSColors.green,
                      glowColor: QSColors.green),
                ),
                const SizedBox(width: QSSpacing.s),
                Expanded(
                  child: _SummaryChip(
                      label: "Pending",
                      value: "₹500",
                      color: QSColors.orangeVib,
                      glowColor: QSColors.orangeVib),
                ),
              ],
            ),

            const SizedBox(height: QSSpacing.xl),

            const SectionTitle("Recent claims"),
            const SizedBox(height: QSSpacing.s),

            _ClaimCard(
              id: "CLM-123",
              amount: "₹350",
              statusIndex: 3,
              date: "Today, 10:30 AM",
              type: "Income loss",
            ),

            _ClaimCard(
              id: "CLM-124",
              amount: "₹500",
              statusIndex: 1,
              date: "Yesterday, 3:00 PM",
              type: "Monsoon disruption",
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FileButton extends StatelessWidget {
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