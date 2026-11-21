import 'dart:typed_data';

import '../../domain/entities/note.dart';
import '../../domain/entities/score.dart';
import '../../domain/repositories/score_parser.dart';
import '../pdf/pdf_content_interpreter.dart';
import '../pdf/pdf_document.dart';
import 'engraving.dart';
import 'engraving_reader.dart';
import 'measure_timeline.dart';
import 'pitch_speller.dart';
import 'rhythmic_event.dart';
import 'rhythmic_event_builder.dart';
import 'stave_system.dart';
import 'stave_system_finder.dart';
import 'tempo_reader.dart';
import 'tie_finder.dart';

class PdfSheetMusicParser implements ScoreParser {
  const PdfSheetMusicParser({
    this._engravingReader = const EngravingReader(),
    this._systemFinder = const StaveSystemFinder(),
    this._eventBuilder = const RhythmicEventBuilder(),
    this._timeline = const MeasureTimeline(),
    this._tempoReader = const TempoReader(),
    this._tieFinder = const TieFinder(),
  });

  final EngravingReader _engravingReader;
  final StaveSystemFinder _systemFinder;
  final RhythmicEventBuilder _eventBuilder;
  final MeasureTimeline _timeline;
  final TempoReader _tempoReader;
  final TieFinder _tieFinder;

  @override
  Score parse(Uint8List sheetMusic) {
    final document = PdfDocument.parse(sheetMusic);
    final interpreter = PdfContentInterpreter(document);
    final pages = [
      for (final page in document.pages)
        _engravingReader.read(interpreter.interpretPage(page)),
    ];
    _ensureVectorSheetMusic(pages);
    final secondsPerBeat =
        60 /
        _tempoReader.quarterNotesPerMinute(
          pages.expand((page) => page.textLines),
        );
    final speller = PitchSpeller();
    final notes = <Note>[];
    var systemStartBeat = 0.0;
    for (final page in pages) {
      for (final system in _systemFinder.find(page)) {
        final pitches = _spellSystem(system, speller);
        final events = _eventBuilder.build(
          system,
          bars: page.bars,
          beams: page.beams,
        );
        final notesPerHead = <MusicSymbol, Note>{};
        systemStartBeat = _addNotesOfSystem(
          system,
          events,
          pitches,
          startBeat: systemStartBeat,
          secondsPerBeat: secondsPerBeat,
          notesPerHead: notesPerHead,
        );
        notes.addAll(_joinTiedNotes(system, page.curves, notesPerHead));
      }
    }
    if (notes.isEmpty) {
      throw const SheetMusicNotRecognizedException.noNamedMusicSymbols();
    }
    return Score(_withoutDuplicateNotes(notes));
  }

  void _ensureVectorSheetMusic(List<EngravedPage> pages) {
    if (pages.every((page) => page.staves.isEmpty)) {
      throw const SheetMusicNotRecognizedException.noVectorSheetMusic();
    }
    if (pages.every((page) => page.symbols.isEmpty)) {
      throw const SheetMusicNotRecognizedException.noNamedMusicSymbols();
    }
  }

  Map<MusicSymbol, int> _spellSystem(
    StaveSystem system,
    PitchSpeller speller,
  ) => {
    for (final (index, staff) in system.staves.indexed)
      ...speller.spell(
        staff: staff,
        staffIndex: index,
        symbols: system.symbolsPerStaff[staff]!,
        barlineXs: system.barlineXs,
      ),
  };

  double _addNotesOfSystem(
    StaveSystem system,
    List<RhythmicEvent> events,
    Map<MusicSymbol, int> pitches, {
    required double startBeat,
    required double secondsPerBeat,
    required Map<MusicSymbol, Note> notesPerHead,
  }) {
    final boundaries = system.measureBoundaries;
    var measureStartBeat = startBeat;
    for (var index = 0; index + 1 < boundaries.length; index++) {
      final eventsInMeasure = events
          .where(
            (event) =>
                event.x >= boundaries[index] && event.x < boundaries[index + 1],
          )
          .toList();
      if (eventsInMeasure.isEmpty) continue;
      final measure = _timeline.place(
        eventsInMeasure,
        lineSpacing: system.lineSpacing,
      );
      for (final timed in measure.events) {
        for (final head in timed.event.heads) {
          final pitch = pitches[head];
          if (pitch == null) continue;
          notesPerHead[head] = (Note(
            pitch: pitch,
            start: _beatsToDuration(
              measureStartBeat + timed.startBeat,
              secondsPerBeat,
            ),
            length: _beatsToDuration(timed.event.beats, secondsPerBeat),
          ));
        }
      }
      measureStartBeat += measure.lengthInBeats;
    }
    return measureStartBeat;
  }

  Iterable<Note> _joinTiedNotes(
    StaveSystem system,
    List<Curve> curves,
    Map<MusicSymbol, Note> notesPerHead,
  ) {
    final ties = [
      for (final staff in system.staves)
        ..._tieFinder.find(
          curves: curves,
          staff: staff,
          symbols: system.symbolsPerStaff[staff]!,
        ),
    ]..sort((first, second) => first.from.left.compareTo(second.from.left));
    final startingHeadOf = <MusicSymbol, MusicSymbol>{};
    for (final tie in ties) {
      final startingHead = startingHeadOf[tie.from] ?? tie.from;
      final startingNote = notesPerHead[startingHead];
      final tiedNote = notesPerHead.remove(tie.to);
      if (startingNote == null || tiedNote == null) continue;
      notesPerHead[startingHead] = Note(
        pitch: startingNote.pitch,
        start: startingNote.start,
        length: tiedNote.end - startingNote.start,
      );
      startingHeadOf[tie.to] = startingHead;
    }
    return notesPerHead.values;
  }

  List<Note> _withoutDuplicateNotes(List<Note> notes) {
    final longestPerOnset = <(int, Duration), Note>{};
    for (final note in notes) {
      final key = (note.pitch, note.start);
      final existing = longestPerOnset[key];
      if (existing == null || note.length > existing.length) {
        longestPerOnset[key] = note;
      }
    }
    return longestPerOnset.values.toList();
  }

  static Duration _beatsToDuration(double beats, double secondsPerBeat) =>
      Duration(
        microseconds: (beats * secondsPerBeat * Duration.microsecondsPerSecond)
            .round(),
      );
}
