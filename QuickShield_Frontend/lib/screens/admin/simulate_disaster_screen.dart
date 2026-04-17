import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../services/api_service.dart';
import '../../widgets/app_card.dart';

class SimulateDisasterScreen extends StatefulWidget {
  const SimulateDisasterScreen({super.key});

  @override
  State<SimulateDisasterScreen> createState() => _SimulateDisasterScreenState();
}

class _SimulateDisasterScreenState extends State<SimulateDisasterScreen> {
  static const _amber = Color(0xFFF59E0B);

  // Panel 1 — Trigger Disaster
  String _selectedZone        = 'BLR-SOUTH';
  String _selectedDisruption  = 'flood';
  bool   _triggering          = false;
  Map<String, dynamic>? _triggerResult;

  // Panel 2 — Auto Process Claims
  bool   _processing          = false;
  Map<String, dynamic>? _processResult;

  // Panel 3 — Fraud Test
  String _fraudWorkerId       = '';
  bool   _fraudTesting        = false;
  Map<String, dynamic>? _fraudResult;

  // Panel 4 — Active Zones
  bool   _zonesLoading        = true;
  List<dynamic> _activeZones  = [];

  static const _zones = ['BLR-SOUTH', 'BLR-NORTH', 'MUM-CENTRAL', 'DEFAULT'];
  static const _disruptions = ['flood', 'platform_outage', 'protest', 'accident'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchZones());
  }

  String? get _token => context.read<AuthProvider>().token;

  // ── Panel 1: Trigger ────────────────────────────────────────────────────────
  Future<void> _triggerDisaster() async {
    if (_token == null) return;
    setState(() { _triggering = true; _triggerResult = null; });
    try {
      final res = await ApiService.instance.post('/simulate/trigger', {
        'zone_id':          _selectedZone,
        'disruption_type':  _selectedDisruption,
      }, _token!);
      setState(() { _triggerResult = res; });
      _fetchZones(); // refresh active zones
    } catch (e) {
      setState(() {
        _triggerResult = {'error': e.toString()};
      });
    } finally {
      setState(() => _triggering = false);
    }
  }

  // ── Panel 2: Auto Process ───────────────────────────────────────────────────
  Future<void> _autoProcess() async {
    if (_token == null) return;
    setState(() { _processing = true; _processResult = null; });
    try {
      final res = await ApiService.instance.post(
          '/simulate/auto-process', {}, _token!);
      setState(() => _processResult = res);
    } catch (e) {
      setState(() => _processResult = {'error': e.toString()});
    } finally {
      setState(() => _processing = false);
    }
  }

  // ── Panel 3: Fraud Test ─────────────────────────────────────────────────────
  Future<void> _runFraudTest() async {
    if (_token == null || _fraudWorkerId.trim().isEmpty) return;
    setState(() { _fraudTesting = true; _fraudResult = null; });
    try {
      final res = await ApiService.instance.post('/simulate/test-fraud', {
        'worker_id': _fraudWorkerId.trim(),
      }, _token!);
      setState(() => _fraudResult = res);
    } catch (e) {
      setState(() => _fraudResult = {'error': e.toString()});
    } finally {
      setState(() => _fraudTesting = false);
    }
  }

  // ── Panel 4: Active Zones ───────────────────────────────────────────────────
  Future<void> _fetchZones() async {
    if (_token == null) return;
    setState(() => _zonesLoading = true);
    try {
      final res = await ApiService.instance.get('/admin/zones', _token!);
      setState(() => _activeZones = res['zones'] as List<dynamic>? ?? []);
    } catch (_) {}
    setState(() => _zonesLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              QSSpacing.m, QSSpacing.m, QSSpacing.m, 120),
          children: [
            // ── Header ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: QSColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: QSColors.red, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disaster Simulator',
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: QSColors.textOnDark,
                            letterSpacing: -0.6)),
                    Text('Admin-only simulation controls',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: QSColors.textOnDarkMid)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Panel 1: Trigger ───────────────────────────────────────
            _SectionLabel(label: '01 — TRIGGER DISASTER', color: QSColors.red),
            const SizedBox(height: QSSpacing.s),
            AppCard(
              glowColor: QSColors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownField(
                          label: 'Zone',
                          items: _zones,
                          value: _selectedZone,
                          onChanged: (v) => setState(() => _selectedZone = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Disruption',
                          items: _disruptions,
                          value: _selectedDisruption,
                          onChanged: (v) => setState(() => _selectedDisruption = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _triggering ? null : _triggerDisaster,
                      icon: _triggering
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(_triggering ? 'Triggering...' : 'Trigger Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QSColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_triggerResult != null) ...[
                    const SizedBox(height: 12),
                    _ResultBox(result: _triggerResult!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Panel 2: Auto Process ──────────────────────────────────
            _SectionLabel(label: '02 — AUTO-PROCESS CLAIMS', color: _amber),
            const SizedBox(height: QSSpacing.s),
            AppCard(
              glowColor: _amber,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Runs the full 3-gate pipeline on all pending claims across all active zones.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: QSColors.textMid, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _processing ? null : _autoProcess,
                      icon: _processing
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_circle_filled_rounded, size: 18),
                      label: Text(_processing ? 'Processing...' : 'Run Auto-Processor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_processResult != null) ...[
                    const SizedBox(height: 12),
                    _ResultBox(result: _processResult!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Panel 3: Fraud Test ────────────────────────────────────
            _SectionLabel(label: '03 — FRAUD DETECTION TEST', color: QSColors.primary),
            const SizedBox(height: QSSpacing.s),
            AppCard(
              glowColor: QSColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    style: GoogleFonts.inter(
                        fontSize: 14, color: QSColors.textDark),
                    decoration: InputDecoration(
                      labelText: 'Worker ID (UUID)',
                      labelStyle: GoogleFonts.inter(
                          fontSize: 13, color: QSColors.textLight),
                      filled: true,
                      fillColor: QSColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: QSColors.primary.withOpacity(0.5)),
                      ),
                    ),
                    onChanged: (v) => setState(() => _fraudWorkerId = v),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _fraudTesting ? null : _runFraudTest,
                      icon: _fraudTesting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.shield_rounded, size: 18),
                      label: Text(_fraudTesting ? 'Analysing...' : 'Run Fraud Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: QSColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_fraudResult != null) ...[
                    const SizedBox(height: 12),
                    _ResultBox(result: _fraudResult!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: QSSpacing.l),

            // ── Panel 4: Active Zones ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel(label: '04 — ACTIVE DISRUPTIONS', color: QSColors.green),
                GestureDetector(
                  onTap: _fetchZones,
                  child: const Icon(Icons.refresh_rounded,
                      size: 20, color: QSColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: QSSpacing.s),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _zonesLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                          child: CircularProgressIndicator(color: _amber)))
                  : _activeZones.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                              child: Text('No active disruptions',
                                  style: GoogleFonts.inter(
                                      color: QSColors.textLight))))
                      : Column(
                          children: _activeZones.map((z) {
                            final zone   = z['zone_id'] as String? ?? '';
                            final active = z['active'] as bool? ?? false;
                            final ttl    = z['ttl_seconds'] as int?;
                            final peers  = z['peer_reports'] as int? ?? 0;
                            final event  = z['event'] as Map<String, dynamic>?;
                            if (!active) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: QSColors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.warning_rounded,
                                        color: QSColors.red, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(zone,
                                            style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: QSColors.textDark)),
                                        Text(
                                          '${(event?['type'] as String? ?? '').toUpperCase()}  ·  $peers peer reports'
                                          '${ttl != null ? '  ·  ${ttl}s remaining' : ''}',
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: QSColors.textLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: QSColors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('ACTIVE',
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: QSColors.red)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: color, letterSpacing: 1.2));
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String value;
  final void Function(String?) onChanged;
  const _DropdownField({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 11, color: QSColors.textLight)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: QSColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              dropdownColor: QSColors.card,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: QSColors.textDark),
              items: items.map((e) {
                return DropdownMenuItem(value: e, child: Text(e));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultBox extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultBox({required this.result});
  @override
  Widget build(BuildContext context) {
    final hasError = result.containsKey('error');
    final color    = hasError ? QSColors.red : QSColors.green;
    final text     = hasError
        ? result['error'].toString()
        : (result['message'] as String? ?? result.toString());
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.check_circle_outline,
            color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 12, color: color, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
