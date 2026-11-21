import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/score.dart';
import '../../domain/repositories/music_player.dart';
import 'note_scheduler.dart';
import 'voice.dart';

MusicPlayer createMusicPlayer() => WebAudioMusicPlayer();

class WebAudioMusicPlayer implements MusicPlayer {
  static const _startDelaySeconds = 0.1;
  static const _scheduleInterval = Duration(milliseconds: 100);
  static const _lookAhead = Duration(milliseconds: 500);
  static const _noteGain = 0.1;
  static const _silentGain = 0.0001;

  AudioContext? _context;
  GainNode? _output;
  Timer? _scheduleTimer;
  StreamController<Duration>? _progress;
  final _soundingOscillators = <OscillatorNode>{};

  @override
  void prepareOutput() {
    (_context ??= AudioContext()).resume();
  }

  @override
  Stream<Duration> play(Score score) {
    stop();
    final context = _context ??= AudioContext();
    context.resume();
    final output = context.createGain()..connect(context.destination);
    final startTime = context.currentTime + _startDelaySeconds;
    final scheduler = NoteScheduler(score.notes);
    final progress = StreamController<Duration>();
    _output = output;
    _progress = progress;

    void scheduleUpcomingNotes() {
      final elapsed = _secondsToDuration(context.currentTime - startTime);
      for (final note in scheduler.takeNotesStartingBefore(
        elapsed + _lookAhead,
      )) {
        _scheduleNote(note, context, output, startTime);
      }
      progress.add(elapsed < Duration.zero ? Duration.zero : elapsed);
      if (elapsed >= score.duration) {
        progress.add(score.duration);
        _finish();
      }
    }

    scheduleUpcomingNotes();
    _scheduleTimer = Timer.periodic(
      _scheduleInterval,
      (_) => scheduleUpcomingNotes(),
    );
    return progress.stream;
  }

  @override
  void stop() {
    for (final oscillator in _soundingOscillators) {
      oscillator.stop();
    }
    _soundingOscillators.clear();
    _output?.disconnect();
    _output = null;
    _finish();
  }

  void _finish() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _progress?.close();
    _progress = null;
  }

  void _scheduleNote(
    Note note,
    AudioContext context,
    AudioNode output,
    double startTime,
  ) {
    const voice = Voice.piano;
    final noteStart = startTime + _durationToSeconds(note.start);
    final noteEnd = noteStart + _durationToSeconds(note.length);
    const peakGain = _noteGain;

    final envelope = context.createGain()..connect(output);
    envelope.gain
      ..setValueAtTime(_silentGain, noteStart)
      ..linearRampToValueAtTime(
        peakGain,
        noteStart + _durationToSeconds(voice.attack),
      );
    final decayTimeConstant = voice.decayTimeConstant;
    if (decayTimeConstant != null) {
      envelope.gain.setTargetAtTime(
        _silentGain + peakGain * voice.sustainLevel,
        noteStart + _durationToSeconds(voice.attack),
        _durationToSeconds(decayTimeConstant),
      );
    }
    final releaseSeconds = _durationToSeconds(voice.release);
    envelope.gain
      ..cancelAndHoldAtTime(noteEnd)
      ..setTargetAtTime(_silentGain, noteEnd, releaseSeconds / 3);

    final oscillator = context.createOscillator()
      ..type = voice.waveform.name
      ..connect(envelope);
    oscillator.frequency.value = frequencyOfPitch(note.pitch);
    oscillator.onended = (Event _) {
      _soundingOscillators.remove(oscillator);
      envelope.disconnect();
    }.toJS;
    _soundingOscillators.add(oscillator);
    oscillator
      ..start(noteStart)
      ..stop(noteEnd + releaseSeconds);
  }

  static double _durationToSeconds(Duration duration) =>
      duration.inMicroseconds / Duration.microsecondsPerSecond;

  static Duration _secondsToDuration(double seconds) => Duration(
    microseconds: (seconds * Duration.microsecondsPerSecond).round(),
  );
}
