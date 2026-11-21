import 'dart:typed_data';

sealed class PdfObject {
  const PdfObject();
}

class PdfNumber extends PdfObject {
  const PdfNumber(this.value);

  final num value;
}

class PdfName extends PdfObject {
  const PdfName(this.value);

  final String value;
}

class PdfString extends PdfObject {
  const PdfString(this.bytes);

  final Uint8List bytes;
}

class PdfBoolean extends PdfObject {
  const PdfBoolean(this.value);

  final bool value;
}

class PdfNull extends PdfObject {
  const PdfNull();
}

class PdfArray extends PdfObject {
  const PdfArray(this.items);

  final List<PdfObject> items;
}

class PdfDictionary extends PdfObject {
  const PdfDictionary(this.entries);

  final Map<String, PdfObject> entries;

  PdfObject? operator [](String key) => entries[key];
}

class PdfReference extends PdfObject {
  const PdfReference(this.objectNumber);

  final int objectNumber;
}

class PdfStream extends PdfObject {
  const PdfStream(this.dictionary, this.encodedData);

  final PdfDictionary dictionary;
  final Uint8List encodedData;
}

class PdfOperator extends PdfObject {
  const PdfOperator(this.name);

  final String name;
}
