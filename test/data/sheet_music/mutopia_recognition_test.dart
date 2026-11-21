import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/pdf_sheet_music_parser.dart';
import 'package:mijn_app/domain/entities/note.dart';

import '../../support/reference_midi_reader.dart';

class _Piece {
  const _Piece(
    this.name, {
    required this.quarterNotesPerMinute,
    this.unplayedGraceNotes = 0,
  });

  final String name;
  final double quarterNotesPerMinute;
  final int unplayedGraceNotes;
}

void main() {
  const pieces = [
    _Piece('ode', quarterNotesPerMinute: 100),
    _Piece('wtk1-prelude1', quarterNotesPerMinute: 90),
    _Piece(
      'anna-magdalena-04',
      quarterNotesPerMinute: 90,
      unplayedGraceNotes: 1,
    ),
  ];

  for (final piece in pieces) {
    group(
      '${piece.name} recognised from the PDF matches the MIDI of the same source',
      () {
        late List<Note> recognised;
        late List<ReferenceNote> reference;

        double beatsOf(Duration duration) =>
            duration.inMicroseconds / 1e6 * piece.quarterNotesPerMinute / 60;

        String onsetKey(int pitch, double beat) =>
            '$pitch@${beat.toStringAsFixed(2)}';

        setUpAll(() {
          final fixtures = 'test/fixtures/mutopia/${piece.name}';
          recognised = const PdfSheetMusicParser()
              .parse(File('$fixtures-a4.pdf').readAsBytesSync())
              .notes;
          reference = readReferenceNotes(
            File('$fixtures.mid').readAsBytesSync(),
          );
        });

        test('every recognised note has the right pitch and onset', () {
          final referenceOnsets = {
            for (final note in reference) onsetKey(note.pitch, note.startBeat),
          };
          final unmatched = recognised
              .map((note) => onsetKey(note.pitch, beatsOf(note.start)))
              .where((key) => !referenceOnsets.contains(key))
              .toList();

          expect(unmatched, isEmpty);
        });

        test('no notes are missing apart from unplayed grace notes', () {
          expect(
            recognised.length,
            reference.length - piece.unplayedGraceNotes,
          );
        });

        test('recognised notes have the reference length', () {
          final referenceLengths = {
            for (final note in reference)
              onsetKey(note.pitch, note.startBeat): note.lengthInBeats,
          };
          final wrongLengths = recognised.where((note) {
            final expected =
                referenceLengths[onsetKey(note.pitch, beatsOf(note.start))];
            return expected != null &&
                (beatsOf(note.length) - expected).abs() > 0.02;
          });

          expect(
            wrongLengths.length,
            lessThanOrEqualTo(piece.unplayedGraceNotes),
          );
        });
      },
    );
  }
}
