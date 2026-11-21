import 'dart:typed_data';

import '../../domain/repositories/document_source.dart';

class CachingDocumentSource implements DocumentSource {
  CachingDocumentSource(this._source);

  final DocumentSource _source;
  final _cachedDocuments = <Uri, Future<Uint8List>>{};

  @override
  Future<Uint8List> fetch(Uri uri) {
    return _cachedDocuments.putIfAbsent(
      uri,
      () => _fetchForgettingFailures(uri),
    );
  }

  Future<Uint8List> _fetchForgettingFailures(Uri uri) async {
    try {
      return await _source.fetch(uri);
    } catch (_) {
      _cachedDocuments.remove(uri);
      rethrow;
    }
  }
}
