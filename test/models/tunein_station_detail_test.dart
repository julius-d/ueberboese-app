import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/tunein_station_detail.dart';

void main() {
  group('TuneInStationDetail', () {
    test('should parse from XML with all fields', () {
      const xmlString = '''<station>
        <guide_id>s288368</guide_id>
        <name>Radio Potsdam</name>
        <logo>https://cdn-profiles.tunein.com/s288368/images/logoq.png</logo>
        <slogan>WILLKOMMEN ZUHAUSE</slogan>
        <description>Das Radio für Potsdam, die Mittelmark, Teltow-Fläming und das Havelland.</description>
        <url>http://www.radio-potsdam.de</url>
        <location>Germany</location>
        <genre_name>Adult Hits</genre_name>
        <content_classification>music</content_classification>
        <is_family_content>false</is_family_content>
        <is_mature_content>false</is_mature_content>
      </station>''';

      final element = XmlDocument.parse(xmlString).rootElement;
      final detail = TuneInStationDetail.fromXml(element);

      expect(detail.guideId, 's288368');
      expect(detail.name, 'Radio Potsdam');
      expect(detail.logo, 'https://cdn-profiles.tunein.com/s288368/images/logoq.png');
      expect(detail.slogan, 'WILLKOMMEN ZUHAUSE');
      expect(detail.description, 'Das Radio für Potsdam, die Mittelmark, Teltow-Fläming und das Havelland.');
      expect(detail.url, 'http://www.radio-potsdam.de');
      expect(detail.location, 'Germany');
      expect(detail.genreName, 'Adult Hits');
      expect(detail.contentClassification, 'music');
      expect(detail.isFamilyContent, false);
      expect(detail.isMatureContent, false);
    });

    test('should parse from XML with minimal fields', () {
      const xmlString = '''<station>
        <guide_id>s12345</guide_id>
        <name>Test Station</name>
      </station>''';

      final element = XmlDocument.parse(xmlString).rootElement;
      final detail = TuneInStationDetail.fromXml(element);

      expect(detail.guideId, 's12345');
      expect(detail.name, 'Test Station');
      expect(detail.logo, null);
      expect(detail.slogan, null);
      expect(detail.description, null);
      expect(detail.url, null);
      expect(detail.location, null);
      expect(detail.genreName, null);
      expect(detail.contentClassification, null);
      expect(detail.isFamilyContent, null);
      expect(detail.isMatureContent, null);
    });

    test('should parse boolean fields correctly', () {
      const xmlString = '''<station>
        <guide_id>s12345</guide_id>
        <name>Test Station</name>
        <is_family_content>true</is_family_content>
        <is_mature_content>false</is_mature_content>
      </station>''';

      final element = XmlDocument.parse(xmlString).rootElement;
      final detail = TuneInStationDetail.fromXml(element);

      expect(detail.isFamilyContent, true);
      expect(detail.isMatureContent, false);
    });

    test('should convert to JSON', () {
      const detail = TuneInStationDetail(
        guideId: 's288368',
        name: 'Radio Potsdam',
        logo: 'https://example.com/logo.png',
        slogan: 'WILLKOMMEN ZUHAUSE',
        description: 'Test description',
        url: 'http://www.radio-potsdam.de',
        location: 'Germany',
        genreName: 'Adult Hits',
        contentClassification: 'music',
        isFamilyContent: false,
        isMatureContent: false,
      );

      final json = detail.toJson();

      expect(json['guideId'], 's288368');
      expect(json['name'], 'Radio Potsdam');
      expect(json['logo'], 'https://example.com/logo.png');
      expect(json['slogan'], 'WILLKOMMEN ZUHAUSE');
      expect(json['description'], 'Test description');
      expect(json['url'], 'http://www.radio-potsdam.de');
      expect(json['location'], 'Germany');
      expect(json['genreName'], 'Adult Hits');
      expect(json['contentClassification'], 'music');
      expect(json['isFamilyContent'], false);
      expect(json['isMatureContent'], false);
    });

    test('should create from JSON', () {
      final json = {
        'guideId': 's288368',
        'name': 'Radio Potsdam',
        'logo': 'https://example.com/logo.png',
        'slogan': 'WILLKOMMEN ZUHAUSE',
        'description': 'Test description',
        'url': 'http://www.radio-potsdam.de',
        'location': 'Germany',
        'genreName': 'Adult Hits',
        'contentClassification': 'music',
        'isFamilyContent': false,
        'isMatureContent': false,
      };

      final detail = TuneInStationDetail.fromJson(json);

      expect(detail.guideId, 's288368');
      expect(detail.name, 'Radio Potsdam');
      expect(detail.logo, 'https://example.com/logo.png');
      expect(detail.slogan, 'WILLKOMMEN ZUHAUSE');
      expect(detail.description, 'Test description');
      expect(detail.url, 'http://www.radio-potsdam.de');
      expect(detail.location, 'Germany');
      expect(detail.genreName, 'Adult Hits');
      expect(detail.contentClassification, 'music');
      expect(detail.isFamilyContent, false);
      expect(detail.isMatureContent, false);
    });

    test('should handle equality correctly', () {
      const detail1 = TuneInStationDetail(
        guideId: 's288368',
        name: 'Radio Potsdam',
      );

      const detail2 = TuneInStationDetail(
        guideId: 's288368',
        name: 'Different Name',
      );

      const detail3 = TuneInStationDetail(
        guideId: 's999999',
        name: 'Radio Potsdam',
      );

      expect(detail1, equals(detail2));
      expect(detail1, isNot(equals(detail3)));
    });

    test('should have consistent hashCode', () {
      const detail1 = TuneInStationDetail(
        guideId: 's288368',
        name: 'Radio Potsdam',
      );

      const detail2 = TuneInStationDetail(
        guideId: 's288368',
        name: 'Different Name',
      );

      expect(detail1.hashCode, equals(detail2.hashCode));
    });
  });
}
