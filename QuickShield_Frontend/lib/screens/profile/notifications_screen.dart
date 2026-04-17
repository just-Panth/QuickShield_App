import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _activity = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final data = await ApiService.instance.get('/dashboard', token);
      if (mounted) {
        setState(() {
          _activity = data['recent_activity'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: QSColors.textOnDark,
          ),
        ),
        actions: [
          if (_activity.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: QSColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_activity.length} new',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: QSColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: QSColors.primary))
          : RefreshIndicator(
              onRefresh: _fetch,
              color: QSColors.primary,
              backgroundColor: QSColors.card,
              child: _activity.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          QSSpacing.m, QSSpacing.s, QSSpacing.m, QSSpacing.xxl),
                      itemCount: _activity.length,
                      itemBuilder: (ctx, i) => _NotifTile(item: _activity[i]),
                    ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: QSColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 48, color: QSColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: QSColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Claim updates and alerts will appear here',
            style: GoogleFonts.inter(fontSize: 14, color: QSColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _NotifTile({required this.item});

  IconData get _icon {
    final type = item['type'] as String? ?? '';
    if (type == 'claim_paid') return Icons.check_circle_rounded;
    if (type == 'claim_rejected') return Icons.cancel_rounded;
    if (type == 'claim_review') return Icons.hourglass_top_rounded;
    if (type == 'policy_created') return Icons.shield_rounded;
    if (type == 'payout') return Icons.payments_rounded;
    return Icons.notifications_rounded;
  }

  Color get _color {
    final type = item['type'] as String? ?? '';
    if (type == 'claim_paid' || type == 'payout' || type == 'policy_created') {
      return QSColors.green;
    }
    if (type == 'claim_rejected') return QSColors.redVib;
    if (type == 'claim_review') return QSColors.orangeVib;
    return QSColors.primary;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    if (now.difference(d).inDays == 0) {
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return 'Today $h:$m';
    }
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? item['type'] as String? ?? 'Update';
    final subtitle = item['subtitle'] as String? ?? item['description'] as String? ?? '';
    final rawDate = item['created_at'] as String? ?? item['date'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, size: 22, color: _color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: QSColors.textDark,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: QSColors.textLight),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(rawDate),
                    style: GoogleFonts.inter(
                      fontSize: 11, color: QSColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
