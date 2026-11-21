import '../entities/score.dart';

abstract interface class MusicPlayer {
  Stream<Duration> play(Score score);

  void stop();
}
