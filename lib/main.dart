import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'data/audio/platform_music_player.dart';
import 'data/catalog/mutopia_catalog.dart';
import 'data/documents/caching_document_source.dart';
import 'data/documents/http_document_source.dart';
import 'data/sheet_music/pdf_sheet_music_parser.dart';
import 'domain/use_cases/prepare_piece.dart';
import 'presentation/mijn_app.dart';
import 'presentation/state/piece_player_controller.dart';

void main() {
  final catalog = MutopiaCatalog(archiveBaseUri: _mutopiaArchiveUri());
  final controller = PiecePlayerController(
    preparePiece: PreparePiece(
      documentSource: CachingDocumentSource(HttpDocumentSource(http.Client())),
      scoreParser: const PdfSheetMusicParser(),
    ),
    musicPlayer: createPlatformMusicPlayer(),
  );
  runApp(MijnApp(pieces: catalog.pieces, controller: controller));
}

Uri _mutopiaArchiveUri() => kIsWeb
    ? Uri.base.resolve('/${MutopiaCatalog.webProxyPrefix}/')
    : MutopiaCatalog.officialArchiveUri;
