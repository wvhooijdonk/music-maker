import '../../domain/repositories/document_source.dart';
import '../../domain/repositories/score_parser.dart';
import '../../domain/use_cases/add_sheet_music.dart';

String describeFailure(Object error) => switch (error) {
  InvalidSheetMusicLinkException(:final reason) => reason,
  SheetMusicNotRecognizedException(:final reason) => reason,
  DocumentFetchException() =>
    'De PDF kon niet worden gedownload. Controleer de link; sommige websites '
        'staan downloaden vanuit de browser niet toe.',
  FormatException() => 'De link verwijst niet naar een leesbare PDF.',
  UnsupportedError(:final message) =>
    message ?? 'Niet ondersteund op dit platform.',
  _ => 'Er ging iets mis: $error',
};
