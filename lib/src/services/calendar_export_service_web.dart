// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:chat_utilities_hub/src/services/calendar_export_service.dart';

CalendarExportService createCalendarExportService() =>
    const _WebCalendarExportService();

class _WebCalendarExportService implements CalendarExportService {
  const _WebCalendarExportService();

  @override
  Future<bool> exportEvent({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    String? location,
  }) async {
    final ics = _buildIcs(
      title: title,
      description: description,
      start: start,
      end: end,
      location: location,
    );

    final blob = html.Blob(<Object>[ics], 'text/calendar;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = '${_slug(title)}.ics'
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return true;
  }

  String _buildIcs({
    required String title,
    required String description,
    required DateTime start,
    required DateTime end,
    String? location,
  }) {
    final stamp = _formatUtc(DateTime.now().toUtc());
    final dtStart = _formatUtc(start.toUtc());
    final dtEnd = _formatUtc(end.toUtc());
    final uid = '$stamp-${title.hashCode}@plantogether';
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Plan Together//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:$stamp',
      'DTSTART:$dtStart',
      'DTEND:$dtEnd',
      'SUMMARY:${_escape(title)}',
      'DESCRIPTION:${_escape(description)}',
      if (location != null && location.isNotEmpty)
        'LOCATION:${_escape(location)}',
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    // RFC 5545 mandates CRLF line endings.
    return '${lines.join('\r\n')}\r\n';
  }

  String _formatUtc(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$hh$mm${ss}Z';
  }

  // RFC 5545 §3.3.11: backslash, comma, semicolon, and newline must be escaped.
  String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;')
        .replaceAll('\n', r'\n');
  }

  String _slug(String value) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isEmpty ? 'outing' : cleaned;
  }
}
