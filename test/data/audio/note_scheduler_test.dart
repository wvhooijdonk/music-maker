import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/audio/note_scheduler.dart';
import 'package:mijn_app/data/audio/voice.dart';
import 'package:mijn_app/domain/entities/note.dart';

void main() {
  Note noteAt(int seconds) => Note(
    pitch: 60,
    start: Duration(seconds: seconds),
    length: const Duration(seconds: 1),
  );

  test('hands out each note once, as soon as it falls within the window', () {
    final scheduler = NoteScheduler([noteAt(0), noteAt(1), noteAt(2)]);

    expect(
      scheduler.takeNotesStartingBefore(const Duration(milliseconds: 1500)),
      [noteAt(0), noteAt(1)],
    );
    expect(
      scheduler.takeNotesStartingBefore(const Duration(milliseconds: 1500)),
      isEmpty,
    );
    expect(scheduler.takeNotesStartingBefore(const Duration(seconds: 3)), [
      noteAt(2),
    ]);
  });

  test('concert pitch A is 440 Hz and an octave doubles the frequency', () {
    expect(frequencyOfPitch(69), 440);
    expect(frequencyOfPitch(81), closeTo(880, 0.001));
  });
}
