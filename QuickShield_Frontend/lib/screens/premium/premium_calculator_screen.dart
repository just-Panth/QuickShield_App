import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../widgets/app_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';

class PremiumCalculatorScreen extends StatefulWidget {
  const PremiumCalculatorScreen({super.key});

  @override
  State<PremiumCalculatorScreen> createState() =>
      _PremiumCalculatorScreenState();
}

class _PremiumCalculatorScreenState extends State<PremiumCalculatorScreen> {
  double hours = 8;
  String incomeTier = "Low";
  String season = "Monsoon";
  String zone = "Mid";

  // ── Premium logic ──────────────────────────────────────────────────────────
  double get premium {
    double base = 90;
    double seasonFactor = season == "Monsoon" ? 1.3 : 1.0;
    double zoneFactor = zone == "High" ? 1.2 : 1.0;
    double incomeFactor = incomeTier == "High" ? 1.2 : 1.0;
    return (base * seasonFactor * zoneFactor * incomeFactor).clamp(80, 150);
  }

  String get risk {
    if (premium < 100) return "Low";
    if (premium < 130) return "Medium";
    return "High";
  }

  Color get riskColor {
    switch (risk) {
      case "Low":
        return QSColors.green;
      case "Medium":
        return QSColors.orangeVib;
      default:
        return QSColors.redVib;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      appBar: AppBar(
        title: Text(
          "Risk Configurator",
          style: GoogleFonts.inter(
            color: QSColors.textOnDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            QSSpacing.m, 0, QSSpacing.m, QSSpacing.xxl + 120),
        children: [
          Text(
            "Adjust your profile to calculate\nyour weekly premium.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: QSColors.textOnDarkMid,
              height: 1.6,
            ),
          ),

          const SizedBox(height: QSSpacing.m),

          // ── Result Circular Gauge Card (Dark floating variant) ────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: QSColors.cardDark,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: QSColors.borderDark, width: 1),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    color: riskColor.withOpacity(0.12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: AnimatedTheme(
                          data: ThemeData(
                            colorScheme:
                                ColorScheme.fromSeed(seedColor: riskColor),
                          ),
                          child: CircularProgressIndicator(
                            value: (premium - 80) / 70,
                            strokeWidth: 12,
                            backgroundColor: QSColors.borderDark,
                            color: riskColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            "₹${premium.toStringAsFixed(0)}",
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -2,
                            ),
                          ),
                          Text(
                            "/ week",
                            style: GoogleFonts.inter(
                              color: QSColors.textOnDarkMid,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: riskColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: riskColor.withOpacity(0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$risk risk",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Hours slider ───────────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Daily work hours",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: QSColors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: QSColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: QSColors.border, width: 1),
                      ),
                      child: Text(
                        "${hours.toInt()} hrs",
                        style: GoogleFonts.inter(
                          color: QSColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: QSColors.primary,
                    inactiveTrackColor: QSColors.border,
                    thumbColor: Colors.white,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayColor: QSColors.primary.withOpacity(0.15),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 24),
                  ),
                  child: Slider(
                    value: hours,
                    min: 4,
                    max: 14,
                    divisions: 10,
                    onChanged: (v) => setState(() => hours = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("4h",
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: QSColors.textMuted)),
                      Text("14h",
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: QSColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Segmented controls ─────────────────────────────────────────
          _SegmentedCard(
            title: "Income tier",
            options: const ["Low", "Mid", "High"],
            selected: incomeTier,
            onChanged: (v) => setState(() => incomeTier = v),
          ),

          _SegmentedCard(
            title: "Season",
            options: const ["Monsoon", "Summer", "Winter"],
            selected: season,
            onChanged: (v) => setState(() => season = v),
          ),

          _SegmentedCard(
            title: "Zone risk",
            options: const ["Low", "Mid", "High"],
            selected: zone,
            onChanged: (v) => setState(() => zone = v),
          ),

          const SizedBox(height: QSSpacing.m),

          // ── CTA ─────────────────────────────────────────────────────
          _GradientCTA(onTap: () async {
            final token = context.read<AuthProvider>().token;
            if (token == null) return;

            // Map the frontend 'season' or 'config' to backend plan types
            // For now just pick 'daily_income_shield' and pass 1 wk
            String plan = 'daily_income_shield';
            if (season == 'Monsoon') plan = 'monsoon_surge_cover';

            try {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()));

              await ApiService.instance.post(
                  '/policy/purchase',
                  {
                    'plan_type': plan,
                    'duration_weeks': 1,
                    'premium_inr': premium
                  },
                  token);

              Navigator.pop(context); // pop dialog
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Protection Activated! Dashboard updated.'),
                  backgroundColor: QSColors.green));
              // Do NOT pop the Navigator again, since we are inside `AppShell` and that breaks the stack!
            } catch (e) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Failed to activate: $e'),
                  backgroundColor: QSColors.red));
            }
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GradientCTA extends StatefulWidget {
  final VoidCallback onTap;
  const _GradientCTA({required this.onTap});
  @override
  State<_GradientCTA> createState() => _GradientCTAState();
}

class _GradientCTAState extends State<_GradientCTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: QSColors.gradPrimary,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: QSColors.primary.withOpacity(0.40),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                "Activate protection",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SegmentedCard extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentedCard({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: QSColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: QSColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QSColors.border, width: 1),
            ),
            child: Row(
              children: options.map((e) {
                final isSelected = e == selected;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  blurRadius: 16,
                                  color: Colors.black.withOpacity(0.08),
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? QSColors.textDark
                                : QSColors.textLight,
                          ),
                          child: Text(e),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
