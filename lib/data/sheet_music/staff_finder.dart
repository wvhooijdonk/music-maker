import 'engraving.dart';

class StaffFinder {
  const StaffFinder();

  static const _minimumStaffLineLength = 50.0;
  static const _edgeTolerance = 1.0;
  static const _maximumSpacingDeviation = 0.1;

  List<Staff> find(Iterable<HorizontalSegment> segments) {
    final candidates = segments
        .where((segment) => segment.length >= _minimumStaffLineLength)
        .toList();
    final staves = <Staff>[];
    for (final group in _groupBySharedEdges(candidates)) {
      staves.addAll(_stavesIn(group));
    }
    staves.sort(
      (first, second) => second.bottomLineY.compareTo(first.bottomLineY),
    );
    return staves;
  }

  List<List<HorizontalSegment>> _groupBySharedEdges(
    List<HorizontalSegment> segments,
  ) {
    final groups = <List<HorizontalSegment>>[];
    for (final segment in segments) {
      final group = groups
          .where((group) => _sharesEdges(group.first, segment))
          .firstOrNull;
      if (group == null) {
        groups.add([segment]);
      } else {
        group.add(segment);
      }
    }
    return groups;
  }

  bool _sharesEdges(HorizontalSegment first, HorizontalSegment second) =>
      (first.left - second.left).abs() <= _edgeTolerance &&
      (first.right - second.right).abs() <= _edgeTolerance;

  List<Staff> _stavesIn(List<HorizontalSegment> group) {
    final lines = _withoutDuplicateHeights(group)
      ..sort((first, second) => first.y.compareTo(second.y));
    final staves = <Staff>[];
    var index = 0;
    while (index + Staff.lineCount <= lines.length) {
      final candidateLines = lines.sublist(index, index + Staff.lineCount);
      if (_areEvenlySpaced(candidateLines)) {
        staves.add(_staffFrom(candidateLines));
        index += Staff.lineCount;
      } else {
        index++;
      }
    }
    return staves;
  }

  List<HorizontalSegment> _withoutDuplicateHeights(
    List<HorizontalSegment> lines,
  ) {
    final unique = <HorizontalSegment>[];
    for (final line in lines) {
      if (unique.every(
        (existing) => (existing.y - line.y).abs() > _edgeTolerance / 4,
      )) {
        unique.add(line);
      }
    }
    return unique;
  }

  bool _areEvenlySpaced(List<HorizontalSegment> lines) {
    final gaps = [
      for (var index = 1; index < lines.length; index++)
        lines[index].y - lines[index - 1].y,
    ];
    final averageGap = gaps.reduce((sum, gap) => sum + gap) / gaps.length;
    return averageGap > 0 &&
        gaps.every(
          (gap) =>
              (gap - averageGap).abs() <= averageGap * _maximumSpacingDeviation,
        );
  }

  Staff _staffFrom(List<HorizontalSegment> lines) => Staff(
    bottomLineY: lines.first.y,
    lineSpacing: (lines.last.y - lines.first.y) / (Staff.lineCount - 1),
    left: lines.first.left,
    right: lines.first.right,
    lineThickness: lines.first.thickness,
  );
}
