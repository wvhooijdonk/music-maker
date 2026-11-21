import 'dart:math';

import 'rhythmic_event.dart';

class TimedEvent {
  const TimedEvent({required this.event, required this.startBeat});

  final RhythmicEvent event;
  final double startBeat;
}

class MeasureTimeline {
  const MeasureTimeline();

  static const _columnToleranceInSpaces = 0.6;
  static const _touchingToleranceInSpaces = 0.3;
  static const _collisionDistanceInSpaces = 1.0;

  ({List<TimedEvent> events, double lengthInBeats}) place(
    List<RhythmicEvent> eventsInMeasure, {
    required double lineSpacing,
  }) {
    final ordered = [...eventsInMeasure]..sort((a, b) => a.x.compareTo(b.x));
    final columns = <List<RhythmicEvent>>[];
    for (final event in ordered) {
      final column = columns.lastOrNull;
      final joinsColumn =
          column != null &&
          (event.x - column.first.x <= _columnToleranceInSpaces * lineSpacing ||
              _isShiftedAsideFrom(column, event, lineSpacing));
      if (joinsColumn) {
        column.add(event);
      } else {
        columns.add([event]);
      }
    }

    final timedEvents = <TimedEvent>[];
    final soundingEnds = <double>[];
    var columnStart = 0.0;
    for (final column in columns) {
      for (final event in column) {
        timedEvents.add(TimedEvent(event: event, startBeat: columnStart));
        soundingEnds.add(columnStart + event.beats);
      }
      columnStart = soundingEnds
          .where((end) => end > columnStart)
          .fold(double.infinity, min);
    }
    final measureLength = soundingEnds.fold(0.0, max);
    return (events: timedEvents, lengthInBeats: measureLength);
  }

  bool _isShiftedAsideFrom(
    List<RhythmicEvent> column,
    RhythmicEvent event,
    double lineSpacing,
  ) {
    final columnHeads = column.expand((member) => member.heads);
    return event.heads.any(
      (head) => columnHeads.any(
        (columnHead) =>
            (head.left - columnHead.right).abs() <=
                _touchingToleranceInSpaces * lineSpacing &&
            (head.y - columnHead.y).abs() <=
                _collisionDistanceInSpaces * lineSpacing,
      ),
    );
  }
}
