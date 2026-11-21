abstract final class MusicGlyphNames {
  static const _noteheadPrefix = 'noteheads.';
  static const _restPrefix = 'rests.';
  static const _flagPattern = r'^flags\.[ud](\d)$';
  static const dot = 'dots.dot';

  static const _quarterNoteBeatsPerHead = {
    's0': 4.0,
    's1': 2.0,
    's2': 1.0,
    'sM1': 8.0,
  };

  static const accidentalAlterations = {
    'accidentals.sharp': 1,
    'accidentals.flat': -1,
    'accidentals.natural': 0,
    'accidentals.doublesharp': 2,
    'accidentals.flatflat': -2,
  };

  static const clefReferenceSteps = {
    'clefs.G': _g4,
    'clefs.G_change': _g4,
    'clefs.F': _f3,
    'clefs.F_change': _f3,
    'clefs.C': _c4,
    'clefs.C_change': _c4,
  };

  static const _c4 = 4 * 7;
  static const _f3 = 3 * 7 + 3;
  static const _g4 = 4 * 7 + 4;

  static double? beatsOfNotehead(String name) =>
      name.startsWith(_noteheadPrefix)
      ? _quarterNoteBeatsPerHead[name.substring(_noteheadPrefix.length)]
      : null;

  static bool isNotehead(String name) => beatsOfNotehead(name) != null;

  static bool isStemmedNotehead(String name) {
    final beats = beatsOfNotehead(name);
    return beats != null && beats <= 2;
  }

  static double? beatsOfRest(String name) {
    if (!name.startsWith(_restPrefix)) return null;
    final match = RegExp(r'^(M?)(\d)')
        .firstMatch(name.substring(_restPrefix.length));
    if (match == null) return null;
    final isLongerThanWhole = match.group(1)!.isNotEmpty;
    final exponent = 1 << int.parse(match.group(2)!);
    return isLongerThanWhole ? 4.0 * exponent : 4.0 / exponent;
  }

  static int? flagCount(String name) {
    final match = RegExp(_flagPattern).firstMatch(name);
    if (match == null) return null;
    return int.parse(match.group(1)!) - 2;
  }
}
