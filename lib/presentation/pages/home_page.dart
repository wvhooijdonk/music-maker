import 'package:material_ui/material_ui.dart';

import '../../domain/entities/sheet_music_piece.dart';
import '../state/piece_player_controller.dart';
import '../widgets/piece_button.dart';
import '../widgets/player_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.title,
    required this.pieces,
    required this.controller,
  });

  final String title;
  final List<SheetMusicPiece> pieces;
  final PiecePlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final piece in pieces)
                  PieceButton(
                    piece: piece,
                    onPressed: () => controller.select(piece),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => PlayerPanel(
                state: controller.state,
                onStart: controller.start,
                onStop: controller.stop,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
