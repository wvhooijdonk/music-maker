import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/engraving.dart';
import 'package:mijn_app/data/sheet_music/pitch_speller.dart';

void main() {
  const staff = Staff(
    bottomLineY: 100,
    lineSpacing: 5,
    left: 0,
    right: 500,
    lineThickness: 0.5,
  );
  const halfSpace = 2.5;

  MusicSymbol at(
    String name, {
    required double left,
    required int staffPosition,
  }) => MusicSymbol(
    name: name,
    left: left,
    y: staff.bottomLineY + staffPosition * halfSpace,
    width: 6,
    fontSize: 20,
  );

  final trebleClef = at('clefs.G', left: 5, staffPosition: 2);

  Map<MusicSymbol, int> spell(
    List<MusicSymbol> symbols, {
    List<double> barlineXs = const [],
  }) => PitchSpeller().spell(
    staff: staff,
    staffIndex: 0,
    symbols: symbols,
    barlineXs: barlineXs,
  );

  test('a notehead on the bottom line of a treble staff is E4', () {
    final head = at('noteheads.s2', left: 50, staffPosition: 0);

    expect(spell([trebleClef, head])[head], 64);
  });

  test('a notehead on the top line of a bass staff is A3', () {
    final bassClef = at('clefs.F', left: 5, staffPosition: 6);
    final head = at('noteheads.s2', left: 50, staffPosition: 8);

    expect(spell([bassClef, head])[head], 57);
  });

  test('a key signature sharp raises that note in every octave', () {
    final fSharpInKey = at('accidentals.sharp', left: 20, staffPosition: 8);
    final lowF = at('noteheads.s2', left: 50, staffPosition: 1);

    expect(spell([trebleClef, fSharpInKey, lowF])[lowF], 66);
  });

  test('an accidental lasts until the next barline', () {
    final sharp = at('accidentals.sharp', left: 40, staffPosition: 2);
    final sharpenedG = at('noteheads.s2', left: 50, staffPosition: 2);
    final repeatedG = at('noteheads.s2', left: 80, staffPosition: 2);
    final gAfterBarline = at('noteheads.s2', left: 120, staffPosition: 2);

    final pitches = spell(
      [trebleClef, sharp, sharpenedG, repeatedG, gAfterBarline],
      barlineXs: [100],
    );

    expect(
      [pitches[sharpenedG], pitches[repeatedG], pitches[gAfterBarline]],
      [68, 68, 67],
    );
  });
}
