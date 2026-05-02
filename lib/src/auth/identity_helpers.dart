/// Derive a friendly display name from a Cognito userContact (email or
/// phone). Falls back to null when the contact is missing or we can't
/// produce something better than the raw string. Used to prefill the
/// "responding as" / "organizer" fields when a user is signed in.
String? displayNameFromContact(String? userContact) {
  if (userContact == null || userContact.isEmpty) {
    return null;
  }
  if (!userContact.contains('@')) {
    return null;
  }
  final localPart = userContact.split('@').first.trim();
  if (localPart.isEmpty) {
    return userContact;
  }
  return localPart
      .split(RegExp(r'[._-]+'))
      .where((chunk) => chunk.isNotEmpty)
      .map((chunk) => '${chunk[0].toUpperCase()}${chunk.substring(1)}')
      .join(' ');
}

/// Find the participant on this outing that best matches the signed-in
/// user, if any. Looks for exact display-name match against the derived
/// name and (case-insensitive) against the raw contact.
String? matchingParticipant(
  Iterable<String> participants,
  String? userContact,
) {
  if (userContact == null || userContact.isEmpty) {
    return null;
  }
  final derived = displayNameFromContact(userContact);
  final lowerContact = userContact.toLowerCase();
  for (final participant in participants) {
    final p = participant.trim();
    if (p.isEmpty) continue;
    if (derived != null && p.toLowerCase() == derived.toLowerCase()) {
      return p;
    }
    if (p.toLowerCase() == lowerContact) {
      return p;
    }
  }
  return null;
}
