import 'package:xml/xml.dart';

class SpeakerSource {
  final String source;
  final String? sourceAccount;
  final String? status;
  final String displayName;

  const SpeakerSource({
    required this.source,
    this.sourceAccount,
    this.status,
    required this.displayName,
  });

  factory SpeakerSource.fromXml(XmlElement element) {
    final source = element.getAttribute('source') ?? '';
    final sourceAccount = element.getAttribute('sourceAccount');
    final status = element.getAttribute('status');
    final innerText = element.innerText.trim();
    final displayName = innerText.isNotEmpty ? innerText : source;

    return SpeakerSource(
      source: source,
      sourceAccount: sourceAccount,
      status: status,
      displayName: displayName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeakerSource &&
        other.source == source &&
        other.sourceAccount == sourceAccount &&
        other.status == status &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(source, sourceAccount, status, displayName);
}
