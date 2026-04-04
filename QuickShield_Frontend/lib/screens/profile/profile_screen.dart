import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:quickshield_app/providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  int _totalSaved = 0;
  String _memberSince = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final meRes = await ApiService.instance.get('/auth/me', token);
      final claimRes = await ApiService.instance.get('/claim', token);
      
      if (mounted) {
        setState(() {
          _totalSaved = (claimRes['summary']?['paid_inr'] as num?)?.toInt() ?? 0;
          
          String dateStr = meRes['worker']?['onboarded_at'] ?? meRes['worker']?['created_at'] ?? "";
          if (dateStr.length >= 10) {
            final d = DateTime.tryParse(dateStr);
            if (d != null) {
              final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              _memberSince = "${months[d.month - 1]} ${d.year}";
            }
          }
          if (_memberSince.isEmpty) _memberSince = "Today";
          
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
            Text(
              "Profile",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: QSColors.textOnDark,
                letterSpacing: -0.8,
              ),
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Avatar card (White) ──────────────────────────────────────
            AppCard(
              glowColor: QSColors.primary,
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: QSColors.gradHero,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 20,
                              color: QSColors.primary.withOpacity(0.40),
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 36),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: QSColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: QSColors.card, width: 3),
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.watch<AuthProvider>().userProfile.workerId ?? context.watch<AuthProvider>().fullName ?? "Worker",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: QSColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.watch<AuthProvider>().userData.email ?? "No Email",
                          style: GoogleFonts.inter(
                              fontSize: 14, color: QSColors.textLight),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: QSColors.greenLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 14, color: QSColors.green),
                              const SizedBox(width: 6),
                              Text(
                                "Verified worker",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: QSColors.green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: QSColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: QSColors.border),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 20, color: QSColors.textMid),
                  ),
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Stats row ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: "Member since",
                    value: _memberSince,
                    icon: Icons.calendar_today_rounded,
                    iconColor: QSColors.primary,
                  ),
                ),
                const SizedBox(width: QSSpacing.s),
                Expanded(
                  child: _StatChip(
                    label: "Total saved",
                    value: "₹$_totalSaved",
                    icon: Icons.savings_rounded,
                    iconColor: QSColors.orangeVib,
                  ),
                ),
              ],
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Menu sections ────────────────────────────────────────────
            _SectionLabel("Account"),
            const SizedBox(height: QSSpacing.s),

            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: QSColors.primary,
                    label: "Personal details",
                    subtitle: "Name, ID, phone",
                  ),
                  Divider(height: 1, color: QSColors.border.withOpacity(0.5), indent: 72),
                  _MenuItem(
                    icon: Icons.receipt_long_rounded,
                    iconColor: QSColors.green,
                    label: "Billing & payments",
                    subtitle: "UPI, bank account",
                  ),
                  Divider(height: 1, color: QSColors.border.withOpacity(0.5), indent: 72),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    iconColor: QSColors.orangeVib,
                    label: "Notifications",
                    subtitle: "Claims, alerts, reminders",
                  ),
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.m),

            _SectionLabel("Support"),
            const SizedBox(height: QSSpacing.s),

            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: QSColors.blue,
                    label: "Help & FAQ",
                    subtitle: "Common questions",
                  ),
                  Divider(height: 1, color: QSColors.border.withOpacity(0.5), indent: 72),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: QSColors.primary,
                    label: "Contact support",
                    subtitle: "Chat, email, call",
                  ),
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.xl),

            // ── Logout ───────────────────────────────────────────────────
            GestureDetector(
              onTap: () => context.read<AuthProvider>().logout(),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: QSColors.redLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: QSColors.red.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 20, color: QSColors.red),
                    const SizedBox(width: 10),
                    Text(
                      "Sign out",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: QSColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: QSSpacing.xl),

            Center(
              child: Text(
                "QuickShield v1.0.0  ·  IRDAI Reg. No. 12345",
                style: GoogleFonts.inter(
                    fontSize: 12, color: QSColors.textOnDarkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: QSColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12, color: QSColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: QSColors.textOnDarkMid,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: QSColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: QSColors.textLight),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 24, color: QSColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}