import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/domain/entities/instrument.dart';
import 'package:mijn_app/domain/entities/note.dart';
import 'package:mijn_app/domain/entities/score.dart';

void main() {
  test(
    'the duration ends with the last sounding note, not the last starting one',
    () {
      final score = Score(const [
        Note(pitch: 48, start: Duration.zero, length: Duration(seconds: 4)),
        Note(
          pitch: 60,
          start: Duration(seconds: 1),
          length: Duration(seconds: 1),
        ),
      ]);

      expect(score.duration, const Duration(seconds: 4));
    },
  );

  test('notes are ordered by start time', () {
    final score = Score(const [
      Note(
        pitch: 64,
        start: Duration(seconds: 2),
        length: Duration(seconds: 1),
      ),
      Note(pitch: 60, start: Duration.zero, length: Duration(seconds: 1)),
    ]);

    expect(score.notes.map((note) => note.pitch), [60, 64]);
  });

  test('every instrument is listed once', () {
    final score = Score(const [
      Note(pitch: 60, start: Duration.zero, length: Duration(seconds: 1)),
      Note(pitch: 64, start: Duration.zero, length: Duration(seconds: 1)),
    ]);

    expect(score.instruments, [Instrument.piano]);
  });

  test('an empty score lasts no time', () {
    expect(Score(const []).duration, Duration.zero);
  });
}
