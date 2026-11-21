import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/documents/proxied_document_source.dart';

import '../../support/fakes.dart';

void main() {
  final mutopiaRoute = ProxyRoute(
    publicPrefix: Uri.parse('https://www.mutopiaproject.org/ftp/'),
    proxyPrefix: Uri.parse('http://localhost:8080/mutopia/'),
  );

  test('a link covered by a route is downloaded through the proxy', () async {
    final source = FakeDocumentSource();

    await ProxiedDocumentSource(source, routes: [mutopiaRoute]).fetch(
      Uri.parse(
        'https://www.mutopiaproject.org/ftp/BeethovenLv/ode/ode-a4.pdf',
      ),
    );

    expect(source.fetchedUris, [
      Uri.parse('http://localhost:8080/mutopia/BeethovenLv/ode/ode-a4.pdf'),
    ]);
  });

  test('other links are downloaded directly', () async {
    final source = FakeDocumentSource();
    final elsewhere = Uri.parse('https://example.org/piece.pdf');

    await ProxiedDocumentSource(
      source,
      routes: [mutopiaRoute],
    ).fetch(elsewhere);

    expect(source.fetchedUris, [elsewhere]);
  });
}
