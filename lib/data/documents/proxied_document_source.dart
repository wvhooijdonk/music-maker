import 'dart:typed_data';

import '../../domain/repositories/document_source.dart';

class ProxyRoute {
  const ProxyRoute({required this.publicPrefix, required this.proxyPrefix});

  final Uri publicPrefix;
  final Uri proxyPrefix;

  bool covers(Uri uri) => uri.toString().startsWith(publicPrefix.toString());

  Uri reroute(Uri uri) => proxyPrefix.resolve(
    uri.toString().substring(publicPrefix.toString().length),
  );
}

class ProxiedDocumentSource implements DocumentSource {
  const ProxiedDocumentSource(this._source, {required this._routes});

  final DocumentSource _source;
  final List<ProxyRoute> _routes;

  @override
  Future<Uint8List> fetch(Uri uri) {
    final route = _routes.where((route) => route.covers(uri)).firstOrNull;
    return _source.fetch(route?.reroute(uri) ?? uri);
  }
}
