import 'dart:typed_data';

import 'pdf_document.dart';
import 'pdf_font.dart';
import 'pdf_matrix.dart';
import 'pdf_object.dart';
import 'pdf_object_parser.dart';
import 'pdf_page_graphics.dart';

class PdfContentInterpreter {
  PdfContentInterpreter(this._document);

  final PdfDocument _document;

  PdfPageGraphics interpretPage(PdfDictionary page) {
    final fontDictionary = _document.resolveDictionary(
      _document.resolveDictionary(
        _document.lookupInherited(page, 'Resources'),
      )?['Font'],
    );
    final fonts = <String, PdfFont>{
      for (final MapEntry(:key, :value)
          in fontDictionary?.entries.entries ?? <MapEntry<String, PdfObject>>[])
        if (_document.resolveDictionary(value) case final PdfDictionary font)
          key: PdfFont.from(font, _document),
    };
    return _PageInterpretation(fonts).run(_document.contentOf(page));
  }
}

class _GraphicsState {
  _GraphicsState({
    this.transformation = const PdfMatrix.identity(),
    this.lineWidth = 1,
  });

  PdfMatrix transformation;
  double lineWidth;

  _GraphicsState copy() =>
      _GraphicsState(transformation: transformation, lineWidth: lineWidth);
}

class _PageInterpretation {
  _PageInterpretation(this._fonts);

  final Map<String, PdfFont> _fonts;
  final _glyphs = <PdfGlyph>[];
  final _paths = <PdfPaintedPath>[];
  final _savedStates = <_GraphicsState>[];
  var _state = _GraphicsState();
  final _operands = <PdfObject>[];

  final _subpaths = <PdfSubpath>[];
  var _currentSubpath = <PdfPoint>[];
  var _currentSubpathContainsCurves = false;

  var _textMatrix = const PdfMatrix.identity();
  var _textLineMatrix = const PdfMatrix.identity();
  PdfFont? _font;
  var _fontSize = 1.0;
  var _leading = 0.0;
  var _characterSpacing = 0.0;
  var _wordSpacing = 0.0;
  var _horizontalScaling = 1.0;

  PdfPageGraphics run(Uint8List content) {
    final parser = PdfObjectParser(content);
    while (!parser.isAtEnd) {
      final object = parser.readObject();
      if (object is PdfOperator) {
        _execute(object.name);
        _operands.clear();
      } else {
        _operands.add(object);
      }
    }
    return PdfPageGraphics(glyphs: _glyphs, paths: _paths);
  }

  double _number(int index) => switch (_operands.elementAtOrNull(index)) {
    PdfNumber(:final value) => value.toDouble(),
    _ => 0,
  };

  void _execute(String operator) {
    switch (operator) {
      case 'q':
        _savedStates.add(_state.copy());
      case 'Q':
        if (_savedStates.isNotEmpty) _state = _savedStates.removeLast();
      case 'cm':
        _state.transformation = _matrixFromOperands().then(
          _state.transformation,
        );
      case 'w':
        _state.lineWidth = _number(0);
      case 'm':
        _closeCurrentSubpath(isClosed: false);
        _currentSubpath = [_userPoint(_number(0), _number(1))];
      case 'l':
        _currentSubpath.add(_userPoint(_number(0), _number(1)));
      case 'c':
        _currentSubpath.add(_userPoint(_number(4), _number(5)));
        _currentSubpathContainsCurves = true;
      case 'v' || 'y':
        _currentSubpath.add(_userPoint(_number(2), _number(3)));
        _currentSubpathContainsCurves = true;
      case 'h':
        _closeCurrentSubpath(isClosed: true);
      case 're':
        _addRectangle();
      case 'S':
        _paint(isFilled: false, isStroked: true);
      case 's':
        _closeCurrentSubpath(isClosed: true);
        _paint(isFilled: false, isStroked: true);
      case 'f' || 'F' || 'f*':
        _paint(isFilled: true, isStroked: false);
      case 'B' || 'B*':
        _paint(isFilled: true, isStroked: true);
      case 'b' || 'b*':
        _closeCurrentSubpath(isClosed: true);
        _paint(isFilled: true, isStroked: true);
      case 'n':
        _discardPath();
      case 'BT':
        _textMatrix = const PdfMatrix.identity();
        _textLineMatrix = const PdfMatrix.identity();
      case 'Tf':
        final fontName = _operands.elementAtOrNull(0);
        _font = fontName is PdfName ? _fonts[fontName.value] : null;
        _fontSize = _number(1);
      case 'Tc':
        _characterSpacing = _number(0);
      case 'Tw':
        _wordSpacing = _number(0);
      case 'Tz':
        _horizontalScaling = _number(0) / 100;
      case 'TL':
        _leading = _number(0);
      case 'Td':
        _moveToNextLine(_number(0), _number(1));
      case 'TD':
        _leading = -_number(1);
        _moveToNextLine(_number(0), _number(1));
      case 'Tm':
        _textMatrix = _textLineMatrix = _matrixFromOperands();
      case 'T*':
        _moveToNextLine(0, -_leading);
      case 'Tj':
        _showOperandString(0);
      case "'":
        _moveToNextLine(0, -_leading);
        _showOperandString(0);
      case '"':
        _wordSpacing = _number(0);
        _characterSpacing = _number(1);
        _moveToNextLine(0, -_leading);
        _showOperandString(2);
      case 'TJ':
        _showTextArray();
    }
  }

  PdfMatrix _matrixFromOperands() => PdfMatrix(
    _number(0),
    _number(1),
    _number(2),
    _number(3),
    _number(4),
    _number(5),
  );

  PdfPoint _userPoint(double x, double y) =>
      _state.transformation.transform(x, y);

  void _addRectangle() {
    _closeCurrentSubpath(isClosed: false);
    final x = _number(0);
    final y = _number(1);
    final width = _number(2);
    final height = _number(3);
    _subpaths.add(
      PdfSubpath([
        _userPoint(x, y),
        _userPoint(x + width, y),
        _userPoint(x + width, y + height),
        _userPoint(x, y + height),
      ], isClosed: true),
    );
  }

  void _closeCurrentSubpath({required bool isClosed}) {
    if (_currentSubpath.length > 1) {
      _subpaths.add(
        PdfSubpath(
          _currentSubpath,
          isClosed: isClosed,
          containsCurves: _currentSubpathContainsCurves,
        ),
      );
    }
    _currentSubpath = [];
    _currentSubpathContainsCurves = false;
  }

  void _paint({required bool isFilled, required bool isStroked}) {
    _closeCurrentSubpath(isClosed: false);
    if (_subpaths.isNotEmpty) {
      _paths.add(
        PdfPaintedPath(
          subpaths: List.of(_subpaths),
          isFilled: isFilled,
          isStroked: isStroked,
          lineWidth: _state.lineWidth * _state.transformation.averageScale,
        ),
      );
    }
    _subpaths.clear();
  }

  void _discardPath() {
    _currentSubpath = [];
    _currentSubpathContainsCurves = false;
    _subpaths.clear();
  }

  void _moveToNextLine(double x, double y) {
    _textMatrix = _textLineMatrix = PdfMatrix.translation(
      x,
      y,
    ).then(_textLineMatrix);
  }

  void _showOperandString(int index) {
    final operand = _operands.elementAtOrNull(index);
    if (operand is PdfString) _showString(operand.bytes);
  }

  void _showTextArray() {
    final array = _operands.elementAtOrNull(0);
    if (array is! PdfArray) return;
    for (final item in array.items) {
      switch (item) {
        case PdfString(:final bytes):
          _showString(bytes);
        case PdfNumber(:final value):
          _advanceText(-value / 1000 * _fontSize * _horizontalScaling);
        default:
          break;
      }
    }
  }

  void _showString(Uint8List codes) {
    final font = _font;
    for (final code in codes) {
      final glyphToUser = _textMatrix.then(_state.transformation);
      final glyphWidth = (font?.widthOf(code) ?? 0.5) * _fontSize;
      _glyphs.add(
        PdfGlyph(
          glyphName: font?.glyphNameOf(code),
          character: String.fromCharCode(code),
          origin: glyphToUser.transform(0, 0),
          width: glyphWidth * _horizontalScaling * glyphToUser.horizontalScale,
          fontSize: _fontSize * glyphToUser.averageScale,
        ),
      );
      final wordSpacing = code == 0x20 ? _wordSpacing : 0;
      _advanceText(
        (glyphWidth + _characterSpacing + wordSpacing) * _horizontalScaling,
      );
    }
  }

  void _advanceText(double distance) {
    _textMatrix = PdfMatrix.translation(distance, 0).then(_textMatrix);
  }
}
