import 'package:xml/xml.dart';

class Recent {
  final String deviceId;
  final int utcTime;
  final String id;
  final String itemName;
  final String? containerArt;
  final String source;
  final String location;
  final String type;
  final bool isPresetable;
  final String? sourceAccount;

  const Recent({
    required this.deviceId,
    required this.utcTime,
    required this.id,
    required this.itemName,
    this.containerArt,
    required this.source,
    required this.location,
    required this.type,
    required this.isPresetable,
    this.sourceAccount,
  });

  factory Recent.fromXml(XmlElement recentElement) {
    // Get recent attributes
    final deviceId = recentElement.getAttribute('deviceID') ?? '';
    final utcTimeStr = recentElement.getAttribute('utcTime') ?? '0';
    final utcTime = int.tryParse(utcTimeStr) ?? 0;
    final id = recentElement.getAttribute('id') ?? '';

    // Find ContentItem element
    final contentItemElements = recentElement.findElements('contentItem');
    if (contentItemElements.isEmpty) {
      throw Exception('contentItem not found in recent');
    }

    final contentItem = contentItemElements.first;

    // Extract ContentItem attributes
    final source = contentItem.getAttribute('source') ?? '';
    final type = contentItem.getAttribute('type') ?? '';
    final location = contentItem.getAttribute('location') ?? '';
    final sourceAccount = contentItem.getAttribute('sourceAccount');
    final isPresetableStr = contentItem.getAttribute('isPresetable');
    final isPresetable = isPresetableStr?.toLowerCase() == 'true';

    // Extract ContentItem child elements
    final itemNameElements = contentItem.findElements('itemName');
    final itemName = itemNameElements.isNotEmpty
        ? itemNameElements.first.innerText
        : '';

    final containerArtElements = contentItem.findElements('containerArt');
    final containerArt = containerArtElements.isNotEmpty
        ? containerArtElements.first.innerText
        : null;

    return Recent(
      deviceId: deviceId,
      utcTime: utcTime,
      id: id,
      itemName: itemName,
      containerArt: containerArt,
      source: source,
      location: location,
      type: type,
      isPresetable: isPresetable,
      sourceAccount: sourceAccount,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'utcTime': utcTime,
    'id': id,
    'itemName': itemName,
    'containerArt': containerArt,
    'source': source,
    'location': location,
    'type': type,
    'isPresetable': isPresetable,
    'sourceAccount': sourceAccount,
  };

  factory Recent.fromJson(Map<String, dynamic> json) => Recent(
    deviceId: json['deviceId'] as String,
    utcTime: json['utcTime'] as int,
    id: json['id'] as String,
    itemName: json['itemName'] as String,
    containerArt: json['containerArt'] as String?,
    source: json['source'] as String,
    location: json['location'] as String,
    type: json['type'] as String,
    isPresetable: json['isPresetable'] as bool,
    sourceAccount: json['sourceAccount'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recent &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          id == other.id;

  @override
  int get hashCode => Object.hash(deviceId, id);
}
