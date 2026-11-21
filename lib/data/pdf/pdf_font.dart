import 'pdf_document.dart';
import 'pdf_object.dart';

class PdfFont {
  const PdfFont({
    required this.glyphNames,
    required this.firstCharacterCode,
    required this.widths,
    this.missingWidth = 500,
  });

  factory PdfFont.from(PdfDictionary font, PdfDocument document) {
    final descriptor = document.resolveDictionary(font['FontDescriptor']);
    return PdfFont(
      glyphNames: _glyphNamesFromEncoding(
        document.resolve(font['Encoding']),
        document,
      ),
      firstCharacterCode:
          document.resolveNumber(font['FirstChar'])?.toInt() ?? 0,
      widths: [
        for (final width in document.resolveArray(font['Widths']))
          document.resolveNumber(width)?.toDouble() ?? 0,
      ],
      missingWidth:
          document.resolveNumber(descriptor?['MissingWidth'])?.toDouble() ??
          500,
    );
  }

  static const _glyphSpaceUnitsPerTextUnit = 1000;

  final Map<int, String> glyphNames;
  final int firstCharacterCode;
  final List<double> widths;
  final double missingWidth;

  String? glyphNameOf(int code) => glyphNames[code];

  double widthOf(int code) {
    final index = code - firstCharacterCode;
    final width = index >= 0 && index < widths.length
        ? widths[index]
        : missingWidth;
    return width / _glyphSpaceUnitsPerTextUnit;
  }

  static Map<int, String> _glyphNamesFromEncoding(
    PdfObject encoding,
    PdfDocument document,
  ) {
    if (encoding is! PdfDictionary) return const {};
    final glyphNames = <int, String>{};
    var code = 0;
    for (final item in document.resolveArray(encoding['Differences'])) {
      switch (item) {
        case PdfNumber(:final value):
          code = value.toInt();
        case PdfName(:final value):
          glyphNames[code++] = value;
        default:
          break;
      }
    }
    return glyphNames;
  }
}
