import '../../domain/entities/sheet_music_piece.dart';
import '../../domain/repositories/sheet_music_catalog.dart';

class MutopiaCatalog implements SheetMusicCatalog {
  MutopiaCatalog({Uri? archiveBaseUri})
    : pieces = _pieces(archiveBaseUri ?? officialArchiveUri);

  static List<SheetMusicPiece> _pieces(Uri archiveBaseUri) =>
      List.unmodifiable([
        _piece(
          archiveBaseUri,
          title: 'Ode to Joy',
          composer: 'L. v. Beethoven',
          folder: 'BeethovenLv/ode',
          fileName: 'ode',
        ),
        _piece(
          archiveBaseUri,
          title: 'Prelude in C (BWV 846)',
          composer: 'J. S. Bach',
          folder: 'BachJS/BWV846/wtk1-prelude1',
          fileName: 'wtk1-prelude1',
        ),
        _piece(
          archiveBaseUri,
          title: 'Menuet in G (BWV Anh. 114)',
          composer: 'J. S. Bach',
          folder: 'BachJS/BWVAnh114/anna-magdalena-04',
          fileName: 'anna-magdalena-04',
        ),
      ]);

  static final officialArchiveUri = Uri.parse(
    'https://www.mutopiaproject.org/ftp/',
  );

  @override
  final List<SheetMusicPiece> pieces;

  static SheetMusicPiece _piece(
    Uri archiveBaseUri, {
    required String title,
    required String composer,
    required String folder,
    required String fileName,
  }) {
    return SheetMusicPiece(
      title: title,
      composer: composer,
      sheetMusicUri: archiveBaseUri.resolve('$folder/$fileName-a4.pdf'),
    );
  }
}
