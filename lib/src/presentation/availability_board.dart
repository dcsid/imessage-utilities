import 'dart:math' as math;

import 'package:chat_utilities_hub/src/models/utility_instance.dart';
import 'package:chat_utilities_hub/src/models/utility_option.dart';
import 'package:chat_utilities_hub/src/presentation/app_palette.dart';
import 'package:chat_utilities_hub/src/presentation/date_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

enum AvailabilityBoardMode { aggregate, selection }

class AvailabilityBoard extends StatefulWidget {
  const AvailabilityBoard({
    super.key,
    required this.utility,
    required this.accent,
    this.compact = false,
    this.mode = AvailabilityBoardMode.aggregate,
    this.selectedOptionIds = const <String>{},
    this.onInteractionChanged,
    this.onSelectionChanged,
  });

  final UtilityInstance utility;
  final Color accent;
  final bool compact;
  final AvailabilityBoardMode mode;
  final Set<String> selectedOptionIds;
  final ValueChanged<bool>? onInteractionChanged;
  final ValueChanged<Set<String>>? onSelectionChanged;

  @override
  State<AvailabilityBoard> createState() => _AvailabilityBoardState();
}

class _AvailabilityBoardState extends State<AvailabilityBoard> {
  final GlobalKey _gridKey = GlobalKey();
  final List<ScrollHoldController> _scrollHoldControllers =
      <ScrollHoldController>[];
  int? _activePointer;
  bool? _dragAddsSelection;
  Set<String>? _draftSelection;
  final Set<String> _visitedOptionIds = <String>{};
  _BoardCellAddress? _lastDraggedCell;

  bool get _supportsSelection =>
      widget.mode == AvailabilityBoardMode.selection &&
      widget.onSelectionChanged != null;

  Set<String> get _displaySelection =>
      _draftSelection ?? widget.selectedOptionIds;

  @override
  void didUpdateWidget(covariant AvailabilityBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_supportsSelection) {
      _clearDragState(notify: false);
    }
  }

  @override
  void dispose() {
    _releaseAncestorScrollHolds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frame = _AvailabilityBoardFrame.fromUtility(widget.utility);
    if (frame.options.isEmpty) {
      return Text(
        'No availability board has been created yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppPalette.mutedText,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _BoardGeometry.resolve(
          constraints: constraints,
          dayCount: frame.days.length,
          rowCount: frame.timeSlots.length,
          compact: widget.compact,
        );
        final boardContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BoardLegend(
              mode: widget.mode,
              accent: widget.accent,
              compact: widget.compact,
              selectedCount: _displaySelection.length,
              dragLabel: _dragAddsSelection == null
                  ? null
                  : (_dragAddsSelection! ? 'Painting' : 'Erasing'),
            ),
            SizedBox(height: widget.compact ? 12 : 16),
            Container(
              width: geometry.contentWidth,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(widget.compact ? 18 : 24),
                border: Border.all(color: AppPalette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: widget.compact ? 18 : 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDayHeader(context, frame, geometry),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppPalette.border)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeRail(context, frame, geometry),
                        Expanded(child: _buildGrid(context, frame, geometry)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (!geometry.needsHorizontalScroll) {
          return boardContent;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: boardContent,
        );
      },
    );
  }

  Widget _buildDayHeader(
    BuildContext context,
    _AvailabilityBoardFrame frame,
    _BoardGeometry geometry,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        widget.compact ? 10 : 14,
        0,
        widget.compact ? 10 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: geometry.timeRailWidth),
          if (geometry.needsHorizontalScroll)
            for (var dayIndex = 0; dayIndex < frame.days.length; dayIndex++)
              SizedBox(
                width: geometry.cellWidth,
                child: _DayHeaderCell(
                  day: frame.days[dayIndex],
                  compact: widget.compact,
                ),
              )
          else
            Expanded(
              child: Row(
                children: [
                  for (
                    var dayIndex = 0;
                    dayIndex < frame.days.length;
                    dayIndex++
                  )
                    Expanded(
                      child: _DayHeaderCell(
                        day: frame.days[dayIndex],
                        compact: widget.compact,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRail(
    BuildContext context,
    _AvailabilityBoardFrame frame,
    _BoardGeometry geometry,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: geometry.timeRailWidth,
      child: Column(
        children: [
          for (final minutes in frame.timeSlots)
            Container(
              height: geometry.cellHeight,
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(
                top: widget.compact ? 3 : 5,
                right: widget.compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: _isHourRow(minutes)
                    ? AppPalette.canvas.withValues(alpha: 0.42)
                    : AppPalette.surfaceMuted.withValues(alpha: 0.72),
                border: Border(
                  top: BorderSide(
                    color: _isHourRow(minutes)
                        ? AppPalette.border.withValues(alpha: 0.9)
                        : AppPalette.border.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: Text(
                _timeRailLabel(minutes),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _isHourRow(minutes)
                      ? AppPalette.text
                      : AppPalette.mutedText,
                  fontWeight: _isHourRow(minutes)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    _AvailabilityBoardFrame frame,
    _BoardGeometry geometry,
  ) {
    final grid = RepaintBoundary(
      key: ValueKey('availability-board-grid-${widget.mode.name}'),
      child: SizedBox(
        width: geometry.needsHorizontalScroll ? geometry.gridWidth : null,
        child: RepaintBoundary(
          key: _gridKey,
          child: Column(
            children: [
              for (
                var rowIndex = 0;
                rowIndex < frame.timeSlots.length;
                rowIndex++
              )
                SizedBox(
                  height: geometry.cellHeight,
                  child: Row(
                    children: [
                      for (
                        var dayIndex = 0;
                        dayIndex < frame.days.length;
                        dayIndex++
                      )
                        if (geometry.needsHorizontalScroll)
                          _buildGridCell(
                            context,
                            frame: frame,
                            rowIndex: rowIndex,
                            dayIndex: dayIndex,
                            geometry: geometry,
                          )
                        else
                          Expanded(
                            child: _buildGridCell(
                              context,
                              frame: frame,
                              rowIndex: rowIndex,
                              dayIndex: dayIndex,
                              geometry: geometry,
                              useFixedWidth: false,
                            ),
                          ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!_supportsSelection) {
      return MouseRegion(cursor: SystemMouseCursors.click, child: grid);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (_) {},
              ),
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _handlePointerDown(event, frame: frame),
          onPointerMove: (event) => _handlePointerMove(event, frame: frame),
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: grid,
        ),
      ),
    );
  }

  Widget _buildGridCell(
    BuildContext context, {
    required _AvailabilityBoardFrame frame,
    required int rowIndex,
    required int dayIndex,
    required _BoardGeometry geometry,
    bool useFixedWidth = true,
  }) {
    final minutes = frame.timeSlots[rowIndex];
    final day = frame.days[dayIndex];
    final option = frame.optionAt(day: day, minutes: minutes);
    final score = option == null ? null : frame.scoresById[option.id];
    final isAggregate = widget.mode == AvailabilityBoardMode.aggregate;
    final isSelected = option != null && _displaySelection.contains(option.id);
    final coverage = option == null
        ? 0.0
        : (score?.coverage(widget.utility.participants.length) ?? 0.0);
    final isBest = isAggregate && option?.id == frame.bestOptionId;
    final fillColor = option == null
        ? AppPalette.surfaceMuted.withValues(alpha: 0.72)
        : isAggregate
        ? Color.lerp(
            const Color(0xFFF7FBFF),
            widget.accent,
            0.06 + (coverage * 0.84),
          )!
        : isSelected
        ? widget.accent.withValues(alpha: 0.92)
        : Colors.white;
    final borderColor = isBest
        ? widget.accent
        : _isHourRow(minutes)
        ? AppPalette.border.withValues(alpha: 0.9)
        : AppPalette.border.withValues(alpha: 0.45);

    return Container(
      width: useFixedWidth ? geometry.cellWidth : null,
      height: geometry.cellHeight,
      decoration: BoxDecoration(
        color: fillColor,
        border: Border(
          top: BorderSide(color: borderColor),
          right: BorderSide(color: AppPalette.border.withValues(alpha: 0.55)),
          left: dayIndex == 0
              ? BorderSide(color: AppPalette.border.withValues(alpha: 0.55))
              : BorderSide.none,
        ),
      ),
      child: Stack(
        children: [
          if (isBest)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.accent,
                    width: widget.compact ? 1.6 : 2,
                  ),
                ),
              ),
            ),
          if (!widget.compact && isAggregate && option != null && score != null)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 3),
                child: Text(
                  '${score.votes}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: coverage >= 0.38
                        ? Colors.white
                        : AppPalette.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
          if (!widget.compact && !isAggregate && isSelected)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 3, right: 3),
                child: Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handlePointerDown(
    PointerDownEvent event, {
    required _AvailabilityBoardFrame frame,
  }) {
    if (!_supportsSelection) {
      return;
    }

    if (_activePointer != null) {
      return;
    }

    final cell = _cellForGlobalPosition(
      event.position,
      frame: frame,
      clampToBounds: false,
    );
    if (cell == null || frame.optionAtCell(cell) == null) {
      _releaseAncestorScrollHolds();
      return;
    }

    _activePointer = event.pointer;
    _holdAncestorScrollables();
    widget.onInteractionChanged?.call(true);
    _handlePanStart(globalPosition: event.position, frame: frame);
  }

  void _handlePointerMove(
    PointerMoveEvent event, {
    required _AvailabilityBoardFrame frame,
  }) {
    if (event.pointer != _activePointer) {
      return;
    }

    _handlePanUpdate(globalPosition: event.position, frame: frame);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }

    _clearDragState();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }

    _clearDragState();
  }

  void _handlePanStart({
    required Offset globalPosition,
    required _AvailabilityBoardFrame frame,
  }) {
    if (!_supportsSelection) {
      return;
    }

    final cell = _cellForGlobalPosition(
      globalPosition,
      frame: frame,
      clampToBounds: false,
    );
    if (cell == null) {
      return;
    }

    final option = frame.optionAtCell(cell);
    if (option == null) {
      return;
    }

    final nextSelections = Set<String>.from(widget.selectedOptionIds);
    final shouldAdd = !nextSelections.contains(option.id);
    if (shouldAdd) {
      nextSelections.add(option.id);
    } else {
      nextSelections.remove(option.id);
    }

    HapticFeedback.selectionClick();
    setState(() {
      _dragAddsSelection = shouldAdd;
      _draftSelection = nextSelections;
      _lastDraggedCell = cell;
      _visitedOptionIds
        ..clear()
        ..add(option.id);
    });
    widget.onSelectionChanged?.call(nextSelections);
  }

  void _handlePanUpdate({
    required Offset globalPosition,
    required _AvailabilityBoardFrame frame,
  }) {
    if (!_supportsSelection || _lastDraggedCell == null) {
      return;
    }

    final nextCell = _cellForGlobalPosition(
      globalPosition,
      frame: frame,
      clampToBounds: true,
    );
    if (nextCell == null) {
      return;
    }

    final nextSelections = Set<String>.from(
      _draftSelection ?? _displaySelection,
    );
    var changed = false;
    for (final cell in _interpolateCells(_lastDraggedCell!, nextCell)) {
      final option = frame.optionAtCell(cell);
      if (option == null || _visitedOptionIds.contains(option.id)) {
        continue;
      }
      _visitedOptionIds.add(option.id);
      changed = true;
      if (_dragAddsSelection ?? true) {
        nextSelections.add(option.id);
      } else {
        nextSelections.remove(option.id);
      }
    }

    if (!changed) {
      _lastDraggedCell = nextCell;
      return;
    }

    setState(() {
      _lastDraggedCell = nextCell;
      _draftSelection = nextSelections;
    });
    widget.onSelectionChanged?.call(nextSelections);
  }

  _BoardCellAddress? _cellForGlobalPosition(
    Offset globalPosition, {
    required _AvailabilityBoardFrame frame,
    required bool clampToBounds,
  }) {
    final gridContext = _gridKey.currentContext;
    if (gridContext == null) {
      return null;
    }

    final renderBox = gridContext.findRenderObject();
    if (renderBox is! RenderBox) {
      return null;
    }

    final localPosition = renderBox.globalToLocal(globalPosition);
    final cellWidth = renderBox.size.width / frame.days.length;
    final cellHeight = renderBox.size.height / frame.timeSlots.length;
    final adjustedDx = clampToBounds
        ? localPosition.dx.clamp(0.0, renderBox.size.width - 0.001)
        : localPosition.dx;
    final adjustedDy = clampToBounds
        ? localPosition.dy.clamp(0.0, renderBox.size.height - 0.001)
        : localPosition.dy;
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx >= renderBox.size.width ||
        localPosition.dy >= renderBox.size.height) {
      if (!clampToBounds) {
        return null;
      }
    }

    final dayIndex = (adjustedDx / cellWidth).floor();
    final rowIndex = (adjustedDy / cellHeight).floor();
    if (dayIndex < 0 ||
        dayIndex >= frame.days.length ||
        rowIndex < 0 ||
        rowIndex >= frame.timeSlots.length) {
      return null;
    }

    return _BoardCellAddress(dayIndex: dayIndex, rowIndex: rowIndex);
  }

  Iterable<_BoardCellAddress> _interpolateCells(
    _BoardCellAddress start,
    _BoardCellAddress end,
  ) sync* {
    final dayDelta = end.dayIndex - start.dayIndex;
    final rowDelta = end.rowIndex - start.rowIndex;
    final steps = math.max(dayDelta.abs(), rowDelta.abs());
    if (steps == 0) {
      yield start;
      return;
    }

    for (var step = 1; step <= steps; step++) {
      final t = step / steps;
      yield _BoardCellAddress(
        dayIndex: (start.dayIndex + (dayDelta * t)).round(),
        rowIndex: (start.rowIndex + (rowDelta * t)).round(),
      );
    }
  }

  void _clearDragState({bool notify = true}) {
    _releaseAncestorScrollHolds();
    _activePointer = null;
    if (_dragAddsSelection == null &&
        _draftSelection == null &&
        _visitedOptionIds.isEmpty &&
        _lastDraggedCell == null) {
      return;
    }

    if (notify) {
      setState(() {
        _dragAddsSelection = null;
        _draftSelection = null;
        _visitedOptionIds.clear();
        _lastDraggedCell = null;
      });
      return;
    }

    _dragAddsSelection = null;
    _draftSelection = null;
    _visitedOptionIds.clear();
    _lastDraggedCell = null;
  }

  bool _isHourRow(int minutes) => minutes % 60 == 0;

  String _timeRailLabel(int minutes) {
    if (!_isHourRow(minutes)) {
      return widget.compact ? '·' : '';
    }
    final hour = minutes ~/ 60;
    return formatTime(DateTime(2026, 1, 1, hour));
  }

  void _holdAncestorScrollables() {
    if (_scrollHoldControllers.isNotEmpty) {
      return;
    }

    final holdContext = _gridKey.currentContext ?? context;
    holdContext.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final scrollableState = element.state as ScrollableState;
        _scrollHoldControllers.add(scrollableState.position.hold(() {}));
      }
      return true;
    });
  }

  void _releaseAncestorScrollHolds() {
    if (_scrollHoldControllers.isEmpty) {
      return;
    }

    for (final controller in _scrollHoldControllers) {
      controller.cancel();
    }
    _scrollHoldControllers.clear();
    widget.onInteractionChanged?.call(false);
  }
}

class _BoardLegend extends StatelessWidget {
  const _BoardLegend({
    required this.mode,
    required this.accent,
    required this.compact,
    required this.selectedCount,
    this.dragLabel,
  });

  final AvailabilityBoardMode mode;
  final Color accent;
  final bool compact;
  final int selectedCount;
  final String? dragLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (mode == AvailabilityBoardMode.selection) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _LegendPill(
            label: '$selectedCount blocks selected',
            color: accent.withValues(alpha: 0.92),
            foreground: Colors.white,
          ),
          if (dragLabel != null)
            _LegendPill(
              label: dragLabel!,
              color: accent.withValues(alpha: 0.12),
              foreground: accent,
            ),
          Text(
            compact
                ? 'Drag to paint. Tap for single blocks.'
                : 'Drag across the grid to paint availability. Drag across selected time to erase it, or tap for a single block.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.mutedText,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          compact ? 'Availability overlap' : 'Availability overlap heatmap',
          style: theme.textTheme.titleMedium,
        ),
        _LegendGradient(accent: accent),
        Text(
          compact
              ? 'lighter to darker'
              : 'Lighter means fewer people. Darker means stronger overlap.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppPalette.mutedText,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _LegendGradient extends StatelessWidget {
  const _LegendGradient({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF7FBFF),
            Color.lerp(const Color(0xFFF7FBFF), accent, 0.52)!,
            accent,
          ],
        ),
        border: Border.all(color: AppPalette.border),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({required this.day, required this.compact});

  final DateTime day;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
      child: Column(
        children: [
          Text(
            weekdayLabels[day.weekday - 1],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${monthLabels[day.month - 1]} ${day.day}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppPalette.text),
          ),
        ],
      ),
    );
  }
}

class _BoardGeometry {
  const _BoardGeometry({
    required this.timeRailWidth,
    required this.cellWidth,
    required this.cellHeight,
    required this.contentWidth,
    required this.needsHorizontalScroll,
    required this.gridWidth,
    required this.gridHeight,
  });

  final double timeRailWidth;
  final double cellWidth;
  final double cellHeight;
  final double contentWidth;
  final bool needsHorizontalScroll;
  final double gridWidth;
  final double gridHeight;

  static _BoardGeometry resolve({
    required BoxConstraints constraints,
    required int dayCount,
    required int rowCount,
    required bool compact,
  }) {
    final timeRailWidth = compact ? 58.0 : 76.0;
    final preferredCellWidth = compact ? 38.0 : 50.0;
    final minCellWidth = compact ? 32.0 : 42.0;
    final maxCellWidth = compact ? 44.0 : 64.0;
    final availableWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : timeRailWidth + (preferredCellWidth * dayCount);

    var cellWidth = preferredCellWidth;
    if (dayCount > 0) {
      final fittedWidth = ((availableWidth - timeRailWidth) / dayCount)
          .floorToDouble();
      cellWidth = fittedWidth.clamp(minCellWidth, maxCellWidth);
    }

    final cellHeight = compact ? 22.0 : 28.0;
    final contentWidth = timeRailWidth + (cellWidth * dayCount);
    final needsHorizontalScroll =
        constraints.maxWidth.isFinite &&
        contentWidth > constraints.maxWidth + 0.5;
    return _BoardGeometry(
      timeRailWidth: timeRailWidth,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      contentWidth: contentWidth,
      needsHorizontalScroll: needsHorizontalScroll,
      gridWidth: cellWidth * dayCount,
      gridHeight: cellHeight * rowCount,
    );
  }
}

class _AvailabilityBoardFrame {
  _AvailabilityBoardFrame({
    required this.options,
    required this.days,
    required this.timeSlots,
    required this.optionByCell,
    required this.scoresById,
    required this.bestOptionId,
  });

  final List<UtilityOption> options;
  final List<DateTime> days;
  final List<int> timeSlots;
  final Map<String, UtilityOption> optionByCell;
  final Map<String, UtilityOptionScore> scoresById;
  final String? bestOptionId;

  factory _AvailabilityBoardFrame.fromUtility(UtilityInstance utility) {
    final options = utility.options
        .where((option) => option.startAt != null && option.endAt != null)
        .toList(growable: false);
    final dayMap = <String, DateTime>{};
    final timeSlots = <int>{};
    final optionByCell = <String, UtilityOption>{};

    for (final option in options) {
      final startAt = option.startAt!;
      final day = DateTime(startAt.year, startAt.month, startAt.day);
      final minutes = startAt.hour * 60 + startAt.minute;
      dayMap[_dayKey(day)] = day;
      timeSlots.add(minutes);
      optionByCell['${_dayKey(day)}-$minutes'] = option;
    }

    final days = dayMap.values.toList(growable: false)..sort();
    final sortedSlots = timeSlots.toList(growable: false)..sort();
    final scoresById = <String, UtilityOptionScore>{
      for (final score in utility.optionScores) score.option.id: score,
    };

    return _AvailabilityBoardFrame(
      options: options,
      days: days,
      timeSlots: sortedSlots,
      optionByCell: optionByCell,
      scoresById: scoresById,
      bestOptionId: utility.optionScores.isEmpty
          ? null
          : utility.optionScores.first.option.id,
    );
  }

  UtilityOption? optionAt({required DateTime day, required int minutes}) {
    return optionByCell['${_dayKey(day)}-$minutes'];
  }

  UtilityOption? optionAtCell(_BoardCellAddress cell) {
    if (cell.dayIndex < 0 ||
        cell.dayIndex >= days.length ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= timeSlots.length) {
      return null;
    }

    return optionAt(
      day: days[cell.dayIndex],
      minutes: timeSlots[cell.rowIndex],
    );
  }

  static String _dayKey(DateTime day) => '${day.year}-${day.month}-${day.day}';
}

class _BoardCellAddress {
  const _BoardCellAddress({required this.dayIndex, required this.rowIndex});

  final int dayIndex;
  final int rowIndex;
}
