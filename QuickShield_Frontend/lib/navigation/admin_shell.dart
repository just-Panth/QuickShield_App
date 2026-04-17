import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/colors.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';
import '../screens/admin/admin_all_claims_screen.dart';
import '../screens/admin/admin_workers_screen.dart';
import '../screens/admin/simulate_disaster_screen.dart';
import '../screens/profile/profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  static const _screens = [
    AdminDashboardScreen(),
    AdminAllClaimsScreen(),
    AdminWorkersScreen(),
    SimulateDisasterScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Claims'),
    _NavItem(icon: Icons.people_rounded, label: 'Workers'),
    _NavItem(icon: Icons.bolt_rounded, label: 'Simulate'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  // Accent color for the admin shell — amber/orange to distinguish from worker
  static const Color _accent = QSColors.orangeVib;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QSColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: QSColors.cardDark,
          border: Border(
            top: BorderSide(color: QSColors.borderDark, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == _currentIndex;
                final item = _items[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _currentIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Active indicator dot
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 3,
                            width: selected ? 24 : 0,
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            item.icon,
                            size: selected ? 26 : 22,
                            color:
                                selected ? _accent : QSColors.textOnDarkMid,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: selected
                                  ? _accent
                                  : QSColors.textOnDarkMid,
                            ),
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
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
