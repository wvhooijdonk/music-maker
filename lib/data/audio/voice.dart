import 'dart:math';

enum Waveform { sine, square, sawtooth, triangle }

class Voice {
  const Voice({
    required this.waveform,
    required this.attack,
    required this.release,
    this.decayTimeConstant,
    this.sustainLevel = 1,
  });

  static const piano = Voice(
    waveform: Waveform.triangle,
    attack: Duration(milliseconds: 5),
    decayTimeConstant: Duration(milliseconds: 700),
    sustainLevel: 0,
    release: Duration(milliseconds: 60),
  );

  final Waveform waveform;
  final Duration attack;
  final Duration release;
  final Duration? decayTimeConstant;
  final double sustainLevel;
}

double frequencyOfPitch(int pitch) {
  const concertPitchA = 69;
  const concertPitchFrequency = 440.0;
  return concertPitchFrequency * pow(2, (pitch - concertPitchA) / 12);
}
