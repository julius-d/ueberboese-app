class SpotifyEntity {
  final String name;
  final String? imageUrl;

  const SpotifyEntity({
    required this.name,
    this.imageUrl,
  });

  factory SpotifyEntity.fromJson(Map<String, dynamic> json) {
    return SpotifyEntity(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'imageUrl': imageUrl,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotifyEntity &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => Object.hash(name, imageUrl);
}
