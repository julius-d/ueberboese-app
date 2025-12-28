import 'package:xml/xml.dart';

class TuneInStation {
  final String guideId;
  final String text;
  final String? subtext;
  final String? image;
  final String? bitrate;
  final String? reliability;

  const TuneInStation({
    required this.guideId,
    required this.text,
    this.subtext,
    this.image,
    this.bitrate,
    this.reliability,
  });

  factory TuneInStation.fromXml(XmlElement outline) {
    final guideId = outline.getAttribute('guide_id') ?? '';
    final text = outline.getAttribute('text') ?? '';
    final subtext = outline.getAttribute('subtext');
    final image = outline.getAttribute('image');
    final bitrate = outline.getAttribute('bitrate');
    final reliability = outline.getAttribute('reliability');

    return TuneInStation(
      guideId: guideId,
      text: text,
      subtext: subtext,
      image: image,
      bitrate: bitrate,
      reliability: reliability,
    );
  }

  Map<String, dynamic> toJson() => {
        'guideId': guideId,
        'text': text,
        'subtext': subtext,
        'image': image,
        'bitrate': bitrate,
        'reliability': reliability,
      };

  factory TuneInStation.fromJson(Map<String, dynamic> json) => TuneInStation(
        guideId: json['guideId'] as String,
        text: json['text'] as String,
        subtext: json['subtext'] as String?,
        image: json['image'] as String?,
        bitrate: json['bitrate'] as String?,
        reliability: json['reliability'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TuneInStation &&
          runtimeType == other.runtimeType &&
          guideId == other.guideId;

  @override
  int get hashCode => guideId.hashCode;
}
