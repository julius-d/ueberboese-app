import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/preset.dart';

void main() {
  group('Preset', () {
    test('fromXml parses preset with all fields correctly', () {
      const xmlString = '''
      <preset id="3" createdOn="1701220500" updatedOn="1701220500">
        <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s309605" isPresetable="true">
          <itemName>My Copy K-Love 90s</itemName>
          <containerArt>http://cdn-profiles.tunein.com/s309605/images/logog.png?t=637986891960000000</containerArt>
        </ContentItem>
      </preset>
      ''';

      final document = XmlDocument.parse(xmlString);
      final presetElement = document.findAllElements('preset').first;

      final preset = Preset.fromXml(presetElement);

      expect(preset.id, '3');
      expect(preset.itemName, 'My Copy K-Love 90s');
      expect(
        preset.containerArt,
        'http://cdn-profiles.tunein.com/s309605/images/logog.png?t=637986891960000000',
      );
      expect(preset.source, 'TUNEIN');
      expect(preset.location, '/v1/playback/station/s309605');
      expect(preset.type, 'stationurl');
      expect(preset.isPresetable, true);
      expect(preset.createdOn, 1701220500);
      expect(preset.updatedOn, 1701220500);
    });

    test('fromXml parses preset without optional fields', () {
      const xmlString = '''
      <preset id="1">
        <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s33828" isPresetable="true">
          <itemName>K-LOVE Radio</itemName>
        </ContentItem>
      </preset>
      ''';

      final document = XmlDocument.parse(xmlString);
      final presetElement = document.findAllElements('preset').first;

      final preset = Preset.fromXml(presetElement);

      expect(preset.id, '1');
      expect(preset.itemName, 'K-LOVE Radio');
      expect(preset.containerArt, isNull);
      expect(preset.source, 'TUNEIN');
      expect(preset.location, '/v1/playback/station/s33828');
      expect(preset.type, 'stationurl');
      expect(preset.isPresetable, true);
      expect(preset.createdOn, isNull);
      expect(preset.updatedOn, isNull);
    });

    test('fromXml parses preset with isPresetable false', () {
      const xmlString = '''
      <preset id="5">
        <ContentItem source="SPOTIFY" type="playlist" location="/v1/spotify/playlist/123" isPresetable="false">
          <itemName>My Playlist</itemName>
          <containerArt>http://example.com/art.png</containerArt>
        </ContentItem>
      </preset>
      ''';

      final document = XmlDocument.parse(xmlString);
      final presetElement = document.findAllElements('preset').first;

      final preset = Preset.fromXml(presetElement);

      expect(preset.id, '5');
      expect(preset.itemName, 'My Playlist');
      expect(preset.containerArt, 'http://example.com/art.png');
      expect(preset.source, 'SPOTIFY');
      expect(preset.location, '/v1/spotify/playlist/123');
      expect(preset.type, 'playlist');
      expect(preset.isPresetable, false);
    });

    test('toJson and fromJson work correctly', () {
      final preset = Preset(
        id: '2',
        itemName: 'Test Preset',
        containerArt: 'http://example.com/image.jpg',
        source: 'TUNEIN',
        location: '/v1/test',
        type: 'stationurl',
        isPresetable: true,
        createdOn: 1234567890,
        updatedOn: 1234567900,
      );

      final json = preset.toJson();
      final fromJson = Preset.fromJson(json);

      expect(fromJson.id, preset.id);
      expect(fromJson.itemName, preset.itemName);
      expect(fromJson.containerArt, preset.containerArt);
      expect(fromJson.source, preset.source);
      expect(fromJson.location, preset.location);
      expect(fromJson.type, preset.type);
      expect(fromJson.isPresetable, preset.isPresetable);
      expect(fromJson.createdOn, preset.createdOn);
      expect(fromJson.updatedOn, preset.updatedOn);
    });

    test('equality and hashCode work correctly', () {
      final preset1 = Preset(
        id: '1',
        itemName: 'Test',
        source: 'TUNEIN',
        location: '/test',
        type: 'stationurl',
        isPresetable: true,
      );

      final preset2 = Preset(
        id: '1',
        itemName: 'Different Name',
        source: 'SPOTIFY',
        location: '/different',
        type: 'playlist',
        isPresetable: false,
      );

      final preset3 = Preset(
        id: '2',
        itemName: 'Test',
        source: 'TUNEIN',
        location: '/test',
        type: 'stationurl',
        isPresetable: true,
      );

      expect(preset1, equals(preset2)); // Same id
      expect(preset1.hashCode, equals(preset2.hashCode));
      expect(preset1, isNot(equals(preset3))); // Different id
    });
  });
}
