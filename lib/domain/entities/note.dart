import 'instrument.dart';

class Note {
  const Note({
    required this.pitch,
    required this.start,
    required this.length,
    this.instrument = Instrument.piano,
  });

  final int pitch;
  final Duration start;
  final Duration length;
  final Instrument instrument;

  Duration get end => start + length;

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.pitch == pitch &&
      other.start == start &&
      other.length == length &&
      other.instrument == instrument;

  @override
  int get hashCode => Object.hash(pitch, start, length, instrument);

  @override
  String toString() => 'Note(pitch: $pitch, start: $start, length: $length)';
}
