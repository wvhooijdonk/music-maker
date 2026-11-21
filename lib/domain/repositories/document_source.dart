import 'dart:typed_data';

abstract interface class DocumentSource {
  Future<Uint8List> fetch(Uri uri);
}

class DocumentFetchException implements Exception {
  const DocumentFetchException(this.uri, this.reason);

  final Uri uri;
  final String reason;

  @override
  String toString() => 'Downloaden van $uri mislukt: $reason';
}
