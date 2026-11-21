class HorizontalSegment {
  const HorizontalSegment({
    required this.left,
    required this.right,
    required this.y,
    required this.thickness,
  });

  final double left;
  final double right;
  final double y;
  final double thickness;

  double get length => right - left;
}

class VerticalBar {
  const VerticalBar({
    required this.left,
    required this.right,
    required this.bottom,
    required this.top,
  });

  final double left;
  final double right;
  final double bottom;
  final double top;

  double get width => right - left;

  double get height => top - bottom;

  double get centerX => (left + right) / 2;
}

class Beam {
  const Beam({
    required this.leftX,
    required this.rightX,
    required this.leftY,
    required this.rightY,
    required this.thickness,
  });

  final double leftX;
  final double rightX;
  final double leftY;
  final double rightY;
  final double thickness;

  bool spans(double x, {required double tolerance}) =>
      x >= leftX - tolerance && x <= rightX + tolerance;

  double centerYAt(double x) {
    final width = rightX - leftX;
    if (width == 0) return leftY;
    return leftY + (rightY - leftY) * (x - leftX) / width;
  }
}

class Curve {
  const Curve({
    required this.left,
    required this.right,
    required this.bottom,
    required this.top,
  });

  final double left;
  final double right;
  final double bottom;
  final double top;

  double get centerY => (bottom + top) / 2;
}

class MusicSymbol {
  const MusicSymbol({
    required this.name,
    required this.left,
    required this.y,
    required this.width,
    required this.fontSize,
  });

  final String name;
  final double left;
  final double y;
  final double width;
  final double fontSize;

  double get right => left + width;

  double get centerX => left + width / 2;

  @override
  String toString() =>
      '$name@(${left.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

class TextLine {
  const TextLine({required this.text, required this.y});

  final String text;
  final double y;
}

class Staff {
  const Staff({
    required this.bottomLineY,
    required this.lineSpacing,
    required this.left,
    required this.right,
    required this.lineThickness,
  });

  static const lineCount = 5;

  final double bottomLineY;
  final double lineSpacing;
  final double left;
  final double right;
  final double lineThickness;

  double get topLineY => bottomLineY + (lineCount - 1) * lineSpacing;

  double get halfSpace => lineSpacing / 2;

  int staffPositionOf(double y) => ((y - bottomLineY) / halfSpace).round();

  double verticalDistanceTo(double y) {
    if (y < bottomLineY) return bottomLineY - y;
    if (y > topLineY) return y - topLineY;
    return 0;
  }

  bool isSpannedBy(VerticalBar bar) =>
      bar.bottom <= bottomLineY + halfSpace && bar.top >= topLineY - halfSpace;
}

class EngravedPage {
  const EngravedPage({
    required this.staves,
    required this.bars,
    required this.beams,
    required this.curves,
    required this.symbols,
    required this.textLines,
  });

  final List<Staff> staves;
  final List<VerticalBar> bars;
  final List<Beam> beams;
  final List<Curve> curves;
  final List<MusicSymbol> symbols;
  final List<TextLine> textLines;
}
