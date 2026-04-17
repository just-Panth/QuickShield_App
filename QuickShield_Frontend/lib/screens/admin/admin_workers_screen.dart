import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen> {
  static const _amber = Color(0xFFF59E0B);

  bool _loading = true;
  List<dynamic> _workers = [];
  String _search = '';
  String _selectedZone = 'all';

  static const _zones = ['all', 'BLR-SOUTH', 'BLR-NORTH', 'MUM-CENTRAL', 'DEFAULT'];

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
      String url = '/admin/workers?';
      if (_search.trim().isNotEmpty) url += 'search=${Uri.encodeComponent(_search)}&';
      if (_selectedZone != 'all') url += 'zone=$_selectedZone&';
      final res = await ApiService.instance.get(url, token);
      if (mounted) {
        setState(() {
          _workers = res['workers'] as List<dynamic>? ?? [];
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
            Padding(
              padding: const EdgeInsets.fromLTRB(QSSpacing.m, QSSpacing.m, QSSpacing.m, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Workers',
                        style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: QSColors.textOnDark,
                            letterSpacing: -0.7)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_workers.length} total',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w700, color: _amber)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.m),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: QSSpacing.m),
              child: TextFormField(
                style: GoogleFonts.inter(
                    fontSize: 14, color: QSColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: QSColors.textLight),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: QSColors.textMuted),
                  filled: true,
                  fillColor: QSColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: _amber.withOpacity(0.5), width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) {
                  setState(() => _search = v);
                  // debounce via simple delay
                  Future.delayed(const Duration(milliseconds: 400), _fetch);
                },
              ),
            ),

            const SizedBox(height: QSSpacing.s),

            // Zone filter
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: QSSpacing.m),
                children: _zones.map((z) {
                  final sel = z == _selectedZone;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedZone = z);
                      _fetch();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? _amber : QSColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? _amber
                                : QSColors.border.withOpacity(0.5)),
                      ),
                      child: Text(z == 'all' ? 'All Zones' : z,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.black : QSColors.textMid)),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: QSSpacing.m),

            // Workers list
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _amber))
                  : _workers.isEmpty
                      ? Center(
                          child: Text('No workers found',
                              style: GoogleFonts.inter(
                                  color: QSColors.textLight)))
                      : RefreshIndicator(
                          onRefresh: _fetch,
                          color: _amber,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                                QSSpacing.m, 0, QSSpacing.m, 120),
                            itemCount: _workers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: QSSpacing.s),
                            itemBuilder: (_, i) =>
                                _WorkerCard(worker: _workers[i]),
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

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  const _WorkerCard({required this.worker});

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final name     = worker['full_name'] as String? ?? 'Unknown';
    final email    = worker['email'] as String? ?? '';
    final zone     = worker['zone_id'] as String? ?? '—';
    final platform = worker['platform'] as String? ?? '—';
    final role     = worker['role'] as String? ?? 'worker';
    final policies = worker['active_policies'] as int? ?? 0;
    final paid     = worker['total_paid_inr'] as num? ?? 0;
    final isAdmin  = role == 'admin';

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAdmin
                ? _amber.withOpacity(0.15)
                : QSColors.primary.withOpacity(0.12),
            radius: 22,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'W',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isAdmin ? _amber : QSColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: QSColors.textDark),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('ADMIN',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _amber,
                                letterSpacing: 0.8)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(email,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: QSColors.textLight),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(label: zone, icon: Icons.location_on_rounded),
                    const SizedBox(width: 6),
                    _Chip(label: platform.toUpperCase(), icon: Icons.phone_android_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${paid.toInt()}',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: QSColors.green)),
              Text('paid out',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: QSColors.textLight)),
              const SizedBox(height: 6),
              Text('$policies policies',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: QSColors.textMid)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: QSColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: QSColors.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: QSColors.textLight)),
        ],
      ),
    );
  }
}
