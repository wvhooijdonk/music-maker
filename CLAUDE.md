# CLAUDE.md

## Project

- Flutter-app `mijn_app` (Music Maker): speelt muziek af op basis van bladmuziek.
- Eerst als webapp, later ook native Linux en Windows. Platforms: web, linux, windows.
- Ontwikkeling gebeurt vanaf een iPad. De app draait in GitHub Codespaces met de dev container in `.devcontainer/` (Flutter stable, poort 8080).
- De app wordt bekeken in Safari op de iPad via:
  `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`
- Breakpoints in de UI zijn op de iPad niet mogelijk. Logica moet daarom zo veel mogelijk testbaar zijn met unit tests.

## Structuur (clean architecture)

- `lib/domain`: entities, repository-interfaces en use cases. Geen Flutter-imports.
- `lib/data`: implementaties van de repository-interfaces.
- `lib/presentation`: widgets en state.
- `test/` volgt dezelfde indeling als `lib/`.
- Afhankelijkheden wijzen alleen naar binnen, richting het domein.

## Architectuur van de muziekspeler

- `domain`: `SheetMusicPiece`, `Score`, `Note`, `Instrument`; interfaces `SheetMusicCatalog`, `DocumentSource`, `ScoreParser`, `MusicPlayer`, `LinkOpener`; use cases `PreparePiece` (downloaden en herkennen) en `AddSheetMusic` (link controleren en alleen afspeelbare PDF's toevoegen).
- `data/pdf`: eigen PDF-lezer (objecten, FlateDecode, content streams) die glyphs met glyphnamen en paden in paginacoördinaten oplevert.
- `data/sheet_music`: herkenning van bladmuziek uit vector-PDF's (notenbalken, maatstrepen, stokken, waardestrepen, bogen, sleutels, voortekening, punten, ties) naar een `Score`. Werkt voor digitaal gezette PDF's met benoemde muziekglyphs (zoals LilyPond/Mutopia); scans geven `SheetMusicNotRecognizedException`.
- `data/audio`: Web Audio-synthese (`WebAudioMusicPlayer`) achter `MusicPlayer`; op Linux/Windows nog `UnsupportedMusicPlayer`.
- `presentation`: `SheetMusicLibraryController` (lijst en toevoegen), `PiecePlayerController` (ChangeNotifier met `PiecePlayerState`) en widgets.
- `MusicPlayer.prepareOutput()` wordt direct in de tik op Play aangeroepen, zodat Safari het geluid toestaat terwijl de PDF nog downloadt.
- `main.dart` is de composition root.

## Bladmuziek en proxy

- Mutopia stuurt geen CORS-headers. In de browser gaan downloads daarom via de dev-server-proxy in `web_dev_config.yaml` (`/mutopia/` naar `https://www.mutopiaproject.org/ftp/`), gekoppeld via `ProxyRoute` in `main.dart`. Stukken houden hun echte URL (voor Open). Native platforms downloaden rechtstreeks.
- Toegevoegde links van andere websites werken in de browser alleen als die website CORS toestaat, of na het toevoegen van een eigen proxyregel.
- Een productie-webbuild heeft een eigen proxy nodig.
- `test/data/sheet_music/mutopia_recognition_test.dart` controleert de PDF-herkenning tegen de MIDI uit dezelfde Mutopia-bron (fixtures in `test/fixtures/mutopia`). De MIDI wordt alleen in tests gebruikt.

## Werkafspraken

- Pas SOLID en clean architecture toe bij nieuwe features.
- Clean code: namen leggen de code uit, geen commentaar om code te verklaren.
- Fixes klein en to the point. Reproduceer een bug eerst met een test die precies op dat punt faalt.
- Gebruik nooit em dashes, altijd een gewoon streepje.
- Antwoord in het Nederlands.

## Commando's

- Afhankelijkheden: `flutter pub get`
- Analyse: `flutter analyze`
- Tests: `flutter test`
- Formatteren: `dart format lib test`
