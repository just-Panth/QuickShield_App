import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/colors.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_claims_screen.dart';
import '../screens/admin/simulate_disaster_screen.dart';
import '../screens/admin/admin_workers_screen.dart';

/// Amber-accented shell for admins — visually distinct from the worker's blue shell.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  static const _amber = Color(0xFFF59E0B);

  final _screens = const [
    AdminDashboardScreen(),
    AdminClaimsScreen(),
    SimulateDisasterScreen(),
    AdminWorkersScreen(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded,   label: 'Overview'),
    _NavItem(icon: Icons.list_alt_rounded,    label: 'Claims'),
    _NavItem(icon: Icons.bolt_rounded,        label: 'Simulate'),
    _NavItem(icon: Icons.groups_rounded,      label: 'Workers'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _index) return;
    _controller.forward().then((_) {
      setState(() => _index = i);
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (ctx, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
            child: _screens[_index],
          ),
          // Admin top badge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 12, color: _amber),
                        const SizedBox(width: 5),
                        Text(
                          'ADMIN MODE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _amber,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            QSColors.bg.withOpacity(0),
            QSColors.bg.withOpacity(0.8),
            QSColors.bg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: QSColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _amber.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                blurRadius: 32,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(0.3),
              ),
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 4),
                color: _amber.withOpacity(0.08),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final selected = i == _index;
              final item = _navItems[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _amber.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          item.icon,
                          size: 24,
                          color: selected ? _amber : QSColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? _amber : QSColors.textLight,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
