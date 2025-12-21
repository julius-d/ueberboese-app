class SpeakerInfo {
  final String name;
  final String type;
  final String? margeUrl;
  final String? accountId;

  const SpeakerInfo({
    required this.name,
    required this.type,
    this.margeUrl,
    this.accountId,
  });
}
