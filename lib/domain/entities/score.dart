import 'instrument.dart';
import 'note.dart';

class Score {
  Score(Iterable<Note> notes)
    : notes = List.unmodifiable(
        [...notes]
          ..sort((first, second) => first.start.compareTo(second.start)),
      );

  final List<Note> notes;

  Duration get duration => notes.fold(
    Duration.zero,
    (latestEnd, note) => note.end > latestEnd ? note.end : latestEnd,
  );

  List<Instrument> get instruments =>
      notes.map((note) => note.instrument).toSet().toList(growable: false);
}
