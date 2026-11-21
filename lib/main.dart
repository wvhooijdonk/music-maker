import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'data/audio/platform_music_player.dart';
import 'data/catalog/mutopia_catalog.dart';
import 'data/documents/caching_document_source.dart';
import 'data/documents/http_document_source.dart';
import 'data/documents/proxied_document_source.dart';
import 'data/links/url_launcher_link_opener.dart';
import 'data/sheet_music/pdf_sheet_music_parser.dart';
import 'domain/use_cases/add_sheet_music.dart';
import 'domain/use_cases/prepare_piece.dart';
import 'presentation/mijn_app.dart';
import 'presentation/state/piece_player_controller.dart';
import 'presentation/state/sheet_music_library_controller.dart';

void main() {
  final preparePiece = PreparePiece(
    documentSource: CachingDocumentSource(
      ProxiedDocumentSource(
        HttpDocumentSource(http.Client()),
        routes: kIsWeb ? _devServerProxyRoutes() : const [],
      ),
    ),
    scoreParser: const PdfSheetMusicParser(),
  );
  runApp(
    MijnApp(
      library: SheetMusicLibraryController(
        initialPieces: MutopiaCatalog().pieces,
        addSheetMusic: AddSheetMusic(preparePiece: preparePiece),
      ),
      player: PiecePlayerController(
        preparePiece: preparePiece,
        musicPlayer: createPlatformMusicPlayer(),
      ),
      linkOpener: const UrlLauncherLinkOpener(),
    ),
  );
}

List<ProxyRoute> _devServerProxyRoutes() => [
  ProxyRoute(
    publicPrefix: MutopiaCatalog.officialArchiveUri,
    proxyPrefix: Uri.base.resolve('/mutopia/'),
  ),
];
