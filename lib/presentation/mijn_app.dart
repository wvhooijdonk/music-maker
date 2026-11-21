import 'package:material_ui/material_ui.dart';

import '../domain/entities/sheet_music_piece.dart';
import 'pages/home_page.dart';
import 'state/piece_player_controller.dart';

class MijnApp extends StatelessWidget {
  const MijnApp({super.key, required this.pieces, required this.controller});

  static const title = 'Music Maker';

  final List<SheetMusicPiece> pieces;
  final PiecePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: HomePage(title: title, pieces: pieces, controller: controller),
    );
  }
}
