import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/pdf/pdf_object.dart';
import 'package:mijn_app/data/pdf/pdf_object_parser.dart';

PdfObject _parse(String source) =>
    PdfObjectParser(latin1.encode(source)).readObject();

void main() {
  test('reads a dictionary with names, numbers and references', () {
    final dictionary = _parse(
      '<< /Type /Font /FirstChar 0 /Encoding 30 0 R >>',
    ) as PdfDictionary;

    expect((dictionary['Type'] as PdfName).value, 'Font');
    expect((dictionary['FirstChar'] as PdfNumber).value, 0);
    expect((dictionary['Encoding'] as PdfReference).objectNumber, 30);
  });

  test('reads glyph names with dots from a differences array', () {
    final array = _parse('[ 0/noteheads.s2/flags.u3 ]') as PdfArray;

    expect(array.items.whereType<PdfName>().map((name) => name.value), [
      'noteheads.s2',
      'flags.u3',
    ]);
  });

  test('reads escaped and octal characters in literal strings', () {
    final string = _parse(r'(\(a\)\001)') as PdfString;

    expect(string.bytes, [0x28, 0x61, 0x29, 0x01]);
  });

  test('keeps two numbers apart when they are not a reference', () {
    final parser = PdfObjectParser(latin1.encode('1 0 0 1 422.38 673.67 Tm'));
    final operands = [
      for (var index = 0; index < 6; index++) parser.readObject(),
    ];

    expect(operands.every((operand) => operand is PdfNumber), isTrue);
    expect((parser.readObject() as PdfOperator).name, 'Tm');
  });
}
