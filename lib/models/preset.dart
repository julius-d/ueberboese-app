import 'package:xml/xml.dart';

class Preset {
  final String id;
  final String itemName;
  final String? containerArt;
  final String source;
  final String location;
  final String type;
  final bool isPresetable;
  final int? createdOn;
  final int? updatedOn;

  const Preset({
    required this.id,
    required this.itemName,
    this.containerArt,
    required this.source,
    required this.location,
    required this.type,
    required this.isPresetable,
    this.createdOn,
    this.updatedOn,
  });

  factory Preset.fromXml(XmlElement presetElement) {
    // Get preset id from attribute
    final id = presetElement.getAttribute('id') ?? '';

    // Get optional timestamps
    final createdOnStr = presetElement.getAttribute('createdOn');
    final updatedOnStr = presetElement.getAttribute('updatedOn');

    final createdOn = createdOnStr != null ? int.tryParse(createdOnStr) : null;
    final updatedOn = updatedOnStr != null ? int.tryParse(updatedOnStr) : null;

    // Find ContentItem element
    final contentItemElements = presetElement.findElements('ContentItem');
    if (contentItemElements.isEmpty) {
      throw Exception('ContentItem not found in preset');
    }

    final contentItem = contentItemElements.first;

    // Extract ContentItem attributes
    final source = contentItem.getAttribute('source') ?? '';
    final type = contentItem.getAttribute('type') ?? '';
    final location = contentItem.getAttribute('location') ?? '';
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

    return Preset(
      id: id,
      itemName: itemName,
      containerArt: containerArt,
      source: source,
      location: location,
      type: type,
      isPresetable: isPresetable,
      createdOn: createdOn,
      updatedOn: updatedOn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'containerArt': containerArt,
        'source': source,
        'location': location,
        'type': type,
        'isPresetable': isPresetable,
        'createdOn': createdOn,
        'updatedOn': updatedOn,
      };

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
        id: json['id'] as String,
        itemName: json['itemName'] as String,
        containerArt: json['containerArt'] as String?,
        source: json['source'] as String,
        location: json['location'] as String,
        type: json['type'] as String,
        isPresetable: json['isPresetable'] as bool,
        createdOn: json['createdOn'] as int?,
        updatedOn: json['updatedOn'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Preset && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
