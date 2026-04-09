enum LocationShareMode {
  live,
  every15Minutes,
  every30Minutes,
  hourly,
}

extension LocationShareModeX on LocationShareMode {
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
        return 'Updates continuously while the trip is active.';
      case LocationShareMode.every15Minutes:
        return 'Shares a fresh check-in every 15 minutes.';
      case LocationShareMode.every30Minutes:
        return 'Shares a fresh check-in every 30 minutes.';
      case LocationShareMode.hourly:
        return 'Shares a fresh check-in every hour.';
    }
  }
}
