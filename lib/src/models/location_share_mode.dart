enum LocationShareMode {
  live,
  every15Minutes,
  every30Minutes,
  hourly,
}

extension LocationShareModeX on LocationShareMode {
  Duration get publishInterval {
    switch (this) {
      case LocationShareMode.live:
        return const Duration(seconds: 20);
      case LocationShareMode.every15Minutes:
        return const Duration(minutes: 15);
      case LocationShareMode.every30Minutes:
        return const Duration(minutes: 30);
      case LocationShareMode.hourly:
        return const Duration(hours: 1);
    }
  }

  String get label {
    switch (this) {
      case LocationShareMode.live:
        return 'Live';
      case LocationShareMode.every15Minutes:
        return '15 min';
      case LocationShareMode.every30Minutes:
        return '30 min';
      case LocationShareMode.hourly:
        return 'Hourly';
    }
  }

  String get description {
    switch (this) {
      case LocationShareMode.live:
        return 'Sends GPS updates automatically while the trip is active.';
      case LocationShareMode.every15Minutes:
        return 'Sends a GPS check-in roughly every 15 minutes.';
      case LocationShareMode.every30Minutes:
        return 'Sends a GPS check-in roughly every 30 minutes.';
      case LocationShareMode.hourly:
        return 'Sends a GPS check-in roughly every hour.';
    }
  }
}
