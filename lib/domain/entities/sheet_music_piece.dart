class SheetMusicPiece {
  const SheetMusicPiece({
    required this.title,
    required this.composer,
    required this.sheetMusicUri,
  });

  final String title;
  final String composer;
  final Uri sheetMusicUri;
}
