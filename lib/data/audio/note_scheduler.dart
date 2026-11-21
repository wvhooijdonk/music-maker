import '../../domain/entities/note.dart';

class NoteScheduler {
  NoteScheduler(this._notesInStartOrder);

  final List<Note> _notesInStartOrder;
  int _nextNoteIndex = 0;

  List<Note> takeNotesStartingBefore(Duration moment) {
    final firstIndex = _nextNoteIndex;
    while (_nextNoteIndex < _notesInStartOrder.length &&
        _notesInStartOrder[_nextNoteIndex].start < moment) {
      _nextNoteIndex++;
    }
    return _notesInStartOrder.sublist(firstIndex, _nextNoteIndex);
  }
}
