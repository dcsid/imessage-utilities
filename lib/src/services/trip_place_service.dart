import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/trip_place_match.dart';
import 'package:chat_utilities_hub/src/services/mapbox_geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class TripPlaceService {
  const TripPlaceService();

  static const TripPlaceService instance = MethodChannelTripPlaceService();

  Future<List<TripPlaceMatch>> searchPlaces(String query, {GeoPoint? near});

  Future<TripPlaceMatch?> reverseGeocode(GeoPoint point);
}

class MethodChannelTripPlaceService extends TripPlaceService {
  const MethodChannelTripPlaceService();

  static const MethodChannel _channel = MethodChannel(
    'chat_utilities_hub/trip_places',
  );

  @override
  Future<List<TripPlaceMatch>> searchPlaces(
    String query, {
    GeoPoint? near,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      return const <TripPlaceMatch>[];
    }

    // Web has no MKLocalSearch; route through Mapbox geocoding instead.
    if (kIsWeb) {
      return mapboxSearchPlaces(trimmedQuery, near: near);
    }

    try {
      final response = await _channel
          .invokeListMethod<Object?>('searchPlaces', <String, Object?>{
            'query': trimmedQuery,
            'latitude': near?.latitude,
            'longitude': near?.longitude,
          });
      return response
              ?.whereType<Map<Object?, Object?>>()
              .map(TripPlaceMatch.fromMap)
              .toList(growable: false) ??
          const <TripPlaceMatch>[];
    } on MissingPluginException {
      return const <TripPlaceMatch>[];
    } on PlatformException catch (error) {
      debugPrint('Place search error: ${error.message}');
      return const <TripPlaceMatch>[];
    }
  }

  @override
  Future<TripPlaceMatch?> reverseGeocode(GeoPoint point) async {
    if (kIsWeb) {
      return mapboxReverseGeocode(point);
    }
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'reverseGeocode',
        <String, Object?>{
          'latitude': point.latitude,
          'longitude': point.longitude,
        },
      );
      if (response == null) {
        return null;
      }
      return TripPlaceMatch.fromMap(response);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      debugPrint('Reverse geocode error: ${error.message}');
      return null;
    }
  }
}
