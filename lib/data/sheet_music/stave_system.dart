import 'engraving.dart';

class StaveSystem {
  const StaveSystem({
    required this.staves,
    required this.barlineXs,
    required this.symbolsPerStaff,
  });

  final List<Staff> staves;
  final List<double> barlineXs;
  final Map<Staff, List<MusicSymbol>> symbolsPerStaff;

  double get left => staves.first.left;

  double get right => staves.first.right;

  double get lineSpacing => staves.first.lineSpacing;

  List<double> get measureBoundaries => [left, ...barlineXs, right];
}
