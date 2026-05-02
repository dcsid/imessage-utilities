import 'dart:convert';

import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/trip_place_match.dart';
import 'package:chat_utilities_hub/src/services/mapbox_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Mapbox forward geocoding ("places API"). Returns up to 8 candidate
/// matches. If no MAPBOX_TOKEN is configured at build time, returns an
/// empty list so the UI falls back to "no results" gracefully.
Future<List<TripPlaceMatch>> mapboxSearchPlaces(
  String query, {
  GeoPoint? near,
}) async {
  if (!hasMapboxToken) return const <TripPlaceMatch>[];
  final encoded = Uri.encodeComponent(query);
  final params = <String, String>{
    'access_token': mapboxToken,
    'limit': '8',
    'types': 'poi,address,place',
    if (near != null) 'proximity': '${near.longitude},${near.latitude}',
  };
  final uri = Uri.parse(
    'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json',
  ).replace(queryParameters: params);

  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint('Mapbox search ${response.statusCode}: ${response.body}');
      return const <TripPlaceMatch>[];
    }
    return _parseFeatures(response.body);
  } catch (error) {
    debugPrint('Mapbox search error: $error');
    return const <TripPlaceMatch>[];
  }
}

/// Mapbox reverse geocoding. Returns the best match for a coordinate, or
/// null if nothing is found / the token is missing.
Future<TripPlaceMatch?> mapboxReverseGeocode(GeoPoint point) async {
  if (!hasMapboxToken) return null;
  final params = <String, String>{
    'access_token': mapboxToken,
    'limit': '1',
    'types': 'poi,address,place',
  };
  final uri = Uri.parse(
    'https://api.mapbox.com/geocoding/v5/mapbox.places/${point.longitude},${point.latitude}.json',
  ).replace(queryParameters: params);

  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint('Mapbox reverse ${response.statusCode}: ${response.body}');
      return null;
    }
    final matches = _parseFeatures(response.body);
    return matches.isEmpty ? null : matches.first;
  } catch (error) {
    debugPrint('Mapbox reverse error: $error');
    return null;
  }
}

List<TripPlaceMatch> _parseFeatures(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) return const <TripPlaceMatch>[];
  final features = decoded['features'];
  if (features is! List) return const <TripPlaceMatch>[];

  final results = <TripPlaceMatch>[];
  for (final feature in features) {
    if (feature is! Map<String, dynamic>) continue;
    final geometry = feature['geometry'];
    if (geometry is! Map<String, dynamic>) continue;
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) continue;
    final lng = (coordinates[0] as num?)?.toDouble();
    final lat = (coordinates[1] as num?)?.toDouble();
    if (lat == null || lng == null) continue;

    final text = (feature['text'] as String?)?.trim() ?? '';
    final placeName = (feature['place_name'] as String?)?.trim() ?? '';
    // place_name typically begins with the title; strip it for the subtitle.
    final subtitle =
        placeName.startsWith(text) && placeName.length > text.length
        ? placeName.substring(text.length).replaceFirst(RegExp(r'^,\s*'), '')
        : placeName;

    results.add(
      TripPlaceMatch(
        title: text.isEmpty ? placeName : text,
        subtitle: subtitle,
        position: GeoPoint(latitude: lat, longitude: lng),
      ),
    );
  }
  return results;
}
