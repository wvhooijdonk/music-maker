import 'package:material_ui/material_ui.dart';

import '../../domain/entities/sheet_music_piece.dart';

class PieceButton extends StatelessWidget {
  const PieceButton({super.key, required this.piece, required this.onPressed});

  final SheetMusicPiece piece;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(piece.title, style: textTheme.titleMedium),
          Text(piece.composer, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
