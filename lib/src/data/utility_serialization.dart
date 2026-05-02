import 'dart:convert';

import 'package:chat_utilities_hub/src/models/expense_entry.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/location_share_mode.dart';
import 'package:chat_utilities_hub/src/models/participant_location_share.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

String encodeUtilities(List<UtilityInstance> utilities) {
  final payload = utilities.map(utilityToMap).toList(growable: false);
  return jsonEncode(payload);
}

List<UtilityInstance> decodeUtilities(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <UtilityInstance>[];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(utilityFromMap)
        .toList(growable: false);
  } on FormatException {
    return const <UtilityInstance>[];
  }
}

String encodeUtility(UtilityInstance utility) =>
    jsonEncode(utilityToMap(utility));

UtilityInstance? decodeUtility(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return utilityFromMap(decoded);
  } on FormatException {
    return null;
  }
}

Map<String, dynamic> utilityToMap(UtilityInstance utility) {
  return <String, dynamic>{
    'id': utility.id,
    'title': utility.title,
    'createdBy': utility.createdBy,
    'participants': utility.participants,
    'options': utility.options.map(optionToMap).toList(growable: false),
    'responses': utility.responses.map(responseToMap).toList(growable: false),
    'expenseTrackingEnabled': utility.expenseTrackingEnabled,
    'expenses': utility.expenses.map(expenseToMap).toList(growable: false),
    'plannedStops': utility.plannedStops
        .map(tripStopToMap)
        .toList(growable: false),
    'locationShares': utility.locationShares
        .map(locationShareToMap)
        .toList(growable: false),
    'closesAt': utility.closesAt?.toIso8601String(),
    'lockedOptionId': utility.lockedOptionId,
  };
}

UtilityInstance utilityFromMap(Map<String, dynamic> map) {
  return UtilityInstance(
    id: map['id'] as String,
    title: map['title'] as String,
    createdBy: map['createdBy'] as String,
    participants: (map['participants'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList(growable: false),
    options: (map['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(optionFromMap)
        .toList(growable: false),
    responses: (map['responses'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(responseFromMap)
        .toList(growable: false),
    expenseTrackingEnabled: (map['expenseTrackingEnabled'] as bool?) ?? false,
    expenses: (map['expenses'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(expenseFromMap)
        .toList(growable: false),
    plannedStops: (map['plannedStops'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(tripStopFromMap)
        .toList(growable: false),
    locationShares:
        (map['locationShares'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(locationShareFromMap)
            .toList(growable: false),
    closesAt: parseDateTime(map['closesAt'] as String?),
    lockedOptionId: map['lockedOptionId'] as String?,
  );
}

Map<String, dynamic> optionToMap(UtilityOption option) {
  return <String, dynamic>{
    'id': option.id,
    'title': option.title,
    'subtitle': option.subtitle,
    'sortOrder': option.sortOrder,
    'startAt': option.startAt?.toIso8601String(),
    'endAt': option.endAt?.toIso8601String(),
  };
}

UtilityOption optionFromMap(Map<String, dynamic> map) {
  return UtilityOption(
    id: map['id'] as String,
    title: map['title'] as String,
    subtitle: map['subtitle'] as String,
    sortOrder: (map['sortOrder'] as num).toInt(),
    startAt: parseDateTime(map['startAt'] as String?),
    endAt: parseDateTime(map['endAt'] as String?),
  );
}

Map<String, dynamic> responseToMap(UtilityResponse response) {
  return <String, dynamic>{
    'participantName': response.participantName,
    'respondedAt': response.respondedAt.toIso8601String(),
    'selectedOptionIds': response.selectedOptionIds.toList(growable: false),
  };
}

UtilityResponse responseFromMap(Map<String, dynamic> map) {
  return UtilityResponse(
    participantName: map['participantName'] as String,
    respondedAt: parseDateTime(map['respondedAt'] as String?) ?? DateTime.now(),
    selectedOptionIds:
        (map['selectedOptionIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toSet(),
  );
}

Map<String, dynamic> tripStopToMap(TripStop stop) {
  return <String, dynamic>{
    'id': stop.id,
    'title': stop.title,
    'position': <String, dynamic>{
      'latitude': stop.position.latitude,
      'longitude': stop.position.longitude,
    },
    'order': stop.order,
    'address': stop.address,
    'note': stop.note,
  };
}

TripStop tripStopFromMap(Map<String, dynamic> map) {
  final position = map['position'] as Map<String, dynamic>;
  return TripStop(
    id: map['id'] as String,
    title: map['title'] as String,
    position: GeoPoint(
      latitude: (position['latitude'] as num).toDouble(),
      longitude: (position['longitude'] as num).toDouble(),
    ),
    order: (map['order'] as num).toInt(),
    address: map['address'] as String?,
    note: map['note'] as String?,
  );
}

Map<String, dynamic> locationShareToMap(ParticipantLocationShare share) {
  return <String, dynamic>{
    'participantName': share.participantName,
    'mode': share.mode.name,
    'stopId': share.stopId,
    'sharedAt': share.sharedAt.toIso8601String(),
    'statusMessage': share.statusMessage,
    'isBusy': share.isBusy,
  };
}

ParticipantLocationShare locationShareFromMap(Map<String, dynamic> map) {
  return ParticipantLocationShare(
    participantName: map['participantName'] as String,
    mode: LocationShareMode.values.byName(map['mode'] as String),
    stopId: map['stopId'] as String,
    sharedAt: parseDateTime(map['sharedAt'] as String?) ?? DateTime.now(),
    statusMessage: map['statusMessage'] as String?,
    isBusy: (map['isBusy'] as bool?) ?? false,
  );
}

Map<String, dynamic> expenseToMap(ExpenseEntry expense) {
  return <String, dynamic>{
    'id': expense.id,
    'title': expense.title,
    'amount': expense.amount,
    'paidBy': expense.paidBy,
    'splitBetween': expense.splitBetween,
    'addedAt': expense.addedAt.toIso8601String(),
    'note': expense.note,
  };
}

ExpenseEntry expenseFromMap(Map<String, dynamic> map) {
  return ExpenseEntry(
    id: map['id'] as String,
    title: map['title'] as String,
    amount: (map['amount'] as num).toDouble(),
    paidBy: map['paidBy'] as String,
    splitBetween: (map['splitBetween'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList(growable: false),
    addedAt: parseDateTime(map['addedAt'] as String?) ?? DateTime.now(),
    note: map['note'] as String?,
  );
}

DateTime? parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}
