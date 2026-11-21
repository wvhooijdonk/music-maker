class PdfPoint {
  const PdfPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  String toString() => '($x, $y)';
}

class PdfGlyph {
  const PdfGlyph({
    required this.glyphName,
    required this.character,
    required this.origin,
    required this.width,
    required this.fontSize,
  });

  final String? glyphName;
  final String character;
  final PdfPoint origin;
  final double width;
  final double fontSize;
}

class PdfSubpath {
  const PdfSubpath(
    this.points, {
    required this.isClosed,
    this.containsCurves = false,
  });

  final List<PdfPoint> points;
  final bool isClosed;
  final bool containsCurves;
}

class PdfPaintedPath {
  const PdfPaintedPath({
    required this.subpaths,
    required this.isFilled,
    required this.isStroked,
    required this.lineWidth,
  });

  final List<PdfSubpath> subpaths;
  final bool isFilled;
  final bool isStroked;
  final double lineWidth;
}

class PdfPageGraphics {
  const PdfPageGraphics({required this.glyphs, required this.paths});

  final List<PdfGlyph> glyphs;
  final List<PdfPaintedPath> paths;
}
