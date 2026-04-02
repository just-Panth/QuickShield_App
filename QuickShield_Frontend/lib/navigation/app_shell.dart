import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/colors.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/policies/policies_screen.dart';
import '../screens/premium/premium_calculator_screen.dart';
import '../screens/claims/claims_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  final _screens = const [
    DashboardScreen(),
    PoliciesScreen(),
    PremiumCalculatorScreen(),
    ClaimsScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded,        label: 'Home'),
    _NavItem(icon: Icons.description_rounded, label: 'Policies'),
    _NavItem(icon: Icons.calculate_rounded,   label: 'Premium'),
    _NavItem(icon: Icons.receipt_rounded,     label: 'Claims'),
    _NavItem(icon: Icons.person_rounded,      label: 'Profile'),
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
            child: IndexedStack(index: _index, children: _screens),
          ),
          
          // Floating Nav Bar Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildNav(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    // Add gradient fade to the bottom so the nav bar floats nicely
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
            border: Border.all(color: QSColors.border.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                blurRadius: 32,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(0.3), // Shadow on deep navy
              ),
              BoxShadow(
                blurRadius: 16,
                offset: const Offset(0, 4),
                color: QSColors.primary.withOpacity(0.05),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
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
                                ? QSColors.primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            item.icon,
                            size: 24,
                            color: selected
                                ? QSColors.primary
                                : QSColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? QSColors.primary
                                : QSColors.textLight,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
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