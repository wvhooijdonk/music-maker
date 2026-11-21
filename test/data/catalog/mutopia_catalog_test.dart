import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/catalog/mutopia_catalog.dart';

void main() {
  test('offers three pieces with title and composer', () {
    final catalog = MutopiaCatalog(
      archiveBaseUri: MutopiaCatalog.officialArchiveUri,
    );

    expect(catalog.pieces, hasLength(3));
    expect(catalog.pieces.first.title, 'Ode to Joy');
    expect(catalog.pieces.first.composer, 'L. v. Beethoven');
  });

  test('sheet music points to the A4 PDF in the archive', () {
    final catalog = MutopiaCatalog(
      archiveBaseUri: MutopiaCatalog.officialArchiveUri,
    );

    expect(
      catalog.pieces.first.sheetMusicUri.toString(),
      'https://www.mutopiaproject.org/ftp/BeethovenLv/ode/ode-a4.pdf',
    );
  });

  test('the archive location can be replaced, for example by a proxy', () {
    final catalog = MutopiaCatalog(
      archiveBaseUri: Uri.parse('http://localhost:8080/mutopia/'),
    );

    expect(
      catalog.pieces.first.sheetMusicUri.toString(),
      'http://localhost:8080/mutopia/BeethovenLv/ode/ode-a4.pdf',
    );
  });
}
