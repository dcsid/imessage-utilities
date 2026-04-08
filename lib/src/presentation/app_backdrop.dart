import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:flutter/material.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppPalette.canvas, AppPalette.canvasTint],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          top: -140,
          left: -80,
          child: _GlowOrb(
            size: 320,
            colors: [
              AppPalette.gold.withValues(alpha: 0.28),
              AppPalette.gold.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned(
          top: 120,
          right: -120,
          child: _GlowOrb(
            size: 360,
            colors: [
              AppPalette.sky.withValues(alpha: 0.28),
              AppPalette.sky.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned(
          bottom: -160,
          left: 60,
          child: _GlowOrb(
            size: 300,
            colors: [
              AppPalette.lime.withValues(alpha: 0.22),
              AppPalette.lime.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned(
          bottom: 80,
          right: 40,
          child: _GlowOrb(
            size: 220,
            colors: [
              AppPalette.coral.withValues(alpha: 0.18),
              AppPalette.coral.withValues(alpha: 0),
            ],
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
