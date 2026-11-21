import 'dart:typed_data';

class ReferenceNote {
  const ReferenceNote({
    required this.pitch,
    required this.startBeat,
    required this.lengthInBeats,
  });

  final int pitch;
  final double startBeat;
  final double lengthInBeats;
}

List<ReferenceNote> readReferenceNotes(Uint8List midi) {
  final data = ByteData.sublistView(midi);
  final ticksPerQuarterNote = data.getUint16(12);
  final trackCount = data.getUint16(10);
  final notes = <ReferenceNote>[];
  var position = 14;
  for (var track = 0; track < trackCount; track++) {
    final trackEnd = position + 8 + data.getUint32(position + 4);
    position += 8;
    var tick = 0;
    var status = 0;
    final startTicksPerPitch = <int, List<int>>{};

    int readVariableLength() {
      var value = 0;
      while (true) {
        final byte = midi[position++];
        value = (value << 7) | (byte & 0x7f);
        if (byte < 0x80) return value;
      }
    }

    while (position < trackEnd) {
      tick += readVariableLength();
      final first = midi[position];
      if (first == 0xff) {
        position += 2;
        final metaLength = readVariableLength();
        position += metaLength;
        continue;
      }
      if (first == 0xf0 || first == 0xf7) {
        position++;
        final systemExclusiveLength = readVariableLength();
        position += systemExclusiveLength;
        continue;
      }
      if (first & 0x80 != 0) {
        status = first;
        position++;
      }
      final kind = status & 0xf0;
      if (kind == 0xc0 || kind == 0xd0) {
        position++;
        continue;
      }
      final pitch = midi[position];
      final velocity = midi[position + 1];
      position += 2;
      if (kind == 0x90 && velocity > 0) {
        startTicksPerPitch.putIfAbsent(pitch, () => []).add(tick);
      } else if (kind == 0x80 || kind == 0x90) {
        final starts = startTicksPerPitch[pitch];
        if (starts == null || starts.isEmpty) continue;
        final startTick = starts.removeAt(0);
        notes.add(
          ReferenceNote(
            pitch: pitch,
            startBeat: startTick / ticksPerQuarterNote,
            lengthInBeats: (tick - startTick) / ticksPerQuarterNote,
          ),
        );
      }
    }
    position = trackEnd;
  }
  return notes;
}
