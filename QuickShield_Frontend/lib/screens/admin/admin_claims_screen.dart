import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';
import 'admin_claim_detail_screen.dart';

class AdminClaimsScreen extends StatefulWidget {
  const AdminClaimsScreen({super.key});

  @override
  State<AdminClaimsScreen> createState() => _AdminClaimsScreenState();
}

class _AdminClaimsScreenState extends State<AdminClaimsScreen> {
  bool _loading = true;
  List<dynamic> _claims = [];
  String _selectedStatus = 'all';

  static const _amber = Color(0xFFF59E0B);
  static const _filters = ['all', 'submitted', 'paid', 'rejected'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance
          .get('/admin/claims?status=$_selectedStatus&limit=50', token);
      if (mounted) {
        setState(() {
          _claims = res['claims'] as List<dynamic>? ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(QSSpacing.m, QSSpacing.m, QSSpacing.m, 0),
              child: Text('All Claims',
                  style: GoogleFonts.inter(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: QSColors.textOnDark, letterSpacing: -0.7)),
            ),
            const SizedBox(height: QSSpacing.m),

            // ── Filter chips ─────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: QSSpacing.m),
                children: _filters.map((f) {
                  final selected = f == _selectedStatus;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStatus = f);
                      _fetch();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _amber : QSColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? _amber
                                : QSColors.border.withOpacity(0.5)),
                      ),
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : QSColors.textMid),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: QSSpacing.m),

            // ── Claims list ──────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _amber))
                  : _claims.isEmpty
                      ? Center(
                          child: Text('No claims found',
                              style: GoogleFonts.inter(color: QSColors.textLight)))
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: _amber,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                                QSSpacing.m, 0, QSSpacing.m, 120),
                            itemCount: _claims.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: QSSpacing.s),
                            itemBuilder: (_, i) =>
                                _ClaimAdminCard(claim: _claims[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _ClaimAdminCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  const _ClaimAdminCard({required this.claim});

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final status = claim['status'] as String? ?? 'pending';
    final worker = claim['workers'] as Map<String, dynamic>?;
    final amount = (claim['amount_inr'] as num?)?.toInt() ?? 0;
    final type   = (claim['disruption_type'] as String? ?? 'claim').toUpperCase();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'paid':
        statusColor = QSColors.green; statusIcon = Icons.check_circle_rounded; break;
      case 'rejected':
        statusColor = QSColors.red; statusIcon = Icons.cancel_rounded; break;
      default:
        statusColor = _amber; statusIcon = Icons.hourglass_top_rounded;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminClaimDetailScreen(claimId: claim['id'] as String),
        ),
      ),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker?['full_name'] ?? 'Unknown Worker',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: QSColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$type · ${worker?['zone_id'] ?? '—'}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textLight),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$amount',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      color: statusColor),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: QSColors.textMuted),
          ],
        ),
      ),
    );
  }
}
