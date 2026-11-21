import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/domain/repositories/score_parser.dart';
import 'package:mijn_app/domain/use_cases/add_sheet_music.dart';
import 'package:mijn_app/domain/use_cases/prepare_piece.dart';
import 'package:mijn_app/presentation/state/sheet_music_library_controller.dart';

import '../../support/fakes.dart';

void main() {
  const link = 'https://example.org/sonata.pdf';

  SheetMusicLibraryController libraryWith({
    FakeDocumentSource? documentSource,
    FakeScoreParser? scoreParser,
  }) => SheetMusicLibraryController(
    initialPieces: [pieceForTest],
    addSheetMusic: AddSheetMusic(
      preparePiece: PreparePiece(
        documentSource: documentSource ?? FakeDocumentSource(),
        scoreParser: scoreParser ?? FakeScoreParser(),
      ),
    ),
  );

  test('starts with the initial pieces and a hidden add form', () {
    final library = libraryWith();

    expect(library.pieces, [pieceForTest]);
    expect(library.addState, isA<AddFormHidden>());
  });

  test('shows that the link is being checked', () {
    final documentSource = FakeDocumentSource()
      ..pendingFetch = Completer<Uint8List>();
    final library = libraryWith(documentSource: documentSource)..showAddForm();

    library.add(link);

    expect(library.addState, isA<CheckingLink>());
  });

  test('a playable link is added to the list and closes the form', () async {
    final library = libraryWith()..showAddForm();

    await library.add(link);

    expect(library.pieces.last.sheetMusicUri, Uri.parse(link));
    expect(library.addState, isA<AddFormHidden>());
  });

  test('an unplayable link keeps the form open with an explanation', () async {
    final library = libraryWith(
      scoreParser: FakeScoreParser(
        failure: const SheetMusicNotRecognizedException.noVectorSheetMusic(),
      ),
    )..showAddForm();

    await library.add(link);

    final state = library.addState as AddFormShown;
    expect(state.failure, contains('geen vector-bladmuziek'));
    expect(library.pieces, [pieceForTest]);
  });
}
