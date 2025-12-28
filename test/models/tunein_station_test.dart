import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/tunein_station.dart';

void main() {
  group('TuneInStation', () {
    test('should parse from XML with all fields', () {
      const xmlString = '''<outline type="audio" text="Radio Potsdam"
        URL="http://opml.radiotime.com/Tune.ashx?id=s288368"
        bitrate="192" reliability="100" guide_id="s288368"
        subtext="WILLKOMMEN ZUHAUSE" genre_id="g3" formats="mp3"
        item="station" image="http://cdn-profiles.tunein.com/s288368/images/logoq.png?t=155066"
        now_playing_id="s288368" preset_id="s288368"/>''';

      final element = XmlDocument.parse(xmlString).rootElement;
      final station = TuneInStation.fromXml(element);

      expect(station.guideId, 's288368');
      expect(station.text, 'Radio Potsdam');
      expect(station.subtext, 'WILLKOMMEN ZUHAUSE');
      expect(station.image, 'http://cdn-profiles.tunein.com/s288368/images/logoq.png?t=155066');
      expect(station.bitrate, '192');
      expect(station.reliability, '100');
    });

    test('should parse from XML with minimal fields', () {
      const xmlString = '''<outline type="audio" text="Test Station"
        guide_id="s12345" item="station"/>''';

      final element = XmlDocument.parse(xmlString).rootElement;
      final station = TuneInStation.fromXml(element);

      expect(station.guideId, 's12345');
      expect(station.text, 'Test Station');
      expect(station.subtext, null);
      expect(station.image, null);
      expect(station.bitrate, null);
      expect(station.reliability, null);
    });

    test('should convert to JSON', () {
      const station = TuneInStation(
        guideId: 's288368',
        text: 'Radio Potsdam',
        subtext: 'WILLKOMMEN ZUHAUSE',
        image: 'http://example.com/logo.png',
        bitrate: '192',
        reliability: '100',
      );

      final json = station.toJson();

      expect(json['guideId'], 's288368');
      expect(json['text'], 'Radio Potsdam');
      expect(json['subtext'], 'WILLKOMMEN ZUHAUSE');
      expect(json['image'], 'http://example.com/logo.png');
      expect(json['bitrate'], '192');
      expect(json['reliability'], '100');
    });

    test('should create from JSON', () {
      final json = {
        'guideId': 's288368',
        'text': 'Radio Potsdam',
        'subtext': 'WILLKOMMEN ZUHAUSE',
        'image': 'http://example.com/logo.png',
        'bitrate': '192',
        'reliability': '100',
      };

      final station = TuneInStation.fromJson(json);

      expect(station.guideId, 's288368');
      expect(station.text, 'Radio Potsdam');
      expect(station.subtext, 'WILLKOMMEN ZUHAUSE');
      expect(station.image, 'http://example.com/logo.png');
      expect(station.bitrate, '192');
      expect(station.reliability, '100');
    });

    test('should handle equality correctly', () {
      const station1 = TuneInStation(
        guideId: 's288368',
        text: 'Radio Potsdam',
      );

      const station2 = TuneInStation(
        guideId: 's288368',
        text: 'Different Name',
      );

      const station3 = TuneInStation(
        guideId: 's999999',
        text: 'Radio Potsdam',
      );

      expect(station1, equals(station2));
      expect(station1, isNot(equals(station3)));
    });

    test('should have consistent hashCode', () {
      const station1 = TuneInStation(
        guideId: 's288368',
        text: 'Radio Potsdam',
      );

      const station2 = TuneInStation(
        guideId: 's288368',
        text: 'Different Name',
      );

      expect(station1.hashCode, equals(station2.hashCode));
    });
  });
}
