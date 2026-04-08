import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:flutter/material.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.fillColor,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? fillColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: fillColor ?? AppPalette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
