import 'dart:async';
import 'dart:typed_data';

import 'package:mijn_app/domain/entities/note.dart';
import 'package:mijn_app/domain/entities/score.dart';
import 'package:mijn_app/domain/entities/sheet_music_piece.dart';
import 'package:mijn_app/domain/repositories/document_source.dart';
import 'package:mijn_app/domain/repositories/music_player.dart';
import 'package:mijn_app/domain/repositories/score_parser.dart';

final pieceForTest = SheetMusicPiece(
  title: 'Ode to Joy',
  composer: 'L. v. Beethoven',
  sheetMusicUri: Uri.parse('https://example.org/ode.pdf'),
);

final scoreForTest = Score([
  const Note(pitch: 60, start: Duration.zero, length: Duration(seconds: 1)),
  const Note(
    pitch: 64,
    start: Duration(seconds: 1),
    length: Duration(seconds: 2),
  ),
]);

class FakeDocumentSource implements DocumentSource {
  FakeDocumentSource({this.failure});

  final Object? failure;
  final fetchedUris = <Uri>[];
  Completer<Uint8List>? pendingFetch;

  @override
  Future<Uint8List> fetch(Uri uri) async {
    fetchedUris.add(uri);
    final failure = this.failure;
    if (failure != null) throw failure;
    final pending = pendingFetch;
    if (pending != null) return pending.future;
    return Uint8List.fromList(uri.toString().codeUnits);
  }
}

class FakeScoreParser implements ScoreParser {
  FakeScoreParser({this.failure});

  final Object? failure;
  final parsedDocuments = <Uint8List>[];

  @override
  Score parse(Uint8List sheetMusic) {
    parsedDocuments.add(sheetMusic);
    final failure = this.failure;
    if (failure != null) throw failure;
    return scoreForTest;
  }
}

class FakeMusicPlayer implements MusicPlayer {
  StreamController<Duration>? _progress;
  Score? playedScore;
  var stopCount = 0;

  bool get isPlaying => _progress != null;

  @override
  Stream<Duration> play(Score score) {
    playedScore = score;
    final progress = StreamController<Duration>();
    _progress = progress;
    return progress.stream;
  }

  void reportProgress(Duration elapsed) => _progress?.add(elapsed);

  Future<void> finish() async {
    await _progress?.close();
    _progress = null;
  }

  @override
  void stop() {
    stopCount++;
    _progress?.close();
    _progress = null;
  }
}
