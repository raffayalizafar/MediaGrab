import 'package:flutter/material.dart';

/// Semantic colors and cyber-luxe palette for MediaGrab.
class AppColors {
  /// Default brand seed color (Electric Indigo)
  static const Color brandSeed = Color(0xFF6366F1);

  /// Secondary accent seed (Hyper Cyan / Teal)
  static const Color oceanSeed = Color(0xFF06B6D4);

  /// Tertiary seed (Neon Rose / Coral)
  static const Color roseSeed = Color(0xFFF43F5E);

  /// Violet accent
  static const Color violetSeed = Color(0xFF8B5CF6);

  /// Brand & Surface tokens for Claymorphism & Stitch navigation
  static const Color brandPrimary = Color(0xFF6366F1); // Indigo 500
  static const Color brandAccent = Color(0xFF38BDF8); // Sky 400
  static const Color brandAccentSoft = Color(0xFFA5B4FC); // Indigo 300
  static const Color darkOnSurfaceMuted = Color(0xFF94A3B8); // Slate 400
  static const Color lightOnSurfaceMuted = Color(0xFF64748B); // Slate 500

  /// Status indicators
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  /// Stitch Design Slate palette
  static const Color slate950 = Color(0xFF070A12);
  static const Color slate900 = Color(0xFF0B0F19);
  static const Color slate850 = Color(0xFF111827);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);

  /// Stitch Accents
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color purple400 = Color(0xFFC084FC);

  /// Dark background & surface colors (mapped to Stitch slate-950 and slate-900)
  static const Color darkBackground = slate950;
  static const Color darkSurface = slate900;
  static const Color darkCard = slate850;
  static const Color darkBorder = slate800;

  /// Video badge / Audio badge color accents
  static const Color videoBadge = Color(0xFF3B82F6);
  static const Color audioBadge = Color(0xFF10B981);
  static const Color playlistBadge = Color(0xFFA855F7);
}
