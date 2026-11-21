import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/documents/caching_document_source.dart';

import '../../support/fakes.dart';

void main() {
  final uri = Uri.parse('https://example.org/piece.pdf');

  test('a document is downloaded only once', () async {
    final source = FakeDocumentSource();
    final cachingSource = CachingDocumentSource(source);

    final first = await cachingSource.fetch(uri);
    final second = await cachingSource.fetch(uri);

    expect(second, same(first));
    expect(source.fetchedUris, [uri]);
  });

  test('a failed download is retried on the next request', () async {
    final failingSource = FakeDocumentSource(failure: Exception('offline'));
    final cachingSource = CachingDocumentSource(failingSource);

    await expectLater(cachingSource.fetch(uri), throwsException);
    await expectLater(cachingSource.fetch(uri), throwsException);

    expect(failingSource.fetchedUris, [uri, uri]);
  });
}
