import 'package:flutter_test/flutter_test.dart';
import 'package:mijn_app/presentation/formatting/playback_time.dart';

void main() {
  test('shows minutes and two-digit seconds', () {
    expect(formatPlaybackTime(const Duration(seconds: 38)), '0:38');
    expect(formatPlaybackTime(const Duration(minutes: 2, seconds: 5)), '2:05');
  });
}
