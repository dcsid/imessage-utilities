import 'package:chat_utilities_hub/src/models/planning_board_draft.dart';

class UtilityLink {
  const UtilityLink._();

  static const String scheme = 'chatutilitieshub';
  static const String utilityHost = 'utility';
  static const String composeHost = 'compose';

  static Uri forUtility(String utilityId, {String? kind}) {
    return Uri(
      scheme: scheme,
      host: utilityHost,
      pathSegments: [utilityId],
      queryParameters: kind == null ? null : {'kind': kind},
    );
  }

  static Uri forComposeDraft({
    String? title,
    String? prompt,
    String? createdBy,
    List<String> participants = const <String>[],
  }) {
    final normalizedParticipants = participants
        .map((participant) => participant.trim())
        .where((participant) => participant.isNotEmpty)
        .toList(growable: false);
    final queryParameters = <String, String>{};
    if (title != null && title.trim().isNotEmpty) {
      queryParameters['title'] = title.trim();
    }
    if (prompt != null && prompt.trim().isNotEmpty) {
      queryParameters['prompt'] = prompt.trim();
    }
    if (createdBy != null && createdBy.trim().isNotEmpty) {
      queryParameters['createdBy'] = createdBy.trim();
    }
    if (normalizedParticipants.isNotEmpty) {
      queryParameters['participants'] = normalizedParticipants.join(',');
    }

    return Uri(
      scheme: scheme,
      host: composeHost,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  static String? parseUtilityId(String rawLink) {
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null) {
      return null;
    }
    final segments = normalizedSegments(uri);
    if (segments.length < 2 || segments.first != utilityHost) {
      return null;
    }

    return segments[1];
  }

  static PlanningBoardDraft? parseComposeDraft(String rawLink) {
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null) {
      return null;
    }

    final segments = normalizedSegments(uri);
    if (segments.isEmpty || segments.first != composeHost) {
      return null;
    }

    final participants = (uri.queryParameters['participants'] ?? '')
        .split(',')
        .map((participant) => participant.trim())
        .where((participant) => participant.isNotEmpty)
        .toList(growable: false);

    return PlanningBoardDraft(
      title: uri.queryParameters['title'],
      prompt: uri.queryParameters['prompt'],
      createdBy: uri.queryParameters['createdBy'],
      participants: participants,
    );
  }

  static List<String> normalizedSegments(Uri uri) {
    final pathSegments = uri.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      return pathSegments.toList(growable: false);
    }

    return [uri.host, ...pathSegments];
  }
}
