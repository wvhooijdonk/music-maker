import 'package:material_ui/material_ui.dart';

import '../../domain/repositories/link_opener.dart';
import '../state/piece_player_controller.dart';
import '../state/sheet_music_library_controller.dart';
import '../widgets/add_piece_form.dart';
import '../widgets/piece_list_tile.dart';
import '../widgets/player_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.title,
    required this.library,
    required this.player,
    required this.linkOpener,
  });

  static const addLabel = 'Toevoegen';

  final String title;
  final SheetMusicLibraryController library;
  final PiecePlayerController player;
  final LinkOpener linkOpener;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListenableBuilder(listenable: library, builder: _buildLibrary),
          const Divider(height: 32),
          ListenableBuilder(
            listenable: player,
            builder: (context, _) => PlayerPanel(
              state: player.state,
              onStart: player.start,
              onStop: player.stop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrary(BuildContext context, Widget? _) {
    final addState = library.addState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Muziekstukken',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: addState is AddFormHidden ? library.showAddForm : null,
              icon: const Icon(Icons.add),
              label: const Text(addLabel),
            ),
          ],
        ),
        if (addState is! AddFormHidden) ...[
          const SizedBox(height: 12),
          AddPieceForm(
            isChecking: addState is CheckingLink,
            failure: switch (addState) {
              AddFormShown(:final failure) => failure,
              _ => null,
            },
            onUpload: library.add,
            onCancel: library.hideAddForm,
          ),
        ],
        const SizedBox(height: 8),
        for (final piece in library.pieces)
          PieceListTile(
            piece: piece,
            onPlay: () => player.playNow(piece),
            onOpen: () => linkOpener.open(piece.sheetMusicUri),
          ),
      ],
    );
  }
}
