import 'engraving.dart';

class TempoReader {
  const TempoReader();

  static const defaultQuarterNotesPerMinute = 90.0;
  static final _metronomeMark = RegExp(r'=\s*(\d{2,3})\b');

  double quarterNotesPerMinute(Iterable<TextLine> textLines) {
    for (final line in textLines) {
      final match = _metronomeMark.firstMatch(line.text);
      if (match != null) return double.parse(match.group(1)!);
    }
    return defaultQuarterNotesPerMinute;
  }
}
