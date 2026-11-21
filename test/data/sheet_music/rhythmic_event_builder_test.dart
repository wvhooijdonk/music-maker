import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/engraving.dart';
import 'package:mijn_app/data/sheet_music/rhythmic_event_builder.dart';
import 'package:mijn_app/data/sheet_music/stave_system.dart';

void main() {
  const lineSpacing = 5.0;
  const headWidth = 6.5;
  const upperStaff = Staff(
    bottomLineY: 100,
    lineSpacing: lineSpacing,
    left: 0,
    right: 500,
    lineThickness: 0.5,
  );
  const lowerStaff = Staff(
    bottomLineY: 50,
    lineSpacing: lineSpacing,
    left: 0,
    right: 500,
    lineThickness: 0.5,
  );

  MusicSymbol symbol(String name, {required double left, required double y}) =>
      MusicSymbol(name: name, left: left, y: y, width: headWidth, fontSize: 20);

  VerticalBar upStemOf(MusicSymbol head, {double length = 17.5}) => VerticalBar(
    left: head.right - 0.25,
    right: head.right,
    bottom: head.y,
    top: head.y + length,
  );

  StaveSystem systemWith(Map<Staff, List<MusicSymbol>> symbolsPerStaff) =>
      StaveSystem(
        staves: const [upperStaff, lowerStaff],
        barlineXs: const [],
        symbolsPerStaff: {
          upperStaff: symbolsPerStaff[upperStaff] ?? const [],
          lowerStaff: symbolsPerStaff[lowerStaff] ?? const [],
        },
      );

  test('a quarter notehead on a stem lasts one beat', () {
    final head = symbol('noteheads.s2', left: 100, y: 110);

    final events = const RhythmicEventBuilder().build(
      systemWith({
        upperStaff: [head],
      }),
      bars: [upStemOf(head)],
      beams: const [],
    );

    expect(events.single.beats, 1);
  });

  test('a flag drawn closer to the next staff still shortens the note it belongs to', () {
    final head = symbol('noteheads.s2', left: 100, y: 78);
    final stem = upStemOf(head);
    final flag = MusicSymbol(
      name: 'flags.u3',
      left: stem.centerX,
      y: stem.top - 2,
      width: 3,
      fontSize: 20,
    );

    final events = const RhythmicEventBuilder().build(
      systemWith({
        lowerStaff: [head],
        upperStaff: [flag],
      }),
      bars: [stem],
      beams: const [],
    );

    expect(events.single.beats, 0.5);
  });

  test('a dot belongs only to the nearest notehead on its left', () {
    final lowerHead = symbol('noteheads.s0', left: 100, y: 110);
    final shiftedHead = symbol('noteheads.s0', left: 100 + headWidth, y: 112.5);
    final dot = symbol('dots.dot', left: shiftedHead.right + 2, y: 112.5);

    final events = const RhythmicEventBuilder().build(
      systemWith({
        upperStaff: [lowerHead, shiftedHead, dot],
      }),
      bars: const [],
      beams: const [],
    );

    final beatsPerHeadLeft = {
      for (final event in events) event.heads.single.left: event.beats,
    };
    expect(beatsPerHeadLeft, {lowerHead.left: 4, shiftedHead.left: 6});
  });
}
