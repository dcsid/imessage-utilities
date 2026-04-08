import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:flutter/material.dart';

Color utilityKindColor(UtilityKind kind) {
  switch (kind) {
    case UtilityKind.availability:
      return const Color(0xFF007AFF);
    case UtilityKind.poll:
      return const Color(0xFFFF9F0A);
    case UtilityKind.checklist:
      return const Color(0xFF34C759);
    case UtilityKind.picks:
      return const Color(0xFF5AC8FA);
  }
}

IconData utilityKindIcon(UtilityKind kind) {
  switch (kind) {
    case UtilityKind.availability:
      return Icons.calendar_view_week_rounded;
    case UtilityKind.poll:
      return Icons.restaurant_rounded;
    case UtilityKind.checklist:
      return Icons.checklist_rounded;
    case UtilityKind.picks:
      return Icons.forum_rounded;
  }
}
