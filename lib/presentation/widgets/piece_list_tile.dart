import 'package:material_ui/material_ui.dart';

import '../../domain/entities/sheet_music_piece.dart';

class PieceListTile extends StatelessWidget {
  const PieceListTile({
    super.key,
    required this.piece,
    required this.onPlay,
    required this.onOpen,
  });

  static const playTooltip = 'Afspelen';
  static const openTooltip = 'Bladmuziek openen';

  final SheetMusicPiece piece;
  final VoidCallback onPlay;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(piece.title),
      subtitle: Text(piece.composer),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: playTooltip,
            icon: const Icon(Icons.play_arrow),
            onPressed: onPlay,
          ),
          IconButton(
            tooltip: openTooltip,
            icon: const Icon(Icons.open_in_new),
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}
