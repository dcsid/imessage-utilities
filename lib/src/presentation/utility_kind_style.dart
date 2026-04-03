import 'package:chat_utilities_hub/src/models/utility_kind.dart';
import 'package:flutter/material.dart';

Color utilityKindColor(UtilityKind kind) {
  switch (kind) {
    case UtilityKind.availability:
      return const Color(0xFF0D5C63);
    case UtilityKind.poll:
      return const Color(0xFF9A3412);
    case UtilityKind.checklist:
      return const Color(0xFF365314);
    case UtilityKind.picks:
      return const Color(0xFF5B21B6);
  }
}

IconData utilityKindIcon(UtilityKind kind) {
  switch (kind) {
    case UtilityKind.availability:
      return Icons.calendar_view_week_rounded;
    case UtilityKind.poll:
      return Icons.poll_rounded;
    case UtilityKind.checklist:
      return Icons.checklist_rounded;
    case UtilityKind.picks:
      return Icons.local_activity_rounded;
  }
}
