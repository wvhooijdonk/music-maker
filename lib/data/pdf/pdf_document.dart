import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'pdf_object.dart';
import 'pdf_object_parser.dart';

class PdfDocument {
  PdfDocument._(this._bytes, this._objectOffsets);

  factory PdfDocument.parse(Uint8List bytes) {
    final text = String.fromCharCodes(bytes);
    if (!text.startsWith('%PDF')) {
      throw const FormatException('Geen PDF-bestand');
    }
    final objectOffsets = <int, int>{
      for (final match in _objectHeader.allMatches(text))
        int.parse(match.group(1)!): match.end,
    };
    return PdfDocument._(bytes, objectOffsets);
  }

  static final _objectHeader = RegExp(r'(\d+)\s+\d+\s+obj\b');

  final Uint8List _bytes;
  final Map<int, int> _objectOffsets;
  final _parsedObjects = <int, PdfObject>{};

  PdfObject resolve(PdfObject? object) {
    if (object is PdfReference) return _objectNumbered(object.objectNumber);
    return object ?? const PdfNull();
  }

  PdfDictionary? resolveDictionary(PdfObject? object) =>
      switch (resolve(object)) {
        PdfDictionary dictionary => dictionary,
        PdfStream stream => stream.dictionary,
        _ => null,
      };

  List<PdfObject> resolveArray(PdfObject? object) => switch (resolve(object)) {
    PdfArray array => array.items,
    _ => const [],
  };

  num? resolveNumber(PdfObject? object) => switch (resolve(object)) {
    PdfNumber number => number.value,
    _ => null,
  };

  List<PdfDictionary> get pages {
    final catalog = resolveDictionary(_trailerRoot);
    final pageTreeRoot = resolveDictionary(catalog?['Pages']);
    if (pageTreeRoot == null) {
      throw const FormatException('PDF: geen pagina\'s gevonden');
    }
    return _pagesBelow(pageTreeRoot);
  }

  PdfObject? lookupInherited(PdfDictionary page, String key) {
    PdfDictionary? node = page;
    for (var depth = 0; node != null && depth < 32; depth++) {
      final value = node[key];
      if (value != null) return value;
      node = resolveDictionary(node['Parent']);
    }
    return null;
  }

  Uint8List contentOf(PdfDictionary page) {
    final contents = resolve(page['Contents']);
    final streams = switch (contents) {
      PdfArray(:final items) => items.map(resolve).whereType<PdfStream>(),
      PdfStream stream => [stream],
      _ => const <PdfStream>[],
    };
    final combined = BytesBuilder(copy: false);
    for (final stream in streams) {
      combined
        ..add(decode(stream))
        ..addByte(0x0a);
    }
    return combined.toBytes();
  }

  Uint8List decode(PdfStream stream) {
    final filter = resolve(stream.dictionary['Filter']);
    final filterNames = switch (filter) {
      PdfName name => [name.value],
      PdfArray array =>
        array.items
            .map(resolve)
            .whereType<PdfName>()
            .map((name) => name.value)
            .toList(),
      _ => const <String>[],
    };
    var data = stream.encodedData;
    for (final filterName in filterNames) {
      if (filterName != 'FlateDecode') {
        throw FormatException('PDF: filter $filterName wordt niet ondersteund');
      }
      data = const ZLibDecoder().decodeBytes(data);
    }
    return data;
  }

  PdfObject? get _trailerRoot {
    final catalogNumber = _objectOffsets.keys.firstWhere(
      (number) => switch (_objectNumbered(number)) {
        PdfDictionary(:final entries) => switch (entries['Type']) {
          PdfName(value: 'Catalog') => true,
          _ => false,
        },
        _ => false,
      },
      orElse: () => throw const FormatException('PDF: catalogus ontbreekt'),
    );
    return PdfReference(catalogNumber);
  }

  List<PdfDictionary> _pagesBelow(PdfDictionary node) {
    final isPage = switch (node['Type']) {
      PdfName(value: 'Page') => true,
      _ => node['Kids'] == null,
    };
    if (isPage) return [node];
    return [
      for (final kid in resolveArray(node['Kids']))
        ...?switch (resolveDictionary(kid)) {
          final PdfDictionary kidNode => _pagesBelow(kidNode),
          null => null,
        },
    ];
  }

  PdfObject _objectNumbered(int number) {
    final cached = _parsedObjects[number];
    if (cached != null) return cached;
    final offset = _objectOffsets[number];
    if (offset == null) return const PdfNull();
    _parsedObjects[number] = const PdfNull();
    final parsed = _parseObjectAt(offset);
    _parsedObjects[number] = parsed;
    return parsed;
  }

  PdfObject _parseObjectAt(int offset) {
    final parser = PdfObjectParser(_bytes, position: offset);
    final object = parser.readObject();
    if (object is! PdfDictionary || parser.isAtEnd) return object;
    final positionAfterDictionary = parser.position;
    final keyword = parser.readObject();
    if (keyword is! PdfOperator || keyword.name != 'stream') {
      return object;
    }
    parser.skipEndOfLine();
    final length = resolveNumber(object['Length'])?.toInt();
    if (length == null) {
      throw FormatException(
        'PDF: stream zonder lengte',
        _bytes,
        positionAfterDictionary,
      );
    }
    return PdfStream(object, parser.readBytes(length));
  }
}
