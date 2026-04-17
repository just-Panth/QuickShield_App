import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_title.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _staggerController;
  
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    
    // Fetch data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboard();
    });
  }

  Future<void> _fetchDashboard() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final data = await ApiService.instance.get('/dashboard', token);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _fade(int index) {
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        (index * 0.1 + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Animation<Offset> _slide(int index) {
    return Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        (index * 0.1 + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _dashboardData == null) {
      return const Scaffold(
        backgroundColor: QSColors.bg,
        body: Center(child: CircularProgressIndicator(color: QSColors.primary)),
      );
    }
    
    final stats = _dashboardData!['stats'] ?? {};
    final covers = _dashboardData!['active_coverage'] as List<dynamic>? ?? [];
    
    // Calculate total premium
    double totalPremium = 0;
    for (var c in covers) {
      totalPremium += (c['premium_inr'] ?? 0);
    }

    return Scaffold(
      backgroundColor: QSColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              QSSpacing.m, QSSpacing.m, QSSpacing.m, QSSpacing.xxl),
          children: [
            // ── Brand Header ──────────────────────────────────────────────
            FadeTransition(
              opacity: _fade(0),
              child: SlideTransition(
                position: _slide(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Gradient shield logo
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: QSColors.gradHero,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: QSColors.primary.withOpacity(0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Stylized brand name
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF60A5FA), // light blue
                                  Color(0xFF3B82F6), // primary blue
                                  Color(0xFFA78BFA), // light purple
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                              child: Text(
                                "QUICKSHIELD",
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Income Protection for Gig Workers",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: QSColors.textOnDarkMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Notification bell
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: QSColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: QSColors.borderDark, width: 1),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: QSColors.textOnDarkMid,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: QSSpacing.l),

            const SizedBox(height: QSSpacing.l),

            // ── Coverage Hero (White Card) ──────────────────────────────
            FadeTransition(
              opacity: _fade(1),
              child: SlideTransition(
                position: _slide(1),
                child: AppCard(
                  glowColor: QSColors.primary,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: QSColors.greenLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.shield_rounded, size: 18, color: QSColors.green),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Coverage Active",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: QSColors.green,
                                ),
                              ),
                            ],
                          ),
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) => Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: QSColors.green,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10 * _pulse.value,
                                    color: QSColors.green.withOpacity(0.6 * _pulse.value),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Protected Amount",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: QSColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${(stats['protected_inr'] as num?)?.toInt() ?? 0}",
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: QSColors.textDark,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 8),
                            child: Text(
                              "/ week",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: QSColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        color: QSColors.border.withOpacity(0.5),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MiniStat("Policies", "${stats['active_policies'] ?? 0} Active"),
                          _MiniStat("Risk Zone", "${stats['risk_level'] ?? 'Mid'}", icon: Icons.location_on_rounded, color: QSColors.green),
                          _MiniStat("Premium", "₹${totalPremium.toInt()}", icon: Icons.payments_rounded, color: QSColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: QSSpacing.m),

            // ── Earnings Protection Chart ────────────────────────────────
            FadeTransition(
              opacity: _fade(2),
              child: SlideTransition(
                position: _slide(2),
                child: const SectionTitle("Earnings Protection (Last 7 Days)"),
              ),
            ),
            const SizedBox(height: QSSpacing.s),

            FadeTransition(
              opacity: _fade(3),
              child: SlideTransition(
                position: _slide(3),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: _bottomTitleWidgets,
                              reservedSize: 22,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: 1000,
                        lineBarsData: [
                          LineChartBarData(
                            spots: () {
                              final raw = _dashboardData!['ledger'] as List?;
                              if (raw == null || raw.isEmpty) {
                                return List.generate(7, (i) => FlSpot(i.toDouble(), 0));
                              }
                              // Reverse so oldest entry is leftmost (index 0)
                              final ordered = raw.reversed.toList();
                              return List.generate(
                                ordered.length.clamp(0, 7),
                                (i) => FlSpot(
                                  i.toDouble(),
                                  (ordered[i]['amount_inr'] as num?)?.toDouble() ?? 0.0,
                                ),
                              );
                            }(),
                            isCurved: true,
                            color: QSColors.primary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  QSColors.primary.withOpacity(0.3),
                                  QSColors.primary.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          // Protection Threshold Line
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 450),
                              FlSpot(6, 450),
                            ],
                            isCurved: false,
                            color: QSColors.orangeVib,
                            barWidth: 2,
                            dashArray: [5, 5],
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: QSSpacing.m),

            // ── Active Coverage Horizontal Scroll ────────────────────────
            FadeTransition(
              opacity: _fade(4),
              child: SlideTransition(
                position: _slide(4),
                child: const SectionTitle("Your Covers"),
              ),
            ),
            const SizedBox(height: QSSpacing.s),

            FadeTransition(
              opacity: _fade(5),
              child: SlideTransition(
                position: _slide(5),
                child: SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: covers.isEmpty 
                      ? [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Text("No active covers", style: GoogleFonts.inter(color: QSColors.textLight)),
                            )
                          )
                        ]
                      : covers.map((c) {
                          Color color = QSColors.blue;
                          List<Color> grad = QSColors.gradCyan;
                          IconData ic = Icons.flash_on_rounded;
                          
                          if (c['plan_type'] == 'monsoon_surge_cover') {
                            color = QSColors.orangeVib;
                            grad = QSColors.gradOrange;
                            ic = Icons.water_drop_rounded;
                          } else if (c['plan_type'] == 'traffic_disruption') {
                            color = QSColors.redVib;
                            grad = QSColors.gradHero;
                            ic = Icons.car_crash_rounded;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _CoverageCard(
                              title: c['label'] ?? 'Unknown',
                              amount: "₹${c['premium_inr']}/wk",
                              icon: ic,
                              color: color,
                              gradient: grad,
                              pulse: _pulse,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 50), // padding for bottom nav
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Widget _bottomTitleWidgets(double value, TitleMeta meta) {
  final style = GoogleFonts.inter(
    color: QSColors.textMuted,
    fontWeight: FontWeight.w600,
    fontSize: 10,
  );
  Widget text;
  switch (value.toInt()) {
    case 0: text = Text('Mon', style: style); break;
    case 1: text = Text('Tue', style: style); break;
    case 2: text = Text('Wed', style: style); break;
    case 3: text = Text('Thu', style: style); break;
    case 4: text = Text('Fri', style: style); break;
    case 5: text = Text('Sat', style: style); break;
    case 6: text = Text('Sun', style: style); break;
    default: text = Text('', style: style); break;
  }
  return SideTitleWidget(meta: meta, child: text);
}

// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  const _MiniStat(this.label, this.value, {this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: QSColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: QSColors.textDark,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CoverageCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final Animation<double> pulse;

  const _CoverageCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: QSColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: QSColors.border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient top header line
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    AnimatedBuilder(
                      animation: pulse,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.3 + pulse.value * 0.3)),
                        ),
                        child: Text(
                          "Active",
                          style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: QSColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: QSColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}