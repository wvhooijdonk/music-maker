import 'score.dart';
import 'sheet_music_piece.dart';

class PreparedPiece {
  const PreparedPiece({required this.piece, required this.score});

  final SheetMusicPiece piece;
  final Score score;
}
