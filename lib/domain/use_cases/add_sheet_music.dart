import '../entities/sheet_music_piece.dart';
import 'prepare_piece.dart';

class AddSheetMusic {
  const AddSheetMusic({required this._preparePiece});

  final PreparePiece _preparePiece;

  Future<SheetMusicPiece> call(
    String link, {
    required List<SheetMusicPiece> existingPieces,
  }) async {
    final uri = _parseWebLink(link.trim());
    if (existingPieces.any((piece) => piece.sheetMusicUri == uri)) {
      throw const InvalidSheetMusicLinkException(
        'Dit muziekstuk staat al in de lijst.',
      );
    }
    final piece = SheetMusicPiece(
      title: _titleFrom(uri),
      composer: uri.host,
      sheetMusicUri: uri,
    );
    await _preparePiece(piece);
    return piece;
  }

  Uri _parseWebLink(String link) {
    final uri = Uri.tryParse(link);
    final isWebLink =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isWebLink) {
      throw const InvalidSheetMusicLinkException(
        'Dit is geen geldige link. Plak een volledige link die begint met https://',
      );
    }
    return uri;
  }

  String _titleFrom(Uri uri) {
    final fileName = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .lastOrNull;
    if (fileName == null) return uri.host;
    return fileName
        .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-_]+'), ' ');
  }
}

class InvalidSheetMusicLinkException implements Exception {
  const InvalidSheetMusicLinkException(this.reason);

  final String reason;

  @override
  String toString() => reason;
}
