import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/pdf_sheet_music_parser.dart';
import 'package:mijn_app/domain/repositories/score_parser.dart';

Uint8List _pdfWithPageContent(String content) {
  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >>',
    '<< /Length ${content.length} >>\nstream\n$content\nendstream',
  ];
  final buffer = StringBuffer('%PDF-1.4\n');
  for (final (index, object) in objects.indexed) {
    buffer.write('${index + 1} 0 obj\n$object\nendobj\n');
  }
  buffer.write('trailer\n<< /Root 1 0 R >>\n%%EOF\n');
  return Uint8List.fromList(latin1.encode(buffer.toString()));
}

void main() {
  test('a PDF with only an image and no vector staves is rejected clearly', () {
    final scannedPage = _pdfWithPageContent('q 595 0 0 842 0 0 cm /Im0 Do Q');

    expect(
      () => const PdfSheetMusicParser().parse(scannedPage),
      throwsA(isA<SheetMusicNotRecognizedException>()),
    );
  });

  test(
    'a PDF with staves but without named music symbols is rejected clearly',
    () {
      final staffLines = [
        for (var line = 0; line < 5; line++)
          '50 ${700 + line * 5} m 550 ${700 + line * 5} l S',
      ].join('\n');

      expect(
        () =>
            const PdfSheetMusicParser().parse(_pdfWithPageContent(staffLines)),
        throwsA(
          isA<SheetMusicNotRecognizedException>().having(
            (exception) => exception.reason,
            'reason',
            contains('notenbalken'),
          ),
        ),
      );
    },
  );

  test('a file that is not a PDF is rejected', () {
    expect(
      () => const PdfSheetMusicParser().parse(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
