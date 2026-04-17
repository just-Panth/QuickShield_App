import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/claim_service.dart';
import '../../widgets/app_card.dart';

class AdminAllClaimsScreen extends StatefulWidget {
  const AdminAllClaimsScreen({super.key});

  @override
  State<AdminAllClaimsScreen> createState() => _AdminAllClaimsScreenState();
}

class _AdminAllClaimsScreenState extends State<AdminAllClaimsScreen> {
  bool _isLoading = true;
  List<dynamic> _claims = [];
  String _filter = 'all';

  static const _filters = ['all', 'paid', 'rejected', 'review', 'pending'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await ClaimService.instance.fetchAdminClaims(token);
      if (mounted) {
        setState(() {
          _claims = data['claims'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _claims;
    return _claims.where((c) => c['status'] == _filter).toList();
  }

  Color _statusColor(String status) {
    if (status == 'paid') return QSColors.green;
    if (status == 'rejected') return QSColors.redVib;
    if (status == 'review') return QSColors.orangeVib;
    return QSColors.textMuted;
  }

  IconData _statusIcon(String status) {
    if (status == 'paid') return Icons.check_circle_rounded;
    if (status == 'rejected') return Icons.cancel_rounded;
    if (status == 'review') return Icons.hourglass_top_rounded;
    return Icons.pending_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  QSSpacing.m, QSSpacing.m, QSSpacing.m, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: QSColors.orangeVib.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            color: QSColors.orangeVib, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'All Claims',
                        style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: QSColors.textOnDark, letterSpacing: -0.6,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_filtered.length} claims',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: QSColors.textOnDarkMid),
                      ),
                    ],
                  ),
                  const SizedBox(height: QSSpacing.m),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? QSColors.orangeVib
                                    : QSColors.cardDark,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? QSColors.orangeVib
                                      : QSColors.borderDark,
                                ),
                              ),
                              child: Text(
                                f[0].toUpperCase() + f.substring(1),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : QSColors.textOnDarkMid,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: QSSpacing.s),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: QSColors.orangeVib))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: QSColors.orangeVib,
                      backgroundColor: QSColors.card,
                      child: _filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_rounded,
                                      size: 48,
                                      color: QSColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No $_filter claims',
                                    style: GoogleFonts.inter(
                                        color: QSColors.textLight,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  QSSpacing.m, 0, QSSpacing.m,
                                  QSSpacing.xxl + 60),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) {
                                final c = _filtered[i];
                                final status = c['status'] as String? ?? 'pending';
                                final color = _statusColor(status);
                                final score = (c['fraud_score'] as num?)?.toInt();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AppCard(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(24),
                                              topRight: Radius.circular(24),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: color.withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(10),
                                                    ),
                                                    child: Icon(_statusIcon(status),
                                                        size: 18, color: color),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          c['worker_id']
                                                                  ?.toString()
                                                                  .substring(0, 8) ??
                                                              '—',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w700,
                                                            color: QSColors.textDark,
                                                          ),
                                                        ),
                                                        Text(
                                                          (c['disruption_type']
                                                                      as String? ??
                                                                  'unknown')
                                                              .replaceAll('_', ' '),
                                                          style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              color:
                                                                  QSColors.textLight),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 10,
                                                            vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              color.withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  12),
                                                        ),
                                                        child: Text(
                                                          status.toUpperCase(),
                                                          style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: color,
                                                          ),
                                                        ),
                                                      ),
                                                      if (c['amount_inr'] != null) ...[
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          '₹${(c['amount_inr'] as num).toInt()}',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w800,
                                                            color: QSColors.textDark,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              if (score != null) ...[
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.security_rounded,
                                                        size: 12,
                                                        color: QSColors.textMuted),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Fraud score: $score/100',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: score > 70
                                                            ? QSColors.redVib
                                                            : score > 40
                                                                ? QSColors.orangeVib
                                                                : QSColors.green,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
