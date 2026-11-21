import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/domain/repositories/score_parser.dart';
import 'package:mijn_app/domain/use_cases/prepare_piece.dart';
import 'package:mijn_app/presentation/state/piece_player_controller.dart';
import 'package:mijn_app/presentation/state/piece_player_state.dart';

import '../../support/fakes.dart';

void main() {
  late FakeDocumentSource documentSource;
  late FakeScoreParser scoreParser;
  late FakeMusicPlayer musicPlayer;

  PiecePlayerController controllerWith({FakeScoreParser? parser}) {
    return PiecePlayerController(
      preparePiece: PreparePiece(
        documentSource: documentSource,
        scoreParser: parser ?? scoreParser,
      ),
      musicPlayer: musicPlayer,
    );
  }

  setUp(() {
    documentSource = FakeDocumentSource();
    scoreParser = FakeScoreParser();
    musicPlayer = FakeMusicPlayer();
  });

  test('shows the preparation while the sheet music is downloaded', () {
    documentSource.pendingFetch = Completer<Uint8List>();
    final controller = controllerWith();

    controller.select(pieceForTest);

    expect(controller.state, isA<PreparingPiece>());
  });

  test('is ready to play once the sheet music is recognised', () async {
    final controller = controllerWith();

    await controller.select(pieceForTest);

    final state = controller.state as ReadyToPlay;
    expect(state.prepared.score, scoreForTest);
  });

  test('explains why sheet music could not be recognised', () async {
    final controller = controllerWith(
      parser: FakeScoreParser(
        failure: const SheetMusicNotRecognizedException.noVectorSheetMusic(),
      ),
    );

    await controller.select(pieceForTest);

    final state = controller.state as PreparationFailed;
    expect(state.message, contains('geen vector-bladmuziek'));
  });

  test('start plays the score and reports progress', () async {
    final controller = controllerWith();
    await controller.select(pieceForTest);

    controller.start();
    musicPlayer.reportProgress(const Duration(milliseconds: 1500));
    await pumpEventQueue();

    final state = controller.state as Playing;
    expect(musicPlayer.playedScore, scoreForTest);
    expect(state.elapsed, const Duration(milliseconds: 1500));
    expect(state.progress, 0.5);
  });

  test('stop silences the player and allows starting again', () async {
    final controller = controllerWith();
    await controller.select(pieceForTest);
    controller.start();

    controller.stop();

    expect(musicPlayer.stopCount, greaterThan(0));
    expect(controller.state, isA<ReadyToPlay>());
  });

  test('returns to ready when the piece has finished', () async {
    final controller = controllerWith();
    await controller.select(pieceForTest);
    controller.start();

    await musicPlayer.finish();
    await pumpEventQueue();

    expect(controller.state, isA<ReadyToPlay>());
  });

  test(
    'play now unlocks audio output before downloading and then starts',
    () async {
      final pendingDownload = Completer<Uint8List>();
      documentSource.pendingFetch = pendingDownload;
      final controller = controllerWith();

      final playing = controller.playNow(pieceForTest);

      expect(musicPlayer.preparedOutputCount, 1);
      expect(musicPlayer.isPlaying, isFalse);
      pendingDownload.complete(Uint8List(0));
      await playing;
      expect(controller.state, isA<Playing>());
      expect(musicPlayer.playedScore, scoreForTest);
    },
  );

  test('play now does not start a piece that failed to prepare', () async {
    final controller = controllerWith(
      parser: FakeScoreParser(
        failure: const SheetMusicNotRecognizedException.noVectorSheetMusic(),
      ),
    );

    await controller.playNow(pieceForTest);

    expect(controller.state, isA<PreparationFailed>());
    expect(musicPlayer.isPlaying, isFalse);
  });
}
