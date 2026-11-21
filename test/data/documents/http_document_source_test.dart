import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mijn_app/data/documents/http_document_source.dart';
import 'package:mijn_app/domain/repositories/document_source.dart';

void main() {
  final uri = Uri.parse('https://example.org/piece.pdf');

  test('returns the downloaded bytes', () async {
    final source = HttpDocumentSource(
      MockClient((request) async => http.Response.bytes([1, 2, 3], 200)),
    );

    expect(await source.fetch(uri), [1, 2, 3]);
  });

  test('reports an unsuccessful response as a fetch failure', () async {
    final source = HttpDocumentSource(
      MockClient((request) async => http.Response('not found', 404)),
    );

    await expectLater(
      source.fetch(uri),
      throwsA(isA<DocumentFetchException>()),
    );
  });

  test('reports a network error as a fetch failure', () async {
    final source = HttpDocumentSource(
      MockClient((request) async => throw http.ClientException('offline')),
    );

    await expectLater(
      source.fetch(uri),
      throwsA(isA<DocumentFetchException>()),
    );
  });
}
