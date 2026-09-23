import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Brand Identity Primary & Accent ---
  static const Color brandNavy = Color(0xFF0A1226);      // Deep Slate Navy
  static const Color brandBlue = Color(0xFF0284C7);      // Precision High-Tech Blue
  static const Color brandTeal = Color(0xFF0D9488);      // Connecting Teal
  static const Color brandSky = Color(0xFF38BDF8);       // Electric Sky Cyan
  static const Color accentGlow = Color(0xFF0EA5E9);     // Glow Cyan

  // --- Primary Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Status & Safety Indicators ---
  static const Color statusOnline = Color(0xFF10B981);   // Controlled Emerald
  static const Color statusPaused = Color(0xFF94A3B8);   // Muted Slate
  static const Color statusOffline = Color(0xFF64748B);  // Charcoal Gray
  static const Color alertWarning = Color(0xFFF59E0B);   // Amber Attention
  static const Color alertEmergency = Color(0xFFEF4444); // Crimson SOS

  // --- Light Theme Canvas & Surfaces ---
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // --- Dark Theme Canvas & Surfaces ---
  static const Color darkBackground = Color(0xFF060D1E); // Obsidian Midnight
  static const Color darkSurface = Color(0xFF0F1B35);    // Translucent Dark Card
  static const Color darkSurfaceVariant = Color(0xFF162544);
  static const Color darkBorder = Color(0xFF1E3258);     // Micro Border
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
}
