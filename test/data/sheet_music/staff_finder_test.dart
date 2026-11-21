import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/data/sheet_music/engraving.dart';
import 'package:mijn_app/data/sheet_music/staff_finder.dart';

void main() {
  HorizontalSegment line(double y, {double left = 30, double right = 560}) =>
      HorizontalSegment(left: left, right: right, y: y, thickness: 0.5);

  test('five evenly spaced long lines form a staff', () {
    final staves = const StaffFinder().find([
      for (var index = 0; index < 5; index++) line(700 + index * 5.0),
    ]);

    expect(staves.single.bottomLineY, 700);
    expect(staves.single.lineSpacing, 5);
  });

  test('staves are ordered from the top of the page down', () {
    final staves = const StaffFinder().find([
      for (var index = 0; index < 5; index++) line(400 + index * 5.0),
      for (var index = 0; index < 5; index++) line(700 + index * 5.0),
    ]);

    expect(staves.map((staff) => staff.bottomLineY), [700, 400]);
  });

  test('short ledger lines do not form a staff', () {
    final staves = const StaffFinder().find([
      for (var index = 0; index < 5; index++)
        line(700 + index * 5.0, left: 100, right: 109),
    ]);

    expect(staves, isEmpty);
  });
}
