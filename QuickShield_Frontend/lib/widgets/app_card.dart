import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? borderRadius;
  final Border? border;
  final Color? glowColor;
  final List<Color>? gradient;

  const AppCard({
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
    this.glowColor,
    this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rad = borderRadius ?? 24.0;
    
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? QSColors.card) : null,
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(rad),
        border: border ?? Border.all(color: QSColors.border.withOpacity(0.5), width: 1),
        boxShadow: [
          // Soft wide shadow
          BoxShadow(
            blurRadius: 40,
            offset: const Offset(0, 12),
            color: glowColor != null
                ? glowColor!.withOpacity(0.15)
                : QSColors.primary.withOpacity(0.06), // Very subtle blue tint
          ),
          // Inner tight shadow for depth
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: child,
    );
  }
}