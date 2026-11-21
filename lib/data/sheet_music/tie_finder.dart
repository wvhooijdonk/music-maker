import 'engraving.dart';
import 'music_glyph_names.dart';

class Tie {
  const Tie({required this.from, required this.to});

  final MusicSymbol from;
  final MusicSymbol to;
}

class TieFinder {
  const TieFinder();

  static const _startToleranceInSpaces = 2.5;
  static const _endToleranceInSpaces = 1.0;
  static const _verticalReachInSpaces = 1.5;

  List<Tie> find({
    required List<Curve> curves,
    required Staff staff,
    required List<MusicSymbol> symbols,
  }) {
    final heads = symbols
        .where((symbol) => MusicGlyphNames.isNotehead(symbol.name))
        .toList();
    final ties = <Tie>[];
    for (final curve in curves) {
      final from = _headNear(
        heads,
        staff,
        curve,
        tolerance: _startToleranceInSpaces * staff.lineSpacing,
        gapToCurve: (head) => curve.left - head.right,
      );
      final to = _headNear(
        heads,
        staff,
        curve,
        tolerance: _endToleranceInSpaces * staff.lineSpacing,
        gapToCurve: (head) => head.left - curve.right,
      );
      final isTie =
          from != null &&
          to != null &&
          staff.staffPositionOf(from.y) == staff.staffPositionOf(to.y);
      if (isTie) ties.add(Tie(from: from, to: to));
    }
    return ties;
  }

  MusicSymbol? _headNear(
    List<MusicSymbol> heads,
    Staff staff,
    Curve curve, {
    required double tolerance,
    required double Function(MusicSymbol head) gapToCurve,
  }) {
    MusicSymbol? nearest;
    var smallestGap = double.infinity;
    for (final head in heads) {
      final gap = gapToCurve(head).abs();
      final isBesideCurve =
          (head.y - curve.centerY).abs() <=
          _verticalReachInSpaces * staff.lineSpacing;
      if (isBesideCurve && gap <= tolerance && gap < smallestGap) {
        nearest = head;
        smallestGap = gap;
      }
    }
    return nearest;
  }
}
