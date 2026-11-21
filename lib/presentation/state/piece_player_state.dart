import '../../domain/entities/prepared_piece.dart';
import '../../domain/entities/sheet_music_piece.dart';

sealed class PiecePlayerState {
  const PiecePlayerState();
}

class NothingSelected extends PiecePlayerState {
  const NothingSelected();
}

class PreparingPiece extends PiecePlayerState {
  const PreparingPiece(this.piece);

  final SheetMusicPiece piece;
}

class ReadyToPlay extends PiecePlayerState {
  const ReadyToPlay(this.prepared);

  final PreparedPiece prepared;
}

class Playing extends PiecePlayerState {
  const Playing(this.prepared, {required this.elapsed});

  final PreparedPiece prepared;
  final Duration elapsed;

  double get progress {
    final total = prepared.score.duration.inMicroseconds;
    if (total == 0) return 1;
    return (elapsed.inMicroseconds / total).clamp(0, 1);
  }
}

class PreparationFailed extends PiecePlayerState {
  const PreparationFailed(this.piece, this.message);

  final SheetMusicPiece piece;
  final String message;
}
