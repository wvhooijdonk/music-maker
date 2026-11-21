import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mijn_app/domain/repositories/score_parser.dart';
import 'package:mijn_app/domain/use_cases/add_sheet_music.dart';
import 'package:mijn_app/domain/use_cases/prepare_piece.dart';
import 'package:mijn_app/presentation/mijn_app.dart';
import 'package:mijn_app/presentation/pages/home_page.dart';
import 'package:mijn_app/presentation/state/piece_player_controller.dart';
import 'package:mijn_app/presentation/state/sheet_music_library_controller.dart';
import 'package:mijn_app/presentation/widgets/add_piece_form.dart';
import 'package:mijn_app/presentation/widgets/piece_list_tile.dart';
import 'package:mijn_app/presentation/widgets/player_panel.dart';

import '../../support/fakes.dart';

void main() {
  late FakeMusicPlayer musicPlayer;
  late FakeLinkOpener linkOpener;

  Future<void> pumpApp(
    WidgetTester tester, {
    FakeScoreParser? scoreParser,
  }) async {
    musicPlayer = FakeMusicPlayer();
    linkOpener = FakeLinkOpener();
    final preparePiece = PreparePiece(
      documentSource: FakeDocumentSource(),
      scoreParser: scoreParser ?? FakeScoreParser(),
    );
    await tester.pumpWidget(
      MijnApp(
        library: SheetMusicLibraryController(
          initialPieces: [pieceForTest],
          addSheetMusic: AddSheetMusic(preparePiece: preparePiece),
        ),
        player: PiecePlayerController(
          preparePiece: preparePiece,
          musicPlayer: musicPlayer,
        ),
        linkOpener: linkOpener,
      ),
    );
  }

  Future<void> openAddForm(WidgetTester tester) async {
    await tester.tap(find.text(HomePage.addLabel));
    await tester.pump();
  }

  Future<void> uploadLink(WidgetTester tester, String link) async {
    await tester.enterText(find.byType(TextField), link);
    await tester.tap(find.text(AddPieceForm.uploadLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('lists each piece with title and composer', (tester) async {
    await pumpApp(tester);

    expect(
      find.widgetWithText(PieceListTile, pieceForTest.title),
      findsOneWidget,
    );
    expect(find.text(pieceForTest.composer), findsOneWidget);
    expect(find.text(PlayerPanel.nothingSelectedText), findsOneWidget);
  });

  testWidgets('play starts the piece right away and shows its details', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip(PieceListTile.playTooltip));
    await tester.pumpAndSettle();

    expect(musicPlayer.isPlaying, isTrue);
    expect(find.text('Nagebootste instrumenten: Piano'), findsOneWidget);
    expect(find.text('Geschatte duur: 0:03'), findsOneWidget);
  });

  testWidgets('open shows the sheet music link in a new tab', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip(PieceListTile.openTooltip));
    await tester.pump();

    expect(linkOpener.openedLinks, [pieceForTest.sheetMusicUri]);
  });

  testWidgets('the player has its own start and stop buttons', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip(PieceListTile.playTooltip));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(musicPlayer.isPlaying, isFalse);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(musicPlayer.isPlaying, isTrue);
  });

  testWidgets('add shows a link field with an upload button', (tester) async {
    await pumpApp(tester);

    await openAddForm(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(AddPieceForm.uploadLabel), findsOneWidget);
  });

  testWidgets('a playable link is added to the list', (tester) async {
    await pumpApp(tester);
    await openAddForm(tester);

    await uploadLink(tester, 'https://example.org/sonata.pdf');

    expect(find.widgetWithText(PieceListTile, 'sonata'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('an unplayable link shows an error and is not added', (
    tester,
  ) async {
    await pumpApp(
      tester,
      scoreParser: FakeScoreParser(
        failure: const SheetMusicNotRecognizedException.noVectorSheetMusic(),
      ),
    );
    await openAddForm(tester);

    await uploadLink(tester, 'https://example.org/scan.pdf');

    expect(find.textContaining('geen vector-bladmuziek'), findsOneWidget);
    expect(find.byType(PieceListTile), findsOneWidget);
  });
}
