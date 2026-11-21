import '../../domain/entities/score.dart';
import '../../domain/repositories/music_player.dart';

class UnsupportedMusicPlayer implements MusicPlayer {
  const UnsupportedMusicPlayer();

  @override
  Stream<Duration> play(Score score) => Stream.error(
    UnsupportedError('Afspelen wordt op dit platform nog niet ondersteund'),
  );

  @override
  void stop() {}
}

MusicPlayer createMusicPlayer() => const UnsupportedMusicPlayer();
