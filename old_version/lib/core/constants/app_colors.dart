import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Brand ──────────────────────────────────────────
  static const Color primary        = Color(0xFF00D4FF);   // سماوي نيون
  static const Color primaryGlow    = Color(0xFF0099CC);
  static const Color accent         = Color(0xFF7C3AED);   // بنفسجي عميق
  static const Color accentGlow     = Color(0xFFAB5CF7);

  // ── Backgrounds ────────────────────────────────────────────
  static const Color bgDeep         = Color(0xFF050B18);   // أسود كوني
  static const Color bgCard         = Color(0xFF0D1626);   // بطاقة داكنة
  static const Color bgCardLight    = Color(0xFF111D35);
  static const Color bgSurface      = Color(0xFF0A1220);

  // ── Glass Effect ───────────────────────────────────────────
  static const Color glassWhite     = Color(0x0FFFFFFF);
  static const Color glassBorder    = Color(0x20FFFFFF);
  static const Color glassHighlight = Color(0x15FFFFFF);

  // ── Status ─────────────────────────────────────────────────
  static const Color success        = Color(0xFF00E5A0);
  static const Color warning        = Color(0xFFFFB020);
  static const Color error          = Color(0xFFFF4D6D);
  static const Color info           = Color(0xFF00D4FF);

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF0F8FF);
  static const Color textSecondary  = Color(0xFF8BA8C8);
  static const Color textMuted      = Color(0xFF3D5A7A);
  static const Color textAccent     = Color(0xFF00D4FF);

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0D1626), Color(0xFF111D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient queueGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0099CC), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF050B18), Color(0xFF0A1525), Color(0xFF050B18)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient glowGradient = RadialGradient(
    colors: [Color(0x3000D4FF), Color(0x0000D4FF), Colors.transparent],
    radius: 0.8,
  );
}
