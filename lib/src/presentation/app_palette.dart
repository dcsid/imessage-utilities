import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  // Warm paper / cream system. Nothing here is pure white or pure gray —
  // every neutral has a slight warm cast so the cards feel printed, not
  // drawn by a CSS framework.
  static const Color canvas = Color(0xFFF6EDDC);
  static const Color canvasDeep = Color(0xFFEFE3CB);
  static const Color surface = Color(0xFFFFFBF2);
  static const Color surfaceMuted = Color(0xFFF1E6CF);

  static const Color ink = Color(0xFF1A1410);
  static const Color text = ink;
  static const Color mutedText = Color(0xFF6F5E50);
  static const Color faintText = Color(0xFF9C8A7A);

  // The thick "stroke" we draw around sticker cards.
  static const Color border = Color(0xFF231A12);
  static const Color borderSoft = Color(0xFFE0CFB1);

  // Default app accent — warm coral. Used when no per-outing accent is in scope.
  static const Color primary = Color(0xFFE8553D);
  static const Color primarySoft = Color(0xFFFBE0D5);
  static const Color primaryInk = Color(0xFF6B1F12);

  static const Color success = Color(0xFF2F7A4D);
  static const Color successSoft = Color(0xFFD5ECDD);
  static const Color warning = Color(0xFFD68A1F);
  static const Color warningSoft = Color(0xFFF7E3B6);
  static const Color danger = Color(0xFFB23A3A);

  // Decorative accents used for per-outing color identity. Picked to be
  // distinctive next to each other on a cream canvas — not a generic
  // rainbow.
  static const List<OutingAccent> outingAccents = [
    OutingAccent(
      name: 'sunset',
      base: Color(0xFFE8553D),
      soft: Color(0xFFFBE0D5),
      ink: Color(0xFF6B1F12),
    ),
    OutingAccent(
      name: 'cobalt',
      base: Color(0xFF2C4FB8),
      soft: Color(0xFFD8E0F4),
      ink: Color(0xFF152663),
    ),
    OutingAccent(
      name: 'fern',
      base: Color(0xFF2F7A4D),
      soft: Color(0xFFD5ECDD),
      ink: Color(0xFF13391F),
    ),
    OutingAccent(
      name: 'plum',
      base: Color(0xFF7B3F8C),
      soft: Color(0xFFE9DAEE),
      ink: Color(0xFF3A1B43),
    ),
    OutingAccent(
      name: 'marigold',
      base: Color(0xFFD68A1F),
      soft: Color(0xFFF7E3B6),
      ink: Color(0xFF5C3A07),
    ),
    OutingAccent(
      name: 'teal',
      base: Color(0xFF1F7E80),
      soft: Color(0xFFD0E7E7),
      ink: Color(0xFF0C3535),
    ),
    OutingAccent(
      name: 'rose',
      base: Color(0xFFC4426F),
      soft: Color(0xFFF4D5DF),
      ink: Color(0xFF5C172E),
    ),
    OutingAccent(
      name: 'pine',
      base: Color(0xFF2A5F4A),
      soft: Color(0xFFD2E3DA),
      ink: Color(0xFF112A20),
    ),
  ];

  /// Deterministic per-outing accent based on the outing id. Two outings
  /// with the same id always get the same color, so the visual identity
  /// is stable across sessions.
  static OutingAccent accentFor(String seed) {
    if (seed.isEmpty) {
      return outingAccents.first;
    }
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return outingAccents[hash % outingAccents.length];
  }
}

@immutable
class OutingAccent {
  const OutingAccent({
    required this.name,
    required this.base,
    required this.soft,
    required this.ink,
  });

  final String name;

  /// Saturated brand color — used for headers, CTAs, the live dot.
  final Color base;

  /// Tinted background companion — used for soft fills behind ink text.
  final Color soft;

  /// Darkened version that reads as ink on top of [soft].
  final Color ink;
}
