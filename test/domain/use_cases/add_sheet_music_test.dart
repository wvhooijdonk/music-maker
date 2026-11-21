import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/domain/repositories/score_parser.dart';
import 'package:mijn_app/domain/use_cases/add_sheet_music.dart';
import 'package:mijn_app/domain/use_cases/prepare_piece.dart';

import '../../support/fakes.dart';

void main() {
  const link = 'https://www.mutopiaproject.org/ftp/BachJS/menuet-a4.pdf';

  AddSheetMusic addSheetMusicWith({
    FakeDocumentSource? documentSource,
    FakeScoreParser? scoreParser,
  }) => AddSheetMusic(
    preparePiece: PreparePiece(
      documentSource: documentSource ?? FakeDocumentSource(),
      scoreParser: scoreParser ?? FakeScoreParser(),
    ),
  );

  test(
    'a playable PDF link becomes a piece named after the file and website',
    () async {
      final piece = await addSheetMusicWith()(link, existingPieces: const []);

      expect(piece.sheetMusicUri, Uri.parse(link));
      expect(piece.title, 'menuet a4');
      expect(piece.composer, 'www.mutopiaproject.org');
    },
  );

  test(
    'the sheet music is downloaded and recognised before it is accepted',
    () async {
      final documentSource = FakeDocumentSource();
      final scoreParser = FakeScoreParser();

      await addSheetMusicWith(
        documentSource: documentSource,
        scoreParser: scoreParser,
      )('  $link  ', existingPieces: const []);

      expect(documentSource.fetchedUris, [Uri.parse(link)]);
      expect(scoreParser.parsedDocuments, hasLength(1));
    },
  );

  test('text that is not a web link is refused without downloading', () async {
    final documentSource = FakeDocumentSource();

    await expectLater(
      addSheetMusicWith(documentSource: documentSource)(
        'menuet.pdf',
        existingPieces: const [],
      ),
      throwsA(isA<InvalidSheetMusicLinkException>()),
    );
    expect(documentSource.fetchedUris, isEmpty);
  });

  test('a piece that is already in the list is refused', () async {
    await expectLater(
      addSheetMusicWith()(
        pieceForTest.sheetMusicUri.toString(),
        existingPieces: [pieceForTest],
      ),
      throwsA(isA<InvalidSheetMusicLinkException>()),
    );
  });

  test('a PDF that cannot be played is refused', () async {
    await expectLater(
      addSheetMusicWith(
        scoreParser: FakeScoreParser(
          failure: const SheetMusicNotRecognizedException.noVectorSheetMusic(),
        ),
      )(link, existingPieces: const []),
      throwsA(isA<SheetMusicNotRecognizedException>()),
    );
  });
}
