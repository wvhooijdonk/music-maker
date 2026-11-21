import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../domain/entities/prepared_piece.dart';
import '../../domain/entities/sheet_music_piece.dart';
import '../../domain/repositories/document_source.dart';
import '../../domain/repositories/music_player.dart';
import '../../domain/repositories/score_parser.dart';
import '../../domain/use_cases/prepare_piece.dart';
import 'piece_player_state.dart';

class PiecePlayerController extends ChangeNotifier {
  PiecePlayerController({
    required this._preparePiece,
    required this._musicPlayer,
  });

  final PreparePiece _preparePiece;
  final MusicPlayer _musicPlayer;
  StreamSubscription<Duration>? _playback;
  PiecePlayerState _state = const NothingSelected();

  PiecePlayerState get state => _state;

  Future<void> select(SheetMusicPiece piece) async {
    stop();
    _changeState(PreparingPiece(piece));
    try {
      final prepared = await _preparePiece(piece);
      if (_isStillPreparing(piece)) _changeState(ReadyToPlay(prepared));
    } catch (error) {
      if (_isStillPreparing(piece)) {
        _changeState(PreparationFailed(piece, _describe(error)));
      }
    }
  }

  void start() {
    final prepared = switch (_state) {
      ReadyToPlay(:final prepared) => prepared,
      _ => null,
    };
    if (prepared == null) return;
    _changeState(Playing(prepared, elapsed: Duration.zero));
    _playback = _musicPlayer
        .play(prepared.score)
        .listen(
          (elapsed) => _changeState(Playing(prepared, elapsed: elapsed)),
          onError: (Object error) =>
              _changeState(PreparationFailed(prepared.piece, _describe(error))),
          onDone: () => _returnToReady(prepared),
        );
  }

  void stop() {
    final prepared = switch (_state) {
      Playing(:final prepared) => prepared,
      _ => null,
    };
    _musicPlayer.stop();
    _playback?.cancel();
    _playback = null;
    if (prepared != null) _returnToReady(prepared);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void _returnToReady(PreparedPiece prepared) {
    _playback = null;
    if (_state is Playing) _changeState(ReadyToPlay(prepared));
  }

  bool _isStillPreparing(SheetMusicPiece piece) => switch (_state) {
    PreparingPiece(piece: final preparing) => identical(preparing, piece),
    _ => false,
  };

  void _changeState(PiecePlayerState state) {
    _state = state;
    notifyListeners();
  }

  static String _describe(Object error) => switch (error) {
    SheetMusicNotRecognizedException(:final reason) => reason,
    DocumentFetchException() =>
      'De bladmuziek kon niet worden gedownload. ($error)',
    FormatException(:final message) =>
      'De PDF kon niet worden gelezen: $message',
    UnsupportedError(:final message) =>
      message ?? 'Niet ondersteund op dit platform.',
    _ => 'Er ging iets mis: $error',
  };
}
