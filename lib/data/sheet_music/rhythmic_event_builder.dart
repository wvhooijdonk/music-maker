import 'dart:math';

import 'augmentation_dot_counter.dart';
import 'engraving.dart';
import 'music_glyph_names.dart';
import 'rhythmic_event.dart';
import 'stave_system.dart';

class RhythmicEventBuilder {
  const RhythmicEventBuilder({
    this._dotCounter = const AugmentationDotCounter(),
  });

  final AugmentationDotCounter _dotCounter;

  static const _stemAttachToleranceInSpaces = 0.35;
  static const _stemEndToleranceInSpaces = 0.35;
  static const _flagDistanceInSpaces = 1.0;
  static const _beamReachInSpaces = 3.5;
  static const _beamOvershootInSpaces = 0.35;
  static const _minimumBeamThicknessInSpaces = 0.3;
  static const _minimumStemHeightInSpaces = 1.5;
  static const _cueSizeRatio = 0.9;

  List<RhythmicEvent> build(
    StaveSystem system, {
    required List<VerticalBar> bars,
    required List<Beam> beams,
  }) {
    final events = <RhythmicEvent>[];
    final standardFontSize = _standardNoteheadFontSize(system);
    final systemSymbols = system.symbolsPerStaff.values.expand(
      (symbols) => symbols,
    );
    final dots = systemSymbols
        .where((symbol) => symbol.name == MusicGlyphNames.dot)
        .toList();
    final flags = systemSymbols
        .where((symbol) => MusicGlyphNames.flagCount(symbol.name) != null)
        .toList();
    final dotsPerOwner = _dotCounter.countDotsPerOwner(
      dots: dots,
      possibleOwners: systemSymbols
          .where(
            (symbol) =>
                MusicGlyphNames.isNotehead(symbol.name) ||
                MusicGlyphNames.beatsOfRest(symbol.name) != null,
          )
          .toList(),
      lineSpacing: system.lineSpacing,
    );
    int dotsOf(List<MusicSymbol> owners) =>
        owners.map((owner) => dotsPerOwner[owner] ?? 0).fold(0, max);

    for (final staff in system.staves) {
      final symbols = system.symbolsPerStaff[staff]!;
      final heads = symbols
          .where((symbol) => MusicGlyphNames.isNotehead(symbol.name))
          .where((head) => head.fontSize >= standardFontSize * _cueSizeRatio)
          .toList();
      final stems = bars.where((bar) => _isStemOf(bar, staff)).toList();
      final staffBeams = beams
          .where(
            (beam) =>
                beam.thickness >=
                _minimumBeamThicknessInSpaces * staff.lineSpacing,
          )
          .toList();

      final headsOnStems = <MusicSymbol>{};
      for (final stem in stems) {
        final attachedHeads = _headsAttachedTo(stem, heads, staff);
        if (attachedHeads.isEmpty) continue;
        headsOnStems.addAll(attachedHeads);
        events.add(
          _chordOnStem(
            stem,
            attachedHeads,
            staff,
            flags,
            staffBeams,
            dotsOf(attachedHeads),
          ),
        );
      }
      for (final head in heads.where((head) => !headsOnStems.contains(head))) {
        events.add(
          RhythmicEvent(
            x: head.centerX,
            beats: _dotted(
              MusicGlyphNames.beatsOfNotehead(head.name)!,
              dotsOf([head]),
            ),
            heads: [head],
            staff: staff,
          ),
        );
      }
      for (final rest in symbols) {
        final beats = MusicGlyphNames.beatsOfRest(rest.name);
        if (beats == null) continue;
        events.add(
          RhythmicEvent(
            x: rest.centerX,
            beats: _dotted(beats, dotsOf([rest])),
            heads: const [],
            staff: staff,
          ),
        );
      }
    }
    return events;
  }

  double _standardNoteheadFontSize(StaveSystem system) {
    final sizes = [
      for (final symbols in system.symbolsPerStaff.values)
        for (final symbol in symbols)
          if (MusicGlyphNames.isNotehead(symbol.name)) symbol.fontSize,
    ];
    return sizes.isEmpty ? 0 : sizes.reduce(max);
  }

  bool _isStemOf(VerticalBar bar, Staff staff) =>
      bar.width <= staff.lineThickness &&
      bar.height >= _minimumStemHeightInSpaces * staff.lineSpacing;

  List<MusicSymbol> _headsAttachedTo(
    VerticalBar stem,
    List<MusicSymbol> heads,
    Staff staff,
  ) {
    final sideTolerance = _stemAttachToleranceInSpaces * staff.lineSpacing;
    final endTolerance = _stemEndToleranceInSpaces * staff.lineSpacing;
    return heads.where((head) {
      final touchesStemSide =
          (head.right - stem.right).abs() <= sideTolerance ||
          (head.left - stem.left).abs() <= sideTolerance;
      final liesAlongStem =
          head.y >= stem.bottom - endTolerance &&
          head.y <= stem.top + endTolerance;
      return MusicGlyphNames.isStemmedNotehead(head.name) &&
          touchesStemSide &&
          liesAlongStem;
    }).toList();
  }

  RhythmicEvent _chordOnStem(
    VerticalBar stem,
    List<MusicSymbol> heads,
    Staff staff,
    List<MusicSymbol> flags,
    List<Beam> beams,
    int dotCount,
  ) {
    final lowestHeadY = heads.map((head) => head.y).reduce(min);
    final highestHeadY = heads.map((head) => head.y).reduce(max);
    final pointsUp =
        (lowestHeadY - stem.bottom).abs() < (stem.top - highestHeadY).abs();
    final tipY = pointsUp ? stem.top : stem.bottom;
    final headWidth = heads.first.width;
    final x = pointsUp ? stem.right - headWidth / 2 : stem.left + headWidth / 2;

    final flagCount = flags
        .where(
          (flag) =>
              (flag.left - stem.centerX).abs() <=
                  _flagDistanceInSpaces * staff.lineSpacing &&
              (flag.y - tipY).abs() <=
                  _flagDistanceInSpaces * staff.lineSpacing,
        )
        .map((flag) => MusicGlyphNames.flagCount(flag.name)!)
        .fold(0, max);
    final beamCount = beams
        .where((beam) => _beamMeetsStem(beam, stem, tipY, pointsUp, staff))
        .length;
    final headBeats = heads
        .map((head) => MusicGlyphNames.beatsOfNotehead(head.name)!)
        .reduce(min);
    final shortenings = max(flagCount, beamCount);
    final undottedBeats = headBeats >= 2
        ? headBeats
        : headBeats / (1 << shortenings);
    return RhythmicEvent(
      x: x,
      beats: _dotted(undottedBeats, dotCount),
      heads: heads,
      staff: staff,
    );
  }

  bool _beamMeetsStem(
    Beam beam,
    VerticalBar stem,
    double tipY,
    bool pointsUp,
    Staff staff,
  ) {
    if (!beam.spans(
      stem.centerX,
      tolerance: stem.width + staff.lineThickness,
    )) {
      return false;
    }
    final beamY = beam.centerYAt(stem.centerX);
    final reach = _beamReachInSpaces * staff.lineSpacing;
    final overshoot = _beamOvershootInSpaces * staff.lineSpacing;
    return pointsUp
        ? beamY <= tipY + overshoot && beamY >= tipY - reach
        : beamY >= tipY - overshoot && beamY <= tipY + reach;
  }

  static double _dotted(double beats, int dots) =>
      beats * (2 - 1 / (1 << dots));
}
