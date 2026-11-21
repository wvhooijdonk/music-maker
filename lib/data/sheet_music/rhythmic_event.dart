import 'engraving.dart';

class RhythmicEvent {
  const RhythmicEvent({
    required this.x,
    required this.beats,
    required this.heads,
    required this.staff,
  });

  final double x;
  final double beats;
  final List<MusicSymbol> heads;
  final Staff staff;

  bool get isRest => heads.isEmpty;
}
