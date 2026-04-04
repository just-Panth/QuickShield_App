import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const PremiumCard({
    required this.child,
    this.padding,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      margin: margin ?? const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: QSColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.065),
          ),
          BoxShadow(
            blurRadius: 4,
            offset: const Offset(0, 1),
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: child,
    );
  }
}