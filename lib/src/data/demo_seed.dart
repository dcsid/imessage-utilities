import 'package:chat_utilities_hub/src/models/expense_entry.dart';
import 'package:chat_utilities_hub/src/models/geo_point.dart';
import 'package:chat_utilities_hub/src/models/trip_stop.dart';
import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/models/utility_response.dart';

/// Sample outings shown to anyone who picks "Browse demo" on the auth
/// screen. The outings cover the four product highlights — locked-in
/// time, trip planning, expense settle-up, and the archive — so a
/// resume reviewer can see the full surface in under a minute.
List<UtilityInstance> buildDemoOutings({DateTime? now}) {
  final today = (now ?? DateTime.now()).toLocal();
  final base = DateTime(today.year, today.month, today.day);

  return [
    _lakesideBrunch(base),
    _charlottesvilleWeekend(base),
    _movieNight(base),
    _winterRetreat(base),
  ];
}

UtilityInstance _lakesideBrunch(DateTime today) {
  // Saturday a week out — locked, with a planned stop.
  final saturday = today.add(Duration(days: 7 - today.weekday + 6));
  final start = saturday.add(const Duration(days: 0));
  final options = _buildOptions(
    utilityId: 'demo-brunch',
    startDate: start,
    dayCount: 3,
    dayStart: const Duration(hours: 9),
    dayEnd: const Duration(hours: 14),
    intervalMinutes: 30,
  );
  // Pick a winning slot — Saturday 11:30
  final winningOption = options.firstWhere(
    (o) =>
        o.startAt?.weekday == DateTime.saturday &&
        o.startAt?.hour == 11 &&
        o.startAt?.minute == 30,
    orElse: () => options[options.length ~/ 2],
  );

  return UtilityInstance(
    id: 'demo-brunch',
    title: 'Lakeside Brunch',
    createdBy: 'Demo',
    participants: const ['Demo', 'Alex', 'Priya', 'Sam'],
    options: options,
    responses: [
      UtilityResponse(
        participantName: 'Demo',
        respondedAt: today.subtract(const Duration(days: 2)),
        selectedOptionIds: {
          winningOption.id,
          ..._neighbors(options, winningOption, 4),
        },
      ),
      UtilityResponse(
        participantName: 'Alex',
        respondedAt: today.subtract(const Duration(days: 2)),
        selectedOptionIds: {
          winningOption.id,
          ..._neighbors(options, winningOption, 3),
        },
      ),
      UtilityResponse(
        participantName: 'Priya',
        respondedAt: today.subtract(const Duration(days: 1)),
        selectedOptionIds: {
          winningOption.id,
          ..._neighbors(options, winningOption, 2),
        },
      ),
    ],
    plannedStops: const [
      TripStop(
        id: 'demo-brunch-stop-1',
        title: 'Boar\'s Head Resort',
        address: '200 Ednam Dr, Charlottesville, VA 22903',
        position: GeoPoint(latitude: 38.0257, longitude: -78.5453),
        order: 1,
      ),
    ],
    closesAt: start.add(const Duration(days: 3)),
    lockedOptionId: winningOption.id,
  );
}

UtilityInstance _charlottesvilleWeekend(DateTime today) {
  // Long weekend two weeks out — trip planning + expenses + settle-up.
  final friday = today.add(Duration(days: 14 - today.weekday + 5));
  final options = _buildOptions(
    utilityId: 'demo-cville',
    startDate: friday,
    dayCount: 3,
    dayStart: const Duration(hours: 8),
    dayEnd: const Duration(hours: 22),
    intervalMinutes: 60,
  );
  final winningOption = options.firstWhere(
    (o) => o.startAt?.weekday == DateTime.saturday && o.startAt?.hour == 18,
    orElse: () => options.first,
  );

  return UtilityInstance(
    id: 'demo-cville',
    title: 'Charlottesville Weekend',
    createdBy: 'Demo',
    participants: const ['Demo', 'Alex', 'Priya', 'Sam', 'Maya'],
    options: options,
    responses: [
      UtilityResponse(
        participantName: 'Demo',
        respondedAt: today.subtract(const Duration(days: 3)),
        selectedOptionIds: _multipleNeighbors(options, winningOption, 6),
      ),
      UtilityResponse(
        participantName: 'Alex',
        respondedAt: today.subtract(const Duration(days: 2)),
        selectedOptionIds: _multipleNeighbors(options, winningOption, 5),
      ),
      UtilityResponse(
        participantName: 'Priya',
        respondedAt: today.subtract(const Duration(days: 1)),
        selectedOptionIds: _multipleNeighbors(options, winningOption, 4),
      ),
      UtilityResponse(
        participantName: 'Sam',
        respondedAt: today.subtract(const Duration(hours: 8)),
        selectedOptionIds: _multipleNeighbors(options, winningOption, 5),
      ),
    ],
    plannedStops: const [
      TripStop(
        id: 'demo-cville-stop-1',
        title: 'Monticello',
        address: '931 Thomas Jefferson Pkwy, Charlottesville, VA 22902',
        position: GeoPoint(latitude: 38.0095, longitude: -78.4533),
        order: 1,
      ),
      TripStop(
        id: 'demo-cville-stop-2',
        title: 'Pippin Hill Farm & Vineyards',
        address: '5022 Plank Rd, North Garden, VA 22959',
        position: GeoPoint(latitude: 37.9384, longitude: -78.6147),
        order: 2,
      ),
      TripStop(
        id: 'demo-cville-stop-3',
        title: 'The Local',
        address: '824 Hinton Ave, Charlottesville, VA 22902',
        position: GeoPoint(latitude: 38.0238, longitude: -78.4763),
        order: 3,
        note: 'Reservation at 7pm',
      ),
    ],
    expenseTrackingEnabled: true,
    expenses: [
      ExpenseEntry(
        id: 'demo-cville-exp-1',
        title: 'Airbnb',
        amount: 480.00,
        paidBy: 'Sam',
        splitBetween: const ['Demo', 'Alex', 'Priya', 'Sam', 'Maya'],
        addedAt: today.subtract(const Duration(days: 4)),
      ),
      ExpenseEntry(
        id: 'demo-cville-exp-2',
        title: 'Vineyard tasting',
        amount: 165.00,
        paidBy: 'Demo',
        splitBetween: const ['Demo', 'Alex', 'Priya', 'Sam', 'Maya'],
        addedAt: today.subtract(const Duration(days: 2)),
      ),
      ExpenseEntry(
        id: 'demo-cville-exp-3',
        title: 'Dinner at The Local',
        amount: 248.50,
        paidBy: 'Priya',
        splitBetween: const ['Demo', 'Alex', 'Priya', 'Sam'],
        addedAt: today.subtract(const Duration(days: 1)),
        note: 'Maya skipped — vegetarian menu didn\'t work for her',
      ),
      ExpenseEntry(
        id: 'demo-cville-exp-4',
        title: 'Gas (round trip)',
        amount: 72.00,
        paidBy: 'Alex',
        splitBetween: const ['Demo', 'Alex', 'Priya', 'Sam', 'Maya'],
        addedAt: today.subtract(const Duration(hours: 18)),
      ),
    ],
    closesAt: friday.add(const Duration(days: 3)),
  );
}

UtilityInstance _movieNight(DateTime today) {
  // Mid-week, ongoing — no lock yet, just gathering responses.
  final wednesday = today.add(
    Duration(days: ((3 - today.weekday) % 7)),
  ); // upcoming Wed
  final options = _buildOptions(
    utilityId: 'demo-movie',
    startDate: wednesday,
    dayCount: 3,
    dayStart: const Duration(hours: 18),
    dayEnd: const Duration(hours: 23),
    intervalMinutes: 30,
  );
  final centerOption = options[options.length ~/ 2];

  return UtilityInstance(
    id: 'demo-movie',
    title: 'Movie Night',
    createdBy: 'Demo',
    participants: const ['Demo', 'Alex', 'Sam'],
    options: options,
    responses: [
      UtilityResponse(
        participantName: 'Demo',
        respondedAt: today.subtract(const Duration(hours: 6)),
        selectedOptionIds: _multipleNeighbors(options, centerOption, 4),
      ),
      UtilityResponse(
        participantName: 'Alex',
        respondedAt: today.subtract(const Duration(hours: 4)),
        selectedOptionIds: _multipleNeighbors(options, centerOption, 3),
      ),
    ],
    closesAt: wednesday.add(const Duration(days: 3)),
  );
}

UtilityInstance _winterRetreat(DateTime today) {
  // A wrapped-up outing in the past — populates the archive shelf.
  final pastFriday = today.subtract(const Duration(days: 21));
  final options = _buildOptions(
    utilityId: 'demo-retreat',
    startDate: pastFriday,
    dayCount: 3,
    dayStart: const Duration(hours: 8),
    dayEnd: const Duration(hours: 22),
    intervalMinutes: 60,
  );
  final lockedOption = options.firstWhere(
    (o) => o.startAt?.hour == 16,
    orElse: () => options.first,
  );

  return UtilityInstance(
    id: 'demo-retreat',
    title: 'Winter Cabin Retreat',
    createdBy: 'Demo',
    participants: const ['Demo', 'Alex', 'Priya', 'Sam'],
    options: options,
    responses: [
      UtilityResponse(
        participantName: 'Demo',
        respondedAt: pastFriday.subtract(const Duration(days: 5)),
        selectedOptionIds: {
          lockedOption.id,
          ..._neighbors(options, lockedOption, 4),
        },
      ),
      UtilityResponse(
        participantName: 'Alex',
        respondedAt: pastFriday.subtract(const Duration(days: 4)),
        selectedOptionIds: {
          lockedOption.id,
          ..._neighbors(options, lockedOption, 3),
        },
      ),
      UtilityResponse(
        participantName: 'Priya',
        respondedAt: pastFriday.subtract(const Duration(days: 4)),
        selectedOptionIds: {
          lockedOption.id,
          ..._neighbors(options, lockedOption, 2),
        },
      ),
      UtilityResponse(
        participantName: 'Sam',
        respondedAt: pastFriday.subtract(const Duration(days: 3)),
        selectedOptionIds: {
          lockedOption.id,
          ..._neighbors(options, lockedOption, 5),
        },
      ),
    ],
    plannedStops: const [
      TripStop(
        id: 'demo-retreat-stop-1',
        title: 'Massanutten Resort',
        address: '1822 Resort Dr, Massanutten, VA 22840',
        position: GeoPoint(latitude: 38.4123, longitude: -78.7570),
        order: 1,
      ),
    ],
    closesAt: pastFriday.add(const Duration(days: 3)),
    lockedOptionId: lockedOption.id,
  );
}

// ---- helpers ----

List<UtilityOption> _buildOptions({
  required String utilityId,
  required DateTime startDate,
  required int dayCount,
  required Duration dayStart,
  required Duration dayEnd,
  required int intervalMinutes,
}) {
  final options = <UtilityOption>[];
  var sortOrder = 1;
  for (var dayIndex = 0; dayIndex < dayCount; dayIndex++) {
    final day = startDate.add(Duration(days: dayIndex));
    var cursor = dayStart;
    while (cursor < dayEnd) {
      final startAt = day.add(cursor);
      final endAt = startAt.add(Duration(minutes: intervalMinutes));
      options.add(
        UtilityOption(
          id: '$utilityId-$sortOrder',
          title: _formatDayTitle(day),
          subtitle: '${_formatTime(startAt)} - ${_formatTime(endAt)}',
          sortOrder: sortOrder,
          startAt: startAt,
          endAt: endAt,
        ),
      );
      sortOrder += 1;
      cursor += Duration(minutes: intervalMinutes);
    }
  }
  return options;
}

Set<String> _neighbors(
  List<UtilityOption> options,
  UtilityOption pivot,
  int radius,
) {
  final pivotIndex = options.indexOf(pivot);
  if (pivotIndex == -1) return {};
  final start = (pivotIndex - radius).clamp(0, options.length - 1);
  final end = (pivotIndex + radius).clamp(0, options.length - 1);
  return {for (var i = start; i <= end; i++) options[i].id};
}

Set<String> _multipleNeighbors(
  List<UtilityOption> options,
  UtilityOption pivot,
  int radius,
) {
  return _neighbors(options, pivot, radius);
}

String _formatDayTitle(DateTime day) {
  const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdayLabels[day.weekday - 1]}, ${monthLabels[day.month - 1]} ${day.day}';
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
