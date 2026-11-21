import '../../domain/repositories/music_player.dart';
import 'unsupported_music_player.dart'
    if (dart.library.js_interop) 'web_audio_music_player.dart';

MusicPlayer createPlatformMusicPlayer() => createMusicPlayer();
