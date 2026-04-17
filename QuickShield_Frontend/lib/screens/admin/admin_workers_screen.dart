import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/claim_service.dart';
import '../../widgets/app_card.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  bool _isLoading = true;
  List<dynamic> _workers = [];
  String _query = '';

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
      final data = await ClaimService.instance.fetchAdminWorkers(token);
      if (mounted) {
        setState(() {
          _workers = data['workers'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_query.isEmpty) return _workers;
    final q = _query.toLowerCase();
    return _workers.where((w) {
      final name = (w['full_name'] as String? ?? '').toLowerCase();
      final email = (w['email'] as String? ?? '').toLowerCase();
      final zone = (w['zone_id'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || zone.contains(q);
    }).toList();
  }

  Color _platformColor(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'blinkit': return QSColors.green;
      case 'swiggy': return QSColors.orangeVib;
      case 'zomato': return QSColors.redVib;
      case 'zepto': return QSColors.primary;
      default: return QSColors.textMuted;
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
                          color: QSColors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.people_rounded,
                            color: QSColors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Workers',
                        style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: QSColors.textOnDark, letterSpacing: -0.6,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_filtered.length} workers',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: QSColors.textOnDarkMid),
                      ),
                    ],
                  ),
                  const SizedBox(height: QSSpacing.m),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: QSColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: QSColors.borderDark),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: GoogleFonts.inter(
                          color: QSColors.textOnDark, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search name, email, zone…',
                        hintStyle: GoogleFonts.inter(
                            color: QSColors.textOnDarkMid, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: QSColors.textOnDarkMid),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: QSSpacing.s),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: QSColors.blue))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: QSColors.blue,
                      backgroundColor: QSColors.card,
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(
                                _query.isEmpty
                                    ? 'No workers found'
                                    : 'No results for "$_query"',
                                style: GoogleFonts.inter(
                                    color: QSColors.textLight, fontSize: 15),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  QSSpacing.m, 0, QSSpacing.m,
                                  QSSpacing.xxl + 60),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) {
                                final w = _filtered[i];
                                final platform = w['platform'] as String?;
                                final platformColor = _platformColor(platform);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: AppCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                                colors: QSColors.gradHero),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              (w['full_name'] as String? ?? 'W')
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                w['full_name'] as String? ?? '—',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: QSColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                w['email'] as String? ?? '—',
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: QSColors.textLight),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.location_on_rounded,
                                                      size: 12,
                                                      color: QSColors.textMuted),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${w['zone_id'] ?? '—'} · ${w['city'] ?? '—'}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: QSColors.textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (platform != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: platformColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: platformColor
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  platform.isEmpty ? platform : platform[0].toUpperCase() + platform.substring(1),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: platformColor,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: (w['is_active'] == true)
                                                    ? QSColors.green
                                                    : QSColors.textMuted,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
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
