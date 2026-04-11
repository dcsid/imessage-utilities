import Flutter
import MapKit
import CoreLocation
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var tripPlacesBridge: TripPlacesBridge?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
      return
    }
    tripPlacesBridge = TripPlacesBridge(
      binaryMessenger: flutterViewController.binaryMessenger
    )
  }
}

private final class TripPlacesBridge: NSObject {
  private let channel: FlutterMethodChannel
  private let geocoder = CLGeocoder()

  init(binaryMessenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "chat_utilities_hub/trip_places",
      binaryMessenger: binaryMessenger
    )
    super.init()
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "searchPlaces":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: "Missing search arguments.", details: nil))
        return
      }
      searchPlaces(arguments: arguments, result: result)
    case "reverseGeocode":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "bad_args", message: "Missing reverse geocode arguments.", details: nil))
        return
      }
      reverseGeocode(arguments: arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func searchPlaces(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let query = (arguments["query"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
          !query.isEmpty else {
      result([])
      return
    }

    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    if let coordinate = coordinateFrom(arguments: arguments) {
      request.region = MKCoordinateRegion(
        center: coordinate,
        latitudinalMeters: 12000,
        longitudinalMeters: 12000
      )
    }

    let search = MKLocalSearch(request: request)
    search.start { [weak self] response, error in
      guard let self else {
        result([])
        return
      }
      if let error {
        result(FlutterError(
          code: "search_failed",
          message: "Apple Maps search failed.",
          details: error.localizedDescription
        ))
        return
      }

      let items = response?.mapItems ?? []
      result(Array(items.prefix(8)).map(self.dictionaryForMapItem))
    }
  }

  private func reverseGeocode(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let coordinate = coordinateFrom(arguments: arguments) else {
      result(nil)
      return
    }

    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
      guard let self else {
        result(nil)
        return
      }

      if let error {
        result(FlutterError(
          code: "reverse_geocode_failed",
          message: "Apple Maps reverse geocode failed.",
          details: error.localizedDescription
        ))
        return
      }

      guard let placemark = placemarks?.first else {
        result(nil)
        return
      }

      let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
      result(self.dictionaryForMapItem(mapItem))
    }
  }

  private func coordinateFrom(arguments: [String: Any]) -> CLLocationCoordinate2D? {
    guard let latitude = (arguments["latitude"] as? NSNumber)?.doubleValue,
          let longitude = (arguments["longitude"] as? NSNumber)?.doubleValue else {
      return nil
    }

    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  private func dictionaryForMapItem(_ item: MKMapItem) -> [String: Any] {
    let title = primaryTitle(for: item)
    let subtitle = subtitleForPlacemark(item.placemark)
    return [
      "title": title,
      "subtitle": subtitle,
      "latitude": item.placemark.coordinate.latitude,
      "longitude": item.placemark.coordinate.longitude,
    ]
  }

  private func primaryTitle(for item: MKMapItem) -> String {
    if let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
       !name.isEmpty {
      return name
    }

    if let thoroughfare = item.placemark.thoroughfare,
       !thoroughfare.isEmpty {
      return thoroughfare
    }

    return "Pinned place"
  }

  private func subtitleForPlacemark(_ placemark: MKPlacemark) -> String {
    let street = [placemark.subThoroughfare, placemark.thoroughfare]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    let locality = [placemark.locality, placemark.administrativeArea, placemark.postalCode]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: ", ")

    return [street, locality]
      .filter { !$0.isEmpty }
      .joined(separator: " • ")
  }
}
