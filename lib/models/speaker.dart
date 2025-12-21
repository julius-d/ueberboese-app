class Speaker {
  final String id;
  final String name;
  final String emoji;
  final String ipAddress;

  const Speaker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.ipAddress,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Speaker &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
