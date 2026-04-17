import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class SimulateDisasterScreen extends StatefulWidget {
  const SimulateDisasterScreen({super.key});

  @override
  State<SimulateDisasterScreen> createState() => _SimulateDisasterScreenState();
}

class _SimulateDisasterScreenState extends State<SimulateDisasterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: QSColors.redVib.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: QSColors.redVib, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Simulate',
                    style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: QSColors.textOnDark, letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: QSSpacing.m),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: QSSpacing.m),
              decoration: BoxDecoration(
                color: QSColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: QSColors.redVib,
                  borderRadius: BorderRadius.circular(14),
                ),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600),
                labelColor: Colors.white,
                unselectedLabelColor: QSColors.textOnDarkMid,
                tabs: const [
                  Tab(text: 'Trigger'),
                  Tab(text: 'Pipeline'),
                  Tab(text: 'Fraud Test'),
                ],
              ),
            ),
            const SizedBox(height: QSSpacing.s),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _TriggerDisruptionPanel(),
                  _FullPipelinePanel(),
                  _FraudTestPanel(),
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
// Panel A: Trigger Disruption
// ─────────────────────────────────────────────────────────────────────────────

class _TriggerDisruptionPanel extends StatefulWidget {
  const _TriggerDisruptionPanel();

  @override
  State<_TriggerDisruptionPanel> createState() => _TriggerDisruptionPanelState();
}

class _TriggerDisruptionPanelState extends State<_TriggerDisruptionPanel> {
  final _zoneCtrl = TextEditingController(text: 'ZONE_BLR_CENTRAL');
  String _type = 'weather';
  String _severity = 'high';
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  static const _types = ['weather', 'traffic', 'event'];
  static const _severities = ['low', 'medium', 'high'];

  @override
  void dispose() {
    _zoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _trigger() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() { _loading = true; _result = null; _error = null; });
    try {
      final data = await ApiService.instance.post('/simulate/trigger-disruption', {
        'zone_id': _zoneCtrl.text.trim(),
        'disruption_type': _type,
        'severity': _severity,
      }, token);
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QSSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zone ID',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _zoneCtrl,
                  style: GoogleFonts.inter(
                      color: QSColors.textDark, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: QSColors.surface,
                    hintText: 'e.g. ZONE_BLR_CENTRAL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: QSColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: QSColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: QSColors.redVib, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Disruption Type',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _ChipRow(
                  items: _types,
                  selected: _type,
                  onSelect: (v) => setState(() => _type = v),
                  activeColor: QSColors.redVib,
                ),
                const SizedBox(height: 16),
                Text('Severity',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _ChipRow(
                  items: _severities,
                  selected: _severity,
                  onSelect: (v) => setState(() => _severity = v),
                  activeColor: _severity == 'high'
                      ? QSColors.redVib
                      : _severity == 'medium'
                          ? QSColors.orangeVib
                          : QSColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: QSSpacing.m),
          _ActionButton(
            label: 'Trigger Disruption',
            icon: Icons.warning_amber_rounded,
            color: QSColors.redVib,
            loading: _loading,
            onTap: _trigger,
          ),
          if (_result != null) ...[
            const SizedBox(height: QSSpacing.m),
            _ResultCard(result: _result!, color: QSColors.redVib),
          ],
          if (_error != null) ...[
            const SizedBox(height: QSSpacing.m),
            _ErrorCard(error: _error!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel B: Full Pipeline
// ─────────────────────────────────────────────────────────────────────────────

class _FullPipelinePanel extends StatefulWidget {
  const _FullPipelinePanel();

  @override
  State<_FullPipelinePanel> createState() => _FullPipelinePanelState();
}

class _FullPipelinePanelState extends State<_FullPipelinePanel> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _run() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _result = null; _error = null; });
    try {
      final data = await ApiService.instance.post('/simulate/full-claim-pipeline', {
        'worker_email': _emailCtrl.text.trim(),
        'force_pass_all_gates': true,
      }, token);
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QSSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Worker Email',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(
                      color: QSColors.textDark, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: QSColors.surface,
                    hintText: 'worker@example.com',
                    prefixIcon: const Icon(Icons.person_rounded,
                        color: QSColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: QSColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: QSColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: QSColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: QSColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Triggers disruption + runs all 3 gates automatically',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: QSColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: QSSpacing.m),
          _ActionButton(
            label: 'Run Full Pipeline',
            icon: Icons.play_circle_rounded,
            color: QSColors.primary,
            loading: _loading,
            onTap: _run,
          ),
          if (_result != null) ...[
            const SizedBox(height: QSSpacing.m),
            _PipelineTimeline(result: _result!),
          ],
          if (_error != null) ...[
            const SizedBox(height: QSSpacing.m),
            _ErrorCard(error: _error!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel C: Fraud Test
// ─────────────────────────────────────────────────────────────────────────────

class _FraudTestPanel extends StatefulWidget {
  const _FraudTestPanel();

  @override
  State<_FraudTestPanel> createState() => _FraudTestPanelState();
}

class _FraudTestPanelState extends State<_FraudTestPanel> {
  final _emailCtrl = TextEditingController();
  String _attackType = 'gps_spoofing';
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  static const _attacks = ['gps_spoofing', 'no_photo', 'rapid_repeat'];

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _run() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _result = null; _error = null; });
    try {
      final data = await ApiService.instance.post('/simulate/fraud-attempt', {
        'worker_email': _emailCtrl.text.trim(),
        'attack_type': _attackType,
      }, token);
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QSSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target Worker Email',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(
                      color: QSColors.textDark, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: QSColors.surface,
                    hintText: 'worker@example.com',
                    prefixIcon: const Icon(Icons.person_rounded,
                        color: QSColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: QSColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: QSColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: QSColors.redVib, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Attack Type',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.textLight,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _ChipRow(
                  items: _attacks,
                  selected: _attackType,
                  onSelect: (v) => setState(() => _attackType = v),
                  activeColor: QSColors.redVib,
                  labelTransform: (s) => s.replaceAll('_', ' '),
                ),
              ],
            ),
          ),
          const SizedBox(height: QSSpacing.m),
          _ActionButton(
            label: 'Test Fraud Detection',
            icon: Icons.bug_report_rounded,
            color: QSColors.redVib,
            loading: _loading,
            onTap: _run,
          ),
          if (_result != null) ...[
            const SizedBox(height: QSSpacing.m),
            _FraudResultCard(result: _result!),
          ],
          if (_error != null) ...[
            const SizedBox(height: QSSpacing.m),
            _ErrorCard(error: _error!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final List<String> items;
  final String selected;
  final void Function(String) onSelect;
  final Color activeColor;
  final String Function(String)? labelTransform;

  const _ChipRow({
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.activeColor,
    this.labelTransform,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: items.map((item) {
        final sel = item == selected;
        final label = labelTransform != null ? labelTransform!(item) : item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? activeColor : QSColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: sel ? activeColor : QSColors.border),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : QSColors.textMid,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                else ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final Color color;
  const _ResultCard({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glowColor: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                result['message'] as String? ?? 'Success',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: QSColors.textDark),
              ),
            ],
          ),
          if (result['event'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Zone: ${result['event']['zone_id']} · '
              'Type: ${result['event']['type']} · '
              'Severity: ${result['event']['severity']}',
              style: GoogleFonts.inter(fontSize: 12, color: QSColors.textLight),
            ),
          ],
          if (result['next_step'] != null) ...[
            const SizedBox(height: 8),
            Text(
              result['next_step'] as String,
              style: GoogleFonts.inter(fontSize: 11, color: QSColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _PipelineTimeline extends StatelessWidget {
  final Map<String, dynamic> result;
  const _PipelineTimeline({required this.result});

  @override
  Widget build(BuildContext context) {
    final timeline = result['timeline'] as List<dynamic>? ?? [];
    final payout = result['payout_inr'];

    return AppCard(
      glowColor: QSColors.green,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: QSColors.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Pipeline Complete',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: QSColors.textDark),
              ),
              if (payout != null) ...[
                const Spacer(),
                Text(
                  '₹${(payout as num).toInt()} paid',
                  style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: QSColors.green,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...timeline.map((step) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                      color: QSColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${step['step']}',
                        style: GoogleFonts.inter(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['name'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: QSColors.textDark,
                          ),
                        ),
                        Text(
                          step['detail']?.toString() ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: QSColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FraudResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _FraudResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final failed = result['failed_layers'] as List<dynamic>? ?? [];

    return AppCard(
      glowColor: QSColors.redVib,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block_rounded, color: QSColors.redVib, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['message'] as String? ?? 'Fraud blocked',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: QSColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          if (failed.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Failed layers:',
              style: GoogleFonts.inter(
                  fontSize: 12, color: QSColors.textLight,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...failed.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded,
                      size: 14, color: QSColors.redVib),
                  const SizedBox(width: 6),
                  Text(
                    l.toString().replaceAll('_', ' '),
                    style: GoogleFonts.inter(
                        fontSize: 12, color: QSColors.redVib),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glowColor: QSColors.redVib,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: QSColors.redVib, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(
                  fontSize: 13, color: QSColors.redVib,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
