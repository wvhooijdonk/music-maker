import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/domain/use_cases/prepare_piece.dart';
import 'package:mijn_app/presentation/mijn_app.dart';
import 'package:mijn_app/presentation/state/piece_player_controller.dart';
import 'package:mijn_app/presentation/widgets/player_panel.dart';

import '../../support/fakes.dart';

void main() {
  late FakeMusicPlayer musicPlayer;

  Future<void> pumpApp(WidgetTester tester) async {
    musicPlayer = FakeMusicPlayer();
    final controller = PiecePlayerController(
      preparePiece: PreparePiece(
        documentSource: FakeDocumentSource(),
        scoreParser: FakeScoreParser(),
      ),
      musicPlayer: musicPlayer,
    );
    await tester.pumpWidget(
      MijnApp(pieces: [pieceForTest], controller: controller),
    );
  }

  testWidgets('shows a button with title and composer for each piece', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text(pieceForTest.title), findsOneWidget);
    expect(find.text(pieceForTest.composer), findsOneWidget);
    expect(find.text(PlayerPanel.nothingSelectedText), findsOneWidget);
  });

  testWidgets('choosing a piece shows instruments and estimated duration', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text(pieceForTest.title));
    await tester.pumpAndSettle();

    expect(find.text('Nagebootste instrumenten: Piano'), findsOneWidget);
    expect(find.text('Geschatte duur: 0:03'), findsOneWidget);
    expect(find.text('0:00 / 0:03'), findsOneWidget);
  });

  testWidgets('the start button starts playback', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(pieceForTest.title));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(musicPlayer.isPlaying, isTrue);
  });
}
