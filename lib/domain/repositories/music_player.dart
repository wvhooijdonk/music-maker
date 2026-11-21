import '../entities/score.dart';

abstract interface class MusicPlayer {
  void prepareOutput();

  Stream<Duration> play(Score score);

  void stop();
}
