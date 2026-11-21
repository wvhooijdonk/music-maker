import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/engraving.dart';
import 'package:mijn_app/data/sheet_music/measure_timeline.dart';
import 'package:mijn_app/data/sheet_music/rhythmic_event.dart';

void main() {
  const staff = Staff(
    bottomLineY: 0,
    lineSpacing: 5,
    left: 0,
    right: 500,
    lineThickness: 0.5,
  );

  const headWidth = 6.5;

  RhythmicEvent event({required double x, required double beats}) =>
      RhythmicEvent(x: x, beats: beats, heads: const [], staff: staff);

  RhythmicEvent noteEvent({
    required double x,
    required double y,
    required double beats,
  }) => RhythmicEvent(
    x: x,
    beats: beats,
    heads: [
      MusicSymbol(
        name: 'noteheads.s2',
        left: x - headWidth / 2,
        y: y,
        width: headWidth,
        fontSize: 20,
      ),
    ],
    staff: staff,
  );

  Map<double, double> startBeatPerX(List<RhythmicEvent> events) {
    final placed = const MeasureTimeline().place(events, lineSpacing: 5);
    return {for (final timed in placed.events) timed.event.x: timed.startBeat};
  }

  test('a following column starts when the shortest preceding note ends', () {
    final starts = startBeatPerX([
      event(x: 10, beats: 1),
      event(x: 40, beats: 1),
      event(x: 70, beats: 1),
    ]);

    expect(starts, {10: 0, 40: 1, 70: 2});
  });

  test(
    'an eighth after a dotted quarter starts halfway a parallel quarter',
    () {
      final starts = startBeatPerX([
        event(x: 10, beats: 1.5),
        event(x: 10.5, beats: 1),
        event(x: 40, beats: 1),
        event(x: 55, beats: 0.5),
      ]);

      expect(starts[55], 1.5);
    },
  );

  test('measure length is the latest end of any event', () {
    final placed = const MeasureTimeline().place([
      event(x: 10, beats: 3),
      event(x: 11, beats: 1),
      event(x: 40, beats: 1),
    ], lineSpacing: 5);

    expect(placed.lengthInBeats, 3);
  });

  test('a notehead shifted aside by a colliding voice shares the column', () {
    final starts = startBeatPerX([
      noteEvent(x: 10, y: 10, beats: 1),
      noteEvent(x: 10 + headWidth, y: 12.5, beats: 1.5),
      event(x: 40, beats: 0.5),
    ]);

    expect(starts[10 + headWidth], 0);
  });

  test('close notes far apart vertically stay successive columns', () {
    final starts = startBeatPerX([
      event(x: 10, beats: 0.5),
      event(x: 10.4, beats: 0.25),
      noteEvent(x: 20, y: -30, beats: 0.75),
      noteEvent(x: 24.3, y: 10, beats: 0.25),
    ]);

    expect(starts, {10: 0, 10.4: 0, 20: 0.25, 24.3: 0.5});
  });
}
