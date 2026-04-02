import 'package:flutter/material.dart';

class QSColors {
  QSColors._();

  // ─── App Backgrounds (DARK) ─────────────────────────────────────
  static const bg      = Color(0xFF060F1C); // Main dark navy
  static const bgDeep  = Color(0xFF030A15); // Deeper for gradient
  static const bgMid   = Color(0xFF0C1829); // Slight variation

  // ─── Card Surfaces (LIGHT — the semi-dark balance) ──────────────
  static const card    = Color(0xFFFFFFFF); // White card (primary)
  static const cardAlt = Color(0xFFF0F5FF); // Blue-tinted alt
  static const surface = Color(0xFFF5F8FF); // Input fill on white
  static const cardDark = Color(0xFF0F1E35); // Dark card variant

  // ─── Brand ──────────────────────────────────────────────────────
  static const primary      = Color(0xFF2563EB);
  static const primaryLight = Color(0xFFEFF6FF);
  static const primaryDark  = Color(0xFF1D4ED8);
  static const accent       = Color(0xFF7C3AED);
  static const accentLight  = Color(0xFFF5F3FF);
  static const cyan         = Color(0xFF06B6D4);

  // ─── Gradient pairs ─────────────────────────────────────────────
  static const gradPrimary = [Color(0xFF3B82F6), Color(0xFF2563EB)];
  static const gradAccent  = [Color(0xFF7C3AED), Color(0xFF4F46E5)];
  static const gradHero    = [Color(0xFF3B82F6), Color(0xFF7C3AED)];
  static const gradCyan    = [Color(0xFF06B6D4), Color(0xFF2563EB)];
  static const gradGreen   = [Color(0xFF22C55E), Color(0xFF16A34A)];
  static const gradOrange  = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const gradRed     = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const gradDark    = [Color(0xFF152035), Color(0xFF0A1628)];
  static const gradGold    = [Color(0xFFFBBF24), Color(0xFFF59E0B)];

  // ─── Borders ────────────────────────────────────────────────────
  static const border     = Color(0xFFE2E8F0); // For white cards
  static const borderDark = Color(0xFF1A2D47); // For dark elements

  // ─── Semantic ───────────────────────────────────────────────────
  static const green       = Color(0xFF16A34A);
  static const greenLight  = Color(0xFFDCFCE7);
  static const greenVib    = Color(0xFF22C55E);
  static const orange      = Color(0xFFD97706);
  static const orangeLight = Color(0xFFFEF3C7);
  static const orangeVib   = Color(0xFFF59E0B);
  static const red         = Color(0xFFDC2626);
  static const redLight    = Color(0xFFFEE2E2);
  static const redVib      = Color(0xFFEF4444);
  static const blue        = Color(0xFF0EA5E9);
  static const blueLight   = Color(0xFFE0F2FE);
  static const gold        = Color(0xFFF59E0B);

  // ─── Text on dark backgrounds ───────────────────────────────────
  static const textOnDark      = Color(0xFFDAE8FF);
  static const textOnDarkMid   = Color(0xFF7E9DC0);
  static const textOnDarkMuted = Color(0xFF3F5C7D);

  // ─── Text on white card backgrounds ─────────────────────────────
  static const textDark  = Color(0xFF0F172A);
  static const textMid   = Color(0xFF334155);
  static const textLight = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
}