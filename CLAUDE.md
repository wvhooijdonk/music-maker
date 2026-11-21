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
