import '../pdf/pdf_page_graphics.dart';
import 'engraving.dart';
import 'staff_finder.dart';

class EngravingReader {
  const EngravingReader({this._staffFinder = const StaffFinder()});

  static const _alignmentTolerance = 0.05;
  static const _maximumHorizontalRectangleHeight = 0.6;
  static const _sameLineTolerance = 1.0;

  final StaffFinder _staffFinder;

  EngravedPage read(PdfPageGraphics graphics) {
    final segments = <HorizontalSegment>[];
    final bars = <VerticalBar>[];
    final beams = <Beam>[];
    final curves = <Curve>[];
    for (final path in graphics.paths) {
      for (final subpath in path.subpaths) {
        if (subpath.containsCurves) {
          if (path.isFilled) curves.add(_curveAround(subpath.points));
          continue;
        }
        _classify(path, subpath, segments: segments, bars: bars, beams: beams);
      }
    }
    return EngravedPage(
      staves: _staffFinder.find(segments),
      bars: _withoutDuplicates(bars),
      beams: beams,
      curves: curves,
      symbols: [
        for (final glyph in graphics.glyphs)
          if (glyph.glyphName case final String name)
            MusicSymbol(
              name: name,
              left: glyph.origin.x,
              y: glyph.origin.y,
              width: glyph.width,
              fontSize: glyph.fontSize,
            ),
      ],
      textLines: _textLines(
        graphics.glyphs.where((glyph) => glyph.glyphName == null),
      ),
    );
  }

  void _classify(
    PdfPaintedPath path,
    PdfSubpath subpath, {
    required List<HorizontalSegment> segments,
    required List<VerticalBar> bars,
    required List<Beam> beams,
  }) {
    final points = _withoutRepeatedClosingPoint(subpath.points);
    final isClosed = subpath.isClosed || path.isFilled;
    if (points.length == 2 && path.isStroked) {
      _classifyLine(
        points[0],
        points[1],
        path.lineWidth,
        segments: segments,
        bars: bars,
      );
    } else if (points.length == 4 && isClosed) {
      _classifyQuadrilateral(
        points,
        path,
        segments: segments,
        bars: bars,
        beams: beams,
      );
    }
  }

  Curve _curveAround(List<PdfPoint> points) {
    final xs = points.map((point) => point.x);
    final ys = points.map((point) => point.y);
    return Curve(
      left: xs.reduce(_min),
      right: xs.reduce(_max),
      bottom: ys.reduce(_min),
      top: ys.reduce(_max),
    );
  }

  List<PdfPoint> _withoutRepeatedClosingPoint(List<PdfPoint> points) {
    final isRepeated =
        points.length > 2 &&
        _isSame(points.first.x, points.last.x) &&
        _isSame(points.first.y, points.last.y);
    return isRepeated ? points.sublist(0, points.length - 1) : points;
  }

  void _classifyLine(
    PdfPoint start,
    PdfPoint end,
    double lineWidth, {
    required List<HorizontalSegment> segments,
    required List<VerticalBar> bars,
  }) {
    if (_isSame(start.y, end.y)) {
      segments.add(
        HorizontalSegment(
          left: _min(start.x, end.x),
          right: _max(start.x, end.x),
          y: start.y,
          thickness: lineWidth,
        ),
      );
    } else if (_isSame(start.x, end.x)) {
      bars.add(
        VerticalBar(
          left: start.x - lineWidth / 2,
          right: start.x + lineWidth / 2,
          bottom: _min(start.y, end.y),
          top: _max(start.y, end.y),
        ),
      );
    }
  }

  void _classifyQuadrilateral(
    List<PdfPoint> points,
    PdfPaintedPath path, {
    required List<HorizontalSegment> segments,
    required List<VerticalBar> bars,
    required List<Beam> beams,
  }) {
    final verticalSides = _verticalSidesOf(points);
    if (verticalSides == null) return;
    final (leftSide, rightSide) = verticalSides;
    final left = leftSide.$1.x;
    final right = rightSide.$1.x;
    final sideHeight = (leftSide.$1.y - leftSide.$2.y).abs();
    final isAxisAligned =
        _isSame(leftSide.$1.y, rightSide.$1.y) ||
        _isSame(leftSide.$1.y, rightSide.$2.y);
    final bottom = _min(leftSide.$1.y, leftSide.$2.y);
    final top = _max(leftSide.$1.y, leftSide.$2.y);

    if (isAxisAligned && sideHeight > right - left) {
      bars.add(VerticalBar(left: left, right: right, bottom: bottom, top: top));
    } else if (isAxisAligned &&
        sideHeight <= _maximumHorizontalRectangleHeight) {
      if (path.isFilled) {
        segments.add(
          HorizontalSegment(
            left: left,
            right: right,
            y: (bottom + top) / 2,
            thickness: sideHeight,
          ),
        );
      }
    } else if (path.isFilled) {
      beams.add(
        Beam(
          leftX: left,
          rightX: right,
          leftY: (leftSide.$1.y + leftSide.$2.y) / 2,
          rightY: (rightSide.$1.y + rightSide.$2.y) / 2,
          thickness: sideHeight,
        ),
      );
    }
  }

  ((PdfPoint, PdfPoint), (PdfPoint, PdfPoint))? _verticalSidesOf(
    List<PdfPoint> points,
  ) {
    for (final offset in [0, 1]) {
      final first = (points[offset], points[offset + 1]);
      final second = (points[offset + 2], points[(offset + 3) % 4]);
      if (_isSame(first.$1.x, first.$2.x) &&
          _isSame(second.$1.x, second.$2.x) &&
          !_isSame(first.$1.x, second.$1.x)) {
        return first.$1.x < second.$1.x ? (first, second) : (second, first);
      }
    }
    return null;
  }

  List<VerticalBar> _withoutDuplicates(List<VerticalBar> bars) {
    final unique = <VerticalBar>[];
    for (final bar in bars) {
      final isDuplicate = unique.any(
        (existing) =>
            (existing.left - bar.left).abs() < 0.1 &&
            (existing.bottom - bar.bottom).abs() < 0.1 &&
            (existing.top - bar.top).abs() < 0.1,
      );
      if (!isDuplicate) unique.add(bar);
    }
    return unique;
  }

  List<TextLine> _textLines(Iterable<PdfGlyph> textGlyphs) {
    final glyphsPerLine = <List<PdfGlyph>>[];
    for (final glyph in textGlyphs) {
      final line = glyphsPerLine
          .where(
            (line) =>
                (line.first.origin.y - glyph.origin.y).abs() <=
                _sameLineTolerance,
          )
          .firstOrNull;
      if (line == null) {
        glyphsPerLine.add([glyph]);
      } else {
        line.add(glyph);
      }
    }
    return [
      for (final line in glyphsPerLine)
        TextLine(
          text: (line..sort((a, b) => a.origin.x.compareTo(b.origin.x)))
              .map((glyph) => glyph.character)
              .join(),
          y: line.first.origin.y,
        ),
    ];
  }

  static bool _isSame(double first, double second) =>
      (first - second).abs() <= _alignmentTolerance;

  static double _min(double first, double second) =>
      first < second ? first : second;

  static double _max(double first, double second) =>
      first > second ? first : second;
}
