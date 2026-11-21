import '../entities/prepared_piece.dart';
import '../entities/sheet_music_piece.dart';
import '../repositories/document_source.dart';
import '../repositories/score_parser.dart';

class PreparePiece {
  const PreparePiece({
    required this._documentSource,
    required this._scoreParser,
  });

  final DocumentSource _documentSource;
  final ScoreParser _scoreParser;

  Future<PreparedPiece> call(SheetMusicPiece piece) async {
    final sheetMusic = await _documentSource.fetch(piece.sheetMusicUri);
    return PreparedPiece(piece: piece, score: _scoreParser.parse(sheetMusic));
  }
}
