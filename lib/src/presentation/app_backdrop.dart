import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:flutter/material.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppPalette.canvas,
      child: child,
    );
  }
}
