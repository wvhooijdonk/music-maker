import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/domain/use_cases/prepare_piece.dart';

import '../../support/fakes.dart';

void main() {
  test('downloads the sheet music and parses it into a score', () async {
    final documentSource = FakeDocumentSource();
    final scoreParser = FakeScoreParser();

    final prepared = await PreparePiece(
      documentSource: documentSource,
      scoreParser: scoreParser,
    )(pieceForTest);

    expect(documentSource.fetchedUris, [pieceForTest.sheetMusicUri]);
    expect(scoreParser.parsedDocuments, hasLength(1));
    expect(prepared.piece, pieceForTest);
    expect(prepared.score, scoreForTest);
  });
}
