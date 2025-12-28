import 'package:xml/xml.dart';

class TuneInStationDetail {
  final String guideId;
  final String name;
  final String? logo;
  final String? slogan;
  final String? description;
  final String? url;
  final String? location;
  final String? genreName;
  final String? contentClassification;
  final bool? isFamilyContent;
  final bool? isMatureContent;

  const TuneInStationDetail({
    required this.guideId,
    required this.name,
    this.logo,
    this.slogan,
    this.description,
    this.url,
    this.location,
    this.genreName,
    this.contentClassification,
    this.isFamilyContent,
    this.isMatureContent,
  });

  factory TuneInStationDetail.fromXml(XmlElement stationElement) {
    final guideIdElements = stationElement.findElements('guide_id');
    final guideId = guideIdElements.isNotEmpty ? guideIdElements.first.innerText : '';

    final nameElements = stationElement.findElements('name');
    final name = nameElements.isNotEmpty ? nameElements.first.innerText : '';

    final logoElements = stationElement.findElements('logo');
    final logo = logoElements.isNotEmpty ? logoElements.first.innerText : null;

    final sloganElements = stationElement.findElements('slogan');
    final slogan = sloganElements.isNotEmpty ? sloganElements.first.innerText : null;

    final descriptionElements = stationElement.findElements('description');
    final description = descriptionElements.isNotEmpty ? descriptionElements.first.innerText : null;

    final urlElements = stationElement.findElements('url');
    final url = urlElements.isNotEmpty ? urlElements.first.innerText : null;

    final locationElements = stationElement.findElements('location');
    final location = locationElements.isNotEmpty ? locationElements.first.innerText : null;

    final genreNameElements = stationElement.findElements('genre_name');
    final genreName = genreNameElements.isNotEmpty ? genreNameElements.first.innerText : null;

    final contentClassificationElements = stationElement.findElements('content_classification');
    final contentClassification = contentClassificationElements.isNotEmpty
        ? contentClassificationElements.first.innerText
        : null;

    final isFamilyContentElements = stationElement.findElements('is_family_content');
    final isFamilyContent = isFamilyContentElements.isNotEmpty
        ? isFamilyContentElements.first.innerText.toLowerCase() == 'true'
        : null;

    final isMatureContentElements = stationElement.findElements('is_mature_content');
    final isMatureContent = isMatureContentElements.isNotEmpty
        ? isMatureContentElements.first.innerText.toLowerCase() == 'true'
        : null;

    return TuneInStationDetail(
      guideId: guideId,
      name: name,
      logo: logo,
      slogan: slogan,
      description: description,
      url: url,
      location: location,
      genreName: genreName,
      contentClassification: contentClassification,
      isFamilyContent: isFamilyContent,
      isMatureContent: isMatureContent,
    );
  }

  Map<String, dynamic> toJson() => {
        'guideId': guideId,
        'name': name,
        'logo': logo,
        'slogan': slogan,
        'description': description,
        'url': url,
        'location': location,
        'genreName': genreName,
        'contentClassification': contentClassification,
        'isFamilyContent': isFamilyContent,
        'isMatureContent': isMatureContent,
      };

  factory TuneInStationDetail.fromJson(Map<String, dynamic> json) => TuneInStationDetail(
        guideId: json['guideId'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String?,
        slogan: json['slogan'] as String?,
        description: json['description'] as String?,
        url: json['url'] as String?,
        location: json['location'] as String?,
        genreName: json['genreName'] as String?,
        contentClassification: json['contentClassification'] as String?,
        isFamilyContent: json['isFamilyContent'] as bool?,
        isMatureContent: json['isMatureContent'] as bool?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TuneInStationDetail &&
          runtimeType == other.runtimeType &&
          guideId == other.guideId;

  @override
  int get hashCode => guideId.hashCode;
}
