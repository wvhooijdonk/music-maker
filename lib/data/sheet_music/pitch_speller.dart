import 'engraving.dart';
import 'music_glyph_names.dart';

class PitchSpeller {
  PitchSpeller();

  static const _stepsPerOctave = 7;
  static const _semitonesAboveC = [0, 2, 4, 5, 7, 9, 11];
  static const _accidentalReachInSpaces = 6.0;

  final _keySignaturePerStaffIndex = <int, Map<int, int>>{};

  Map<MusicSymbol, int> spell({
    required Staff staff,
    required int staffIndex,
    required List<MusicSymbol> symbols,
    required List<double> barlineXs,
  }) {
    final heads = symbols
        .where((symbol) => MusicGlyphNames.isNotehead(symbol.name))
        .toList();
    final firstHeadX = heads.isEmpty
        ? double.infinity
        : heads.map((head) => head.left).reduce((a, b) => a < b ? a : b);
    final orderedSymbols = [...symbols]
      ..sort((a, b) => a.left.compareTo(b.left));

    var clefReference = (
      staffPosition: 2,
      step: MusicGlyphNames.clefReferenceSteps['clefs.G']!,
    );
    final newKeySignature = <int, int>{};
    var keySignature =
        _keySignaturePerStaffIndex[staffIndex] ?? const <int, int>{};
    final measureAlterations = <int, int>{};
    var nextBarlineIndex = 0;
    final pitches = <MusicSymbol, int>{};

    int stepOf(MusicSymbol symbol) =>
        clefReference.step +
        staff.staffPositionOf(symbol.y) -
        clefReference.staffPosition;

    for (final symbol in orderedSymbols) {
      while (nextBarlineIndex < barlineXs.length &&
          barlineXs[nextBarlineIndex] < symbol.left) {
        measureAlterations.clear();
        nextBarlineIndex++;
      }
      final clefStep = MusicGlyphNames.clefReferenceSteps[symbol.name];
      final alteration = MusicGlyphNames.accidentalAlterations[symbol.name];
      if (clefStep != null) {
        clefReference = (
          staffPosition: staff.staffPositionOf(symbol.y),
          step: clefStep,
        );
      } else if (alteration != null) {
        final step = stepOf(symbol);
        if (_belongsToNotehead(symbol, heads, staff)) {
          measureAlterations[step] = alteration;
        } else if (symbol.left < firstHeadX) {
          newKeySignature[step % _stepsPerOctave] = alteration;
          keySignature = newKeySignature;
        }
      } else if (MusicGlyphNames.isNotehead(symbol.name)) {
        final step = stepOf(symbol);
        final alterationOfStep =
            measureAlterations[step] ??
            keySignature[step % _stepsPerOctave] ??
            0;
        pitches[symbol] = _midiPitch(step, alterationOfStep);
      }
    }
    _keySignaturePerStaffIndex[staffIndex] = keySignature;
    return pitches;
  }

  bool _belongsToNotehead(
    MusicSymbol accidental,
    List<MusicSymbol> heads,
    Staff staff,
  ) {
    final staffPosition = staff.staffPositionOf(accidental.y);
    return heads.any(
      (head) =>
          head.left > accidental.left &&
          head.left - accidental.left <=
              _accidentalReachInSpaces * staff.lineSpacing &&
          staff.staffPositionOf(head.y) == staffPosition,
    );
  }

  static int _midiPitch(int step, int alteration) {
    final octave = step ~/ _stepsPerOctave;
    final stepInOctave = step % _stepsPerOctave;
    return 12 * (octave + 1) + _semitonesAboveC[stepInOctave] + alteration;
  }
}
