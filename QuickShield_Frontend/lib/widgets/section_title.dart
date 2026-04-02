import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final bool showDot;

  const SectionTitle(this.text, {this.showDot = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: QSColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: QSColors.primary.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: QSColors.textOnDarkMid,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}