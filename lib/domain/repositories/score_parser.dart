import 'dart:typed_data';

import '../entities/score.dart';

abstract interface class ScoreParser {
  Score parse(Uint8List sheetMusic);
}

class SheetMusicNotRecognizedException implements Exception {
  const SheetMusicNotRecognizedException(this.reason);

  const SheetMusicNotRecognizedException.noVectorSheetMusic()
    : reason =
          'Deze PDF bevat geen vector-bladmuziek (bijvoorbeeld een scan of foto). '
          'Alleen digitaal gezette bladmuziek kan worden afgespeeld.';

  const SheetMusicNotRecognizedException.noNamedMusicSymbols()
    : reason =
          'In deze PDF zijn notenbalken gevonden, maar geen herkenbare muzieksymbolen.';

  final String reason;

  @override
  String toString() => reason;
}
