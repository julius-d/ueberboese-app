class Speaker {
  final String id;
  final String name;
  final String emoji;
  final String ipAddress;
  final String type;

  const Speaker({
    required this.id,
    required this.name,
    required this.emoji,
    required this.ipAddress,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'ipAddress': ipAddress,
        'type': type,
      };

  factory Speaker.fromJson(Map<String, dynamic> json) => Speaker(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        ipAddress: json['ipAddress'] as String,
        type: json['type'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Speaker &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
