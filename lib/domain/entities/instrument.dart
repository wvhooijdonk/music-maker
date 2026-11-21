class Instrument {
  const Instrument(this.name);

  static const piano = Instrument('Piano');

  final String name;

  @override
  bool operator ==(Object other) => other is Instrument && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}
