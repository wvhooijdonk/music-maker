import 'package:material_ui/material_ui.dart';

import '../../domain/entities/prepared_piece.dart';
import '../formatting/playback_time.dart';
import '../state/piece_player_state.dart';

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.state,
    required this.onStart,
    required this.onStop,
  });

  static const nothingSelectedText = 'Kies een muziekstuk.';
  static const preparingText = 'Bladmuziek downloaden en herkennen...';

  final PiecePlayerState state;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      NothingSelected() => const Text(nothingSelectedText),
      PreparingPiece(:final piece) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(piece.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(preparingText),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ),
      PreparationFailed(:final piece, :final message) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(piece.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
      ReadyToPlay(:final prepared) => _PreparedPieceView(
        prepared: prepared,
        elapsed: Duration.zero,
        progress: 0,
        onStart: onStart,
      ),
      Playing(:final prepared, :final elapsed, :final progress) =>
        _PreparedPieceView(
          prepared: prepared,
          elapsed: elapsed,
          progress: progress,
          onStop: onStop,
        ),
    };
  }
}

class _PreparedPieceView extends StatelessWidget {
  const _PreparedPieceView({
    required this.prepared,
    required this.elapsed,
    required this.progress,
    this.onStart,
    this.onStop,
  });

  final PreparedPiece prepared;
  final Duration elapsed;
  final double progress;
  final VoidCallback? onStart;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final score = prepared.score;
    final instrumentNames = score.instruments
        .map((instrument) => instrument.name)
        .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prepared.piece.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(prepared.piece.composer),
        const SizedBox(height: 12),
        Text('Nagebootste instrumenten: $instrumentNames'),
        Text('Geschatte duur: ${formatPlaybackTime(score.duration)}'),
        Text('Herkende noten: ${score.notes.length}'),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 4),
        Text(
          '${formatPlaybackTime(elapsed)} / ${formatPlaybackTime(score.duration)}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }
}
