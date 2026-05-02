import 'package:chat_utilities_hub/src/services/calendar_export_service_io.dart'
    if (dart.library.html) 'package:chat_utilities_hub/src/services/calendar_export_service_web.dart'
    as impl;

/// Platform-neutral facade for "add this locked time to my calendar."
/// On iOS the implementation pops the native EKEventEditViewController via
/// `add_2_calendar`. On web it generates an RFC 5545 .ics file and triggers
/// a browser download.
abstract class CalendarExportService {
  static final CalendarExportService instance = impl
      .createCalendarExportService();

  Future<bool> exportEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    String? location,
  });
}
