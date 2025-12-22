import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

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

    test('getVolume parses volume response correctly', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<volume deviceID="1004567890AA">
  <targetvolume>50</targetvolume>
  <actualvolume>50</actualvolume>
  <muteenabled>false</muteenabled>
</volume>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final volume = await apiService.getVolume('192.168.1.100');

      expect(volume.targetVolume, 50);
      expect(volume.actualVolume, 50);
      expect(volume.muteEnabled, false);
    });

    test('getVolume parses muted volume correctly', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<volume deviceID="1004567890AA">
  <targetvolume>0</targetvolume>
  <actualvolume>0</actualvolume>
  <muteenabled>true</muteenabled>
</volume>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final volume = await apiService.getVolume('192.168.1.100');

      expect(volume.targetVolume, 0);
      expect(volume.actualVolume, 0);
      expect(volume.muteEnabled, true);
    });

    test('setVolume sends correct XML and parses response', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<volume deviceID="1004567890AA">
  <targetvolume>75</targetvolume>
  <actualvolume>75</actualvolume>
  <muteenabled>false</muteenabled>
</volume>''';

      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final volume = await apiService.setVolume('192.168.1.100', 75);

      expect(volume.targetVolume, 75);
      expect(volume.actualVolume, 75);
      expect(volume.muteEnabled, false);

      // Verify the request was made with correct XML body
      verify(mockClient.post(
        any,
        headers: {'Content-Type': 'text/xml'},
        body: '<volume>75</volume>',
      )).called(1);
    });

    test('setVolume throws ArgumentError for volume < 0', () async {
      expect(
        () => apiService.setVolume('192.168.1.100', -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setVolume throws ArgumentError for volume > 100', () async {
      expect(
        () => apiService.setVolume('192.168.1.100', 101),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setVolume accepts volume at boundaries (0 and 100)', () async {
      const xmlResponse0 = '''<?xml version="1.0" encoding="UTF-8" ?>
<volume deviceID="1004567890AA">
  <targetvolume>0</targetvolume>
  <actualvolume>0</actualvolume>
  <muteenabled>false</muteenabled>
</volume>''';

      const xmlResponse100 = '''<?xml version="1.0" encoding="UTF-8" ?>
<volume deviceID="1004567890AA">
  <targetvolume>100</targetvolume>
  <actualvolume>100</actualvolume>
  <muteenabled>false</muteenabled>
</volume>''';

      when(mockClient.post(any, headers: anyNamed('headers'), body: '<volume>0</volume>')).thenAnswer(
        (_) async => http.Response(xmlResponse0, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      when(mockClient.post(any, headers: anyNamed('headers'), body: '<volume>100</volume>')).thenAnswer(
        (_) async => http.Response(xmlResponse100, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final volume0 = await apiService.setVolume('192.168.1.100', 0);
      expect(volume0.actualVolume, 0);

      final volume100 = await apiService.setVolume('192.168.1.100', 100);
      expect(volume100.actualVolume, 100);
    });

    test('getVolume throws exception on non-200 status code', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => apiService.getVolume('192.168.1.100'),
        throwsA(isA<Exception>()),
      );
    });

    test('setVolume throws exception on non-200 status code', () async {
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => apiService.setVolume('192.168.1.100', 50),
        throwsA(isA<Exception>()),
      );
    });
  });
}
