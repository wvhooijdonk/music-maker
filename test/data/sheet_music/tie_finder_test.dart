import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/engraving.dart';
import 'package:mijn_app/data/sheet_music/tie_finder.dart';

void main() {
  const staff = Staff(
    bottomLineY: 100,
    lineSpacing: 5,
    left: 0,
    right: 500,
    lineThickness: 0.5,
  );

  MusicSymbol head({required double left, required double y}) => MusicSymbol(
    name: 'noteheads.s2',
    left: left,
    y: y,
    width: 6.5,
    fontSize: 20,
  );

  Curve curveBetween(MusicSymbol from, MusicSymbol to, {required double y}) =>
      Curve(
        left: from.right + 1,
        right: to.left - 1,
        bottom: y - 1,
        top: y + 1,
      );

  test('a curve between two noteheads on the same pitch is a tie', () {
    final first = head(left: 100, y: 110);
    final second = head(left: 130, y: 110);

    final ties = const TieFinder().find(
      curves: [curveBetween(first, second, y: 106)],
      staff: staff,
      symbols: [first, second],
    );

    expect(ties.single.from, first);
    expect(ties.single.to, second);
  });

  test(
    'a curve between noteheads on different pitches is a slur, not a tie',
    () {
      final first = head(left: 100, y: 110);
      final second = head(left: 130, y: 112.5);

      final ties = const TieFinder().find(
        curves: [curveBetween(first, second, y: 106)],
        staff: staff,
        symbols: [first, second],
      );

      expect(ties, isEmpty);
    },
  );

  test('a tie may start after the augmentation dot of a dotted note', () {
    final dotted = head(left: 77.7, y: 110);
    final tiedTo = head(left: 105.5, y: 110);
    const tieStartingAfterDot = Curve(
      left: 90,
      right: 107.7,
      bottom: 115,
      top: 115,
    );

    final ties = const TieFinder().find(
      curves: [tieStartingAfterDot],
      staff: staff,
      symbols: [dotted, tiedTo],
    );

    expect(ties.single.from, dotted);
  });
}
