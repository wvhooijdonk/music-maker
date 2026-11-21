import 'engraving.dart';

class AugmentationDotCounter {
  const AugmentationDotCounter();

  static const _reachFromNoteInSpaces = 2.5;
  static const _reachFromDotInSpaces = 1.0;
  static const _verticalToleranceInSpaces = 0.6;

  Map<MusicSymbol, int> countDotsPerOwner({
    required List<MusicSymbol> dots,
    required List<MusicSymbol> possibleOwners,
    required double lineSpacing,
  }) {
    final ownerOfDot = <MusicSymbol, MusicSymbol>{};
    final dotCountPerOwner = <MusicSymbol, int>{};
    final dotsLeftToRight = [...dots]..sort((a, b) => a.left.compareTo(b.left));
    for (final dot in dotsLeftToRight) {
      final nearestOwner = _nearestOnTheLeft(
        dot,
        possibleOwners,
        _reachFromNoteInSpaces * lineSpacing,
        lineSpacing,
      );
      final nearestDot = _nearestOnTheLeft(
        dot,
        ownerOfDot.keys,
        _reachFromDotInSpaces * lineSpacing,
        lineSpacing,
      );
      final owner =
          _closer(nearestDot, nearestOwner) == nearestDot && nearestDot != null
          ? ownerOfDot[nearestDot]
          : nearestOwner;
      if (owner == null) continue;
      ownerOfDot[dot] = owner;
      dotCountPerOwner[owner] = (dotCountPerOwner[owner] ?? 0) + 1;
    }
    return dotCountPerOwner;
  }

  MusicSymbol? _nearestOnTheLeft(
    MusicSymbol dot,
    Iterable<MusicSymbol> candidates,
    double reach,
    double lineSpacing,
  ) {
    MusicSymbol? nearest;
    for (final candidate in candidates) {
      final gap = dot.left - candidate.right;
      final isAligned =
          (dot.y - candidate.y).abs() <=
          _verticalToleranceInSpaces * lineSpacing;
      if (gap < 0 || gap > reach || !isAligned) continue;
      if (nearest == null || candidate.right > nearest.right) {
        nearest = candidate;
      }
    }
    return nearest;
  }

  MusicSymbol? _closer(MusicSymbol? first, MusicSymbol? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.right >= second.right ? first : second;
  }
}
