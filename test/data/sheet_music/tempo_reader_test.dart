import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/engraving.dart';
import 'package:mijn_app/data/sheet_music/tempo_reader.dart';

void main() {
  test('reads the number of a metronome mark', () {
    final tempo = const TempoReader().quarterNotesPerMinute(const [
      TextLine(text: 'Ode to Joy', y: 800),
      TextLine(text: ' = 100', y: 760),
    ]);

    expect(tempo, 100);
  });

  test('falls back to a moderate tempo without a metronome mark', () {
    final tempo = const TempoReader().quarterNotesPerMinute(const [
      TextLine(text: 'Prelude 1', y: 800),
    ]);

    expect(tempo, TempoReader.defaultQuarterNotesPerMinute);
  });
}
