import 'dart:typed_data';

import 'pdf_object.dart';

class PdfObjectParser {
  PdfObjectParser(this._bytes, {this._position = 0});

  final Uint8List _bytes;
  int _position;

  int get position => _position;

  bool get isAtEnd {
    _skipWhitespaceAndComments();
    return _position >= _bytes.length;
  }

  PdfObject readObject() {
    _skipWhitespaceAndComments();
    if (_position >= _bytes.length) {
      throw const FormatException('PDF: onverwacht einde');
    }
    final byte = _bytes[_position];
    if (byte == _slash) return _readName();
    if (byte == _openParenthesis) return _readLiteralString();
    if (byte == _lessThan) {
      return _nextByteIs(_lessThan) ? _readDictionary() : _readHexString();
    }
    if (byte == _openBracket) return _readArray();
    if (_isNumberStart(byte)) return _readNumberOrReference();
    return _readKeyword();
  }

  void skipEndOfLine() {
    if (_position < _bytes.length && _bytes[_position] == _carriageReturn) {
      _position++;
    }
    if (_position < _bytes.length && _bytes[_position] == _lineFeed) {
      _position++;
    }
  }

  Uint8List readBytes(int length) {
    final end = (_position + length).clamp(0, _bytes.length);
    final bytes = Uint8List.sublistView(_bytes, _position, end);
    _position = end;
    return bytes;
  }

  PdfName _readName() {
    _position++;
    final name = StringBuffer();
    while (_position < _bytes.length && _isRegular(_bytes[_position])) {
      final byte = _bytes[_position++];
      if (byte == _hash && _position + 1 < _bytes.length) {
        final hex = String.fromCharCodes(_bytes, _position, _position + 2);
        name.writeCharCode(int.parse(hex, radix: 16));
        _position += 2;
      } else {
        name.writeCharCode(byte);
      }
    }
    return PdfName(name.toString());
  }

  PdfString _readLiteralString() {
    _position++;
    final content = BytesBuilder(copy: false);
    var depth = 1;
    while (_position < _bytes.length) {
      final byte = _bytes[_position++];
      if (byte == _backslash) {
        _readEscapeInto(content);
      } else if (byte == _openParenthesis) {
        depth++;
        content.addByte(byte);
      } else if (byte == _closeParenthesis) {
        depth--;
        if (depth == 0) break;
        content.addByte(byte);
      } else {
        content.addByte(byte);
      }
    }
    return PdfString(content.toBytes());
  }

  void _readEscapeInto(BytesBuilder content) {
    if (_position >= _bytes.length) return;
    final escaped = _bytes[_position++];
    switch (escaped) {
      case 0x6e:
        content.addByte(_lineFeed);
      case 0x72:
        content.addByte(_carriageReturn);
      case 0x74:
        content.addByte(0x09);
      case 0x62:
        content.addByte(0x08);
      case 0x66:
        content.addByte(0x0c);
      case _carriageReturn:
        if (_position < _bytes.length && _bytes[_position] == _lineFeed) {
          _position++;
        }
      case _lineFeed:
        break;
      default:
        if (_isOctalDigit(escaped)) {
          var value = escaped - _zero;
          for (var digit = 1; digit < 3; digit++) {
            if (_position >= _bytes.length ||
                !_isOctalDigit(_bytes[_position])) {
              break;
            }
            value = value * 8 + _bytes[_position++] - _zero;
          }
          content.addByte(value & 0xff);
        } else {
          content.addByte(escaped);
        }
    }
  }

  PdfString _readHexString() {
    _position++;
    final digits = StringBuffer();
    while (_position < _bytes.length && _bytes[_position] != _greaterThan) {
      final byte = _bytes[_position++];
      if (!_isWhitespace(byte)) digits.writeCharCode(byte);
    }
    _position++;
    final hex = digits.length.isOdd ? '${digits}0' : digits.toString();
    return PdfString(
      Uint8List.fromList([
        for (var index = 0; index < hex.length; index += 2)
          int.parse(hex.substring(index, index + 2), radix: 16),
      ]),
    );
  }

  PdfDictionary _readDictionary() {
    _position += 2;
    final entries = <String, PdfObject>{};
    while (true) {
      _skipWhitespaceAndComments();
      if (_position >= _bytes.length) break;
      if (_bytes[_position] == _greaterThan && _nextByteIs(_greaterThan)) {
        _position += 2;
        break;
      }
      final key = readObject();
      if (key is! PdfName) {
        throw FormatException(
          'PDF: sleutel in dictionary verwacht',
          _bytes,
          _position,
        );
      }
      entries[key.value] = readObject();
    }
    return PdfDictionary(entries);
  }

  PdfArray _readArray() {
    _position++;
    final items = <PdfObject>[];
    while (true) {
      _skipWhitespaceAndComments();
      if (_position >= _bytes.length) break;
      if (_bytes[_position] == _closeBracket) {
        _position++;
        break;
      }
      items.add(readObject());
    }
    return PdfArray(items);
  }

  PdfObject _readNumberOrReference() {
    final number = _readNumber();
    if (number is! int) return PdfNumber(number);
    final positionAfterNumber = _position;
    final reference = _tryReadReferenceTail();
    if (reference) return PdfReference(number);
    _position = positionAfterNumber;
    return PdfNumber(number);
  }

  bool _tryReadReferenceTail() {
    _skipWhitespaceAndComments();
    if (_position >= _bytes.length || !_isDigit(_bytes[_position])) {
      return false;
    }
    final generation = _readNumber();
    if (generation is! int) return false;
    _skipWhitespaceAndComments();
    final isReferenceKeyword =
        _position < _bytes.length &&
        _bytes[_position] == _capitalR &&
        (_position + 1 >= _bytes.length || !_isRegular(_bytes[_position + 1]));
    if (isReferenceKeyword) {
      _position++;
    }
    return isReferenceKeyword;
  }

  num _readNumber() {
    final start = _position;
    while (_position < _bytes.length && _isNumberStart(_bytes[_position])) {
      _position++;
    }
    final text = String.fromCharCodes(_bytes, start, _position);
    return int.tryParse(text) ??
        double.tryParse(text) ??
        _parseLenientDouble(text);
  }

  double _parseLenientDouble(String text) {
    final cleaned = text.replaceAll(RegExp(r'(?<=.)[+-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  PdfObject _readKeyword() {
    final start = _position;
    while (_position < _bytes.length && _isRegular(_bytes[_position])) {
      _position++;
    }
    if (_position == start) {
      _position++;
      return PdfOperator(String.fromCharCode(_bytes[start]));
    }
    final keyword = String.fromCharCodes(_bytes, start, _position);
    return switch (keyword) {
      'true' => const PdfBoolean(true),
      'false' => const PdfBoolean(false),
      'null' => const PdfNull(),
      _ => PdfOperator(keyword),
    };
  }

  void _skipWhitespaceAndComments() {
    while (_position < _bytes.length) {
      final byte = _bytes[_position];
      if (_isWhitespace(byte)) {
        _position++;
      } else if (byte == _percent) {
        while (_position < _bytes.length &&
            _bytes[_position] != _lineFeed &&
            _bytes[_position] != _carriageReturn) {
          _position++;
        }
      } else {
        return;
      }
    }
  }

  bool _nextByteIs(int byte) =>
      _position + 1 < _bytes.length && _bytes[_position + 1] == byte;

  static bool _isWhitespace(int byte) =>
      byte == 0x20 ||
      byte == _lineFeed ||
      byte == _carriageReturn ||
      byte == 0x09 ||
      byte == 0x0c ||
      byte == 0x00;

  static bool _isDelimiter(int byte) =>
      byte == _openParenthesis ||
      byte == _closeParenthesis ||
      byte == _lessThan ||
      byte == _greaterThan ||
      byte == _openBracket ||
      byte == _closeBracket ||
      byte == 0x7b ||
      byte == 0x7d ||
      byte == _slash ||
      byte == _percent;

  static bool _isRegular(int byte) =>
      !_isWhitespace(byte) && !_isDelimiter(byte);

  static bool _isDigit(int byte) => byte >= _zero && byte <= _zero + 9;

  static bool _isOctalDigit(int byte) => byte >= _zero && byte <= _zero + 7;

  static bool _isNumberStart(int byte) =>
      _isDigit(byte) || byte == 0x2b || byte == 0x2d || byte == 0x2e;

  static const _lineFeed = 0x0a;
  static const _carriageReturn = 0x0d;
  static const _slash = 0x2f;
  static const _percent = 0x25;
  static const _hash = 0x23;
  static const _backslash = 0x5c;
  static const _openParenthesis = 0x28;
  static const _closeParenthesis = 0x29;
  static const _lessThan = 0x3c;
  static const _greaterThan = 0x3e;
  static const _openBracket = 0x5b;
  static const _closeBracket = 0x5d;
  static const _zero = 0x30;
  static const _capitalR = 0x52;
}
