class Speaker {
  final String id;
  final String name;
  final String emoji;
  final String ipAddress;
  final String? type;

  const Speaker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.ipAddress,
    this.type,
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
