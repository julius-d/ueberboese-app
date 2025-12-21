import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'dart:convert';

import 'speaker_api_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SpeakerApiService', () {
    late MockClient mockClient;
    late SpeakerApiService apiService;

    setUp(() {
      mockClient = MockClient();
      apiService = SpeakerApiService(httpClient: mockClient);
    });

    test('fetchSpeakerInfo parses basic speaker info correctly', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="587A628A4073">
  <name>Living Room</name>
  <type>SoundTouch 10</type>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speakerInfo = await apiService.fetchSpeakerInfo('192.168.1.100');

      expect(speakerInfo.name, 'Living Room');
      expect(speakerInfo.type, 'SoundTouch 10');
      expect(speakerInfo.margeUrl, isNull);
      expect(speakerInfo.accountId, isNull);
    });

    test('fetchSpeakerInfo parses margeURL and accountId correctly', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="587A628A4073">
  <name>Küche</name>
  <type>SoundTouch 10</type>
  <margeAccountUUID>6921073</margeAccountUUID>
  <components>
    <component>
      <componentCategory>SCM</componentCategory>
      <softwareVersion>27.0.6.46330.5043500 epdbuild.trunk.hepdswbld04.2022-08-04T11:20:29</softwareVersion>
      <serialNumber>P8146619702739342030120</serialNumber>
    </component>
  </components>
  <margeURL>https://ueberboese.familie-dannert.de</margeURL>
  <networkInfo type="SCM">
    <macAddress>587A628A4073</macAddress>
    <ipAddress>192.168.178.26</ipAddress>
  </networkInfo>
  <networkInfo type="SMSC">
    <macAddress>40BD32BAB0EA</macAddress>
    <ipAddress>192.168.178.26</ipAddress>
  </networkInfo>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speakerInfo = await apiService.fetchSpeakerInfo('192.168.178.26');

      expect(speakerInfo.name, 'Küche');
      expect(speakerInfo.type, 'SoundTouch 10');
      expect(speakerInfo.margeUrl, 'https://ueberboese.familie-dannert.de');
      expect(speakerInfo.accountId, '587A628A4073');
    });

    test('fetchSpeakerInfo handles Bose domain margeURL', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="123456789ABC">
  <name>Bedroom</name>
  <type>SoundTouch 20</type>
  <margeURL>https://worldwide.bose.com/updates/soundtouch</margeURL>
  <networkInfo type="SCM">
    <macAddress>123456789ABC</macAddress>
    <ipAddress>192.168.1.50</ipAddress>
  </networkInfo>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speakerInfo = await apiService.fetchSpeakerInfo('192.168.1.50');

      expect(speakerInfo.name, 'Bedroom');
      expect(speakerInfo.type, 'SoundTouch 20');
      expect(speakerInfo.margeUrl, 'https://worldwide.bose.com/updates/soundtouch');
      expect(speakerInfo.accountId, '123456789ABC');
    });

    test('fetchSpeakerInfo extracts macAddress from correct networkInfo', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="TEST123">
  <name>Test Speaker</name>
  <type>SoundTouch 30</type>
  <margeURL>https://custom.domain.com</margeURL>
  <networkInfo type="SMSC">
    <macAddress>WRONG123</macAddress>
    <ipAddress>192.168.1.1</ipAddress>
  </networkInfo>
  <networkInfo type="SCM">
    <macAddress>CORRECT456</macAddress>
    <ipAddress>192.168.1.2</ipAddress>
  </networkInfo>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speakerInfo = await apiService.fetchSpeakerInfo('192.168.1.2');

      expect(speakerInfo.accountId, 'CORRECT456');
    });

    test('fetchSpeakerInfo throws exception when name is missing', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="TEST123">
  <type>SoundTouch 10</type>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      expect(
        () => apiService.fetchSpeakerInfo('192.168.1.100'),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchSpeakerInfo throws exception when type is missing', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="TEST123">
  <name>Test Speaker</name>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      expect(
        () => apiService.fetchSpeakerInfo('192.168.1.100'),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchSpeakerInfo throws exception on non-200 status code', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => apiService.fetchSpeakerInfo('192.168.1.100'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
