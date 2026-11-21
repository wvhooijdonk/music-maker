import 'package:material_ui/material_ui.dart';

import '../../domain/entities/sheet_music_piece.dart';
import '../../domain/use_cases/add_sheet_music.dart';
import '../formatting/failure_message.dart';

sealed class AddPieceState {
  const AddPieceState();
}

class AddFormHidden extends AddPieceState {
  const AddFormHidden();
}

class AddFormShown extends AddPieceState {
  const AddFormShown({this.failure});

  final String? failure;
}

class CheckingLink extends AddPieceState {
  const CheckingLink();
}

class SheetMusicLibraryController extends ChangeNotifier {
  SheetMusicLibraryController({
    required List<SheetMusicPiece> initialPieces,
    required this._addSheetMusic,
  }) : _pieces = [...initialPieces];

  final AddSheetMusic _addSheetMusic;
  final List<SheetMusicPiece> _pieces;
  AddPieceState _addState = const AddFormHidden();

  List<SheetMusicPiece> get pieces => List.unmodifiable(_pieces);

  AddPieceState get addState => _addState;

  void showAddForm() => _changeAddState(const AddFormShown());

  void hideAddForm() => _changeAddState(const AddFormHidden());

  Future<void> add(String link) async {
    if (_addState is CheckingLink) return;
    _changeAddState(const CheckingLink());
    try {
      final piece = await _addSheetMusic(link, existingPieces: _pieces);
      _pieces.add(piece);
      _changeAddState(const AddFormHidden());
    } catch (error) {
      _changeAddState(AddFormShown(failure: describeFailure(error)));
    }
  }

  void _changeAddState(AddPieceState state) {
    _addState = state;
    notifyListeners();
  }
}
