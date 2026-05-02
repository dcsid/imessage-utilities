import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:chat_utilities_hub/src/services/calendar_export_service.dart';

CalendarExportService createCalendarExportService() =>
    const _NativeCalendarExportService();

class _NativeCalendarExportService implements CalendarExportService {
  const _NativeCalendarExportService();

  @override
  Future<bool> exportEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    String? location,
  }) {
    final event = Event(
      title: title,
      description: description,
      location: location,
      startDate: start,
      endDate: end,
    );
    return Add2Calendar.addEvent2Cal(event);
  }
}
