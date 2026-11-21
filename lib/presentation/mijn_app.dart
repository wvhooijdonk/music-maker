import 'package:material_ui/material_ui.dart';

import '../domain/repositories/link_opener.dart';
import 'pages/home_page.dart';
import 'state/piece_player_controller.dart';
import 'state/sheet_music_library_controller.dart';

class MijnApp extends StatelessWidget {
  const MijnApp({
    super.key,
    required this.library,
    required this.player,
    required this.linkOpener,
  });

  static const title = 'Music Maker';

  final SheetMusicLibraryController library;
  final PiecePlayerController player;
  final LinkOpener linkOpener;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: HomePage(
        title: title,
        library: library,
        player: player,
        linkOpener: linkOpener,
      ),
    );
  }
}
