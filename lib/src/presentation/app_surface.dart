import 'dart:math' as math;

import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:flutter/material.dart';

/// A "sticker" card. Slight off-axis dark drop, thick ink stroke,
/// optional colored bloom tinted by [accent]. Used everywhere the old
/// flat AppSurface was used, so reskinning here propagates across all
/// existing screens.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin,
    this.fillColor,
    this.radius = 26,
    this.accent,
    this.elevated = true,
    this.strokeWidth = 1.6,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? fillColor;
  final double radius;
  final OutingAccent? accent;
  final bool elevated;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final bloom = (accent?.base ?? AppPalette.primary).withValues(alpha: 0.18);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: fillColor ?? AppPalette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.border, width: strokeWidth),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppPalette.border.withValues(alpha: 0.95),
                  offset: const Offset(4, 5),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: bloom,
                  offset: const Offset(0, 18),
                  blurRadius: 36,
                  spreadRadius: -8,
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Hero block at the top of an outing card. Gradient fill in the
/// outing's accent, big editorial title, optional eyebrow + trailing
/// glyph slot.
class StickerHeader extends StatelessWidget {
  const StickerHeader({
    super.key,
    required this.title,
    required this.accent,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 24),
    this.radius = 26,
  });

  final String title;
  final OutingAccent accent;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.base,
            Color.lerp(accent.base, accent.ink, 0.35) ?? accent.base,
          ],
        ),
      ),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null)
                    Text(
                      eyebrow!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  if (eyebrow != null) const SizedBox(height: 10),
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Decorative geometric glyph used as a "logo" for an outing — sits in
/// the top-right of the StickerHeader. Different shape per accent so two
/// outings don't read identical.
class OutingGlyph extends StatelessWidget {
  const OutingGlyph({
    super.key,
    required this.accent,
    this.size = 44,
  });

  final OutingAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      child: CustomPaint(painter: _GlyphPainter(shape: _shapeFor(accent.name))),
    );
  }

  _GlyphShape _shapeFor(String name) {
    switch (name) {
      case 'sunset':
        return _GlyphShape.arc;
      case 'cobalt':
        return _GlyphShape.diamond;
      case 'fern':
        return _GlyphShape.leaf;
      case 'plum':
        return _GlyphShape.star;
      case 'marigold':
        return _GlyphShape.sun;
      case 'teal':
        return _GlyphShape.wave;
      case 'rose':
        return _GlyphShape.heart;
      case 'pine':
      default:
        return _GlyphShape.triangle;
    }
  }
}

enum _GlyphShape { arc, diamond, leaf, star, sun, wave, heart, triangle }

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.shape});

  final _GlyphShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28;

    switch (shape) {
      case _GlyphShape.arc:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy + r * 0.4), radius: r),
          3.7,
          1.9,
          false,
          stroke,
        );
        canvas.drawCircle(Offset(cx, cy - r * 0.2), 2.2, fill);
        break;
      case _GlyphShape.diamond:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(path, stroke);
        break;
      case _GlyphShape.leaf:
        final path = Path()
          ..moveTo(cx - r * 0.8, cy + r * 0.6)
          ..quadraticBezierTo(cx - r, cy - r, cx + r * 0.6, cy - r * 0.7)
          ..quadraticBezierTo(cx + r, cy + r * 0.4, cx - r * 0.8, cy + r * 0.6);
        canvas.drawPath(path, stroke);
        break;
      case _GlyphShape.star:
        for (var i = 0; i < 5; i++) {
          final angle = -math.pi / 2 + i * (2 * math.pi / 5);
          final point = Offset(
            cx + r * 1.05 * math.cos(angle),
            cy + r * 1.05 * math.sin(angle),
          );
          canvas.drawCircle(point, 1.8, fill);
        }
        canvas.drawCircle(Offset(cx, cy), r * 0.45, stroke);
        break;
      case _GlyphShape.sun:
        canvas.drawCircle(Offset(cx, cy), r * 0.55, stroke);
        for (var i = 0; i < 8; i++) {
          final angle = i * (math.pi / 4);
          final start = Offset(
            cx + r * 0.8 * math.cos(angle),
            cy + r * 0.8 * math.sin(angle),
          );
          final end = Offset(
            cx + r * 1.05 * math.cos(angle),
            cy + r * 1.05 * math.sin(angle),
          );
          canvas.drawLine(start, end, stroke);
        }
        break;
      case _GlyphShape.wave:
        final path = Path()..moveTo(cx - r, cy);
        for (var i = 0; i <= 8; i++) {
          final x = cx - r + (2 * r) * (i / 8);
          final y = cy + (i.isEven ? -r * 0.3 : r * 0.3);
          path.lineTo(x, y);
        }
        canvas.drawPath(path, stroke);
        break;
      case _GlyphShape.heart:
        final path = Path()
          ..moveTo(cx, cy + r * 0.7)
          ..cubicTo(
            cx - r * 1.4,
            cy - r * 0.2,
            cx - r * 0.4,
            cy - r * 1.1,
            cx,
            cy - r * 0.3,
          )
          ..cubicTo(
            cx + r * 0.4,
            cy - r * 1.1,
            cx + r * 1.4,
            cy - r * 0.2,
            cx,
            cy + r * 0.7,
          );
        canvas.drawPath(path, stroke);
        break;
      case _GlyphShape.triangle:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.95, cy + r * 0.7)
          ..lineTo(cx - r * 0.95, cy + r * 0.7)
          ..close();
        canvas.drawPath(path, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.shape != shape;
}
