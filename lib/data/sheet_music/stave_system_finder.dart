import 'engraving.dart';
import 'stave_system.dart';

class StaveSystemFinder {
  const StaveSystemFinder();

  static const _barlineMergeDistanceInSpaces = 1.5;
  static const _systemStartMarginInSpaces = 1.0;
  static const _matchingBarlineToleranceInSpaces = 0.2;
  static const _maximumSymbolDistanceInSpaces = 8.0;

  List<StaveSystem> find(EngravedPage page) {
    final barlinesPerStaff = {
      for (final staff in page.staves) staff: _barlineXsOf(staff, page.bars),
    };
    final stavesPerSystem = <List<Staff>>[];
    for (final staff in page.staves) {
      final previousSystem = stavesPerSystem.lastOrNull;
      final belongsToPreviousSystem =
          previousSystem != null &&
          _haveMatchingBarlines(
            barlinesPerStaff[previousSystem.last]!,
            barlinesPerStaff[staff]!,
            staff.lineSpacing,
          );
      if (belongsToPreviousSystem) {
        previousSystem.add(staff);
      } else {
        stavesPerSystem.add([staff]);
      }
    }
    final symbolsPerStaff = _assignSymbolsToNearestStaff(page);
    return [
      for (final staves in stavesPerSystem)
        StaveSystem(
          staves: staves,
          barlineXs: barlinesPerStaff[staves.first]!,
          symbolsPerStaff: {
            for (final staff in staves)
              staff: symbolsPerStaff[staff] ?? const [],
          },
        ),
    ];
  }

  List<double> _barlineXsOf(Staff staff, List<VerticalBar> bars) {
    final barlineXs =
        bars
            .where(
              (bar) =>
                  bar.width > staff.lineThickness &&
                  staff.isSpannedBy(bar) &&
                  bar.centerX >
                      staff.left +
                          _systemStartMarginInSpaces * staff.lineSpacing,
            )
            .map((bar) => bar.centerX)
            .toList()
          ..sort();
    final merged = <double>[];
    for (final x in barlineXs) {
      final isPartOfPrevious =
          merged.isNotEmpty &&
          x - merged.last <= _barlineMergeDistanceInSpaces * staff.lineSpacing;
      if (!isPartOfPrevious) merged.add(x);
    }
    return merged;
  }

  bool _haveMatchingBarlines(
    List<double> first,
    List<double> second,
    double lineSpacing,
  ) {
    if (first.length != second.length || first.isEmpty) return false;
    final tolerance = _matchingBarlineToleranceInSpaces * lineSpacing;
    for (var index = 0; index < first.length; index++) {
      if ((first[index] - second[index]).abs() > tolerance) return false;
    }
    return true;
  }

  Map<Staff, List<MusicSymbol>> _assignSymbolsToNearestStaff(
    EngravedPage page,
  ) {
    final symbolsPerStaff = <Staff, List<MusicSymbol>>{};
    for (final symbol in page.symbols) {
      Staff? nearestStaff;
      var nearestDistance = double.infinity;
      for (final staff in page.staves) {
        final distance = staff.verticalDistanceTo(symbol.y);
        if (distance < nearestDistance) {
          nearestStaff = staff;
          nearestDistance = distance;
        }
      }
      if (nearestStaff != null &&
          nearestDistance <=
              _maximumSymbolDistanceInSpaces * nearestStaff.lineSpacing) {
        symbolsPerStaff.putIfAbsent(nearestStaff, () => []).add(symbol);
      }
    }
    return symbolsPerStaff;
  }
}
