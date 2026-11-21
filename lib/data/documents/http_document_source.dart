import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../domain/repositories/document_source.dart';

class HttpDocumentSource implements DocumentSource {
  HttpDocumentSource(this._client);

  final http.Client _client;

  @override
  Future<Uint8List> fetch(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri);
    } on Exception catch (error) {
      throw DocumentFetchException(uri, '$error');
    }
    if (response.statusCode != 200) {
      throw DocumentFetchException(uri, 'HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
