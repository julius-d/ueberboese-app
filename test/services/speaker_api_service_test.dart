import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/models/clock_display.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/models/zone.dart';
import 'package:ueberboese_app/models/recent.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/models/speaker_source.dart';

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
      expect(speakerInfo.deviceId, '587A628A4073');
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
      expect(speakerInfo.deviceId, '587A628A4073');
      expect(speakerInfo.margeUrl, 'https://ueberboese.familie-dannert.de');
      expect(speakerInfo.accountId, '6921073');
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
      expect(speakerInfo.deviceId, '123456789ABC');
      expect(speakerInfo.margeUrl, 'https://worldwide.bose.com/updates/soundtouch');
      expect(speakerInfo.accountId, isNull);
    });

    test('fetchSpeakerInfo extracts accountId from margeAccountUUID', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="TEST123">
  <name>Test Speaker</name>
  <type>SoundTouch 30</type>
  <margeAccountUUID>ACCOUNT789</margeAccountUUID>
  <margeURL>https://custom.domain.com</margeURL>
  <networkInfo type="SMSC">
    <macAddress>WRONG123</macAddress>
    <ipAddress>192.168.1.1</ipAddress>
  </networkInfo>
  <networkInfo type="SCM">
    <macAddress>DIFFERENT456</macAddress>
    <ipAddress>192.168.1.2</ipAddress>
  </networkInfo>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speakerInfo = await apiService.fetchSpeakerInfo('192.168.1.2');

      expect(speakerInfo.deviceId, 'TEST123');
      expect(speakerInfo.accountId, 'ACCOUNT789');
    });

    test('fetchSpeakerInfo returns null accountId when margeAccountUUID is missing', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="TEST456">
  <name>Speaker Without Account</name>
  <type>SoundTouch 20</type>
  <margeURL>https://example.com</margeURL>
  <networkInfo type="SCM">
    <macAddress>ABCD1234</macAddress>
    <ipAddress>192.168.1.5</ipAddress>
  </networkInfo>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speakerInfo = await apiService.fetchSpeakerInfo('192.168.1.5');

      expect(speakerInfo.deviceId, 'TEST456');
      expect(speakerInfo.accountId, isNull);
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

    test('fetchSpeakerInfo throws exception when deviceID is missing', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info>
  <name>Test Speaker</name>
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

    test('fetchSpeakerInfo throws exception when deviceID is empty', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="">
  <name>Test Speaker</name>
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

    test('fetchSpeakerInfo throws exception on non-200 status code', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => apiService.fetchSpeakerInfo('192.168.1.100'),
        throwsA(isA<Exception>()),
      );
    });

    test('createSpeakerFromIp creates speaker with correct deviceId from speakerInfo', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="587A628A4073">
  <name>Living Room</name>
  <type>SoundTouch 10</type>
  <margeAccountUUID>6921073</margeAccountUUID>
  <margeURL>https://ueberboese.example.com</margeURL>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speaker = await apiService.createSpeakerFromIp('192.168.1.100', '🔊');

      expect(speaker.name, 'Living Room');
      expect(speaker.type, 'SoundTouch 10');
      expect(speaker.deviceId, '587A628A4073');  // deviceId from deviceID attribute, NOT from margeAccountUUID
      expect(speaker.emoji, '🔊');
      expect(speaker.ipAddress, '192.168.1.100');
      expect(speaker.id, isNotEmpty);
    });

    test('createSpeakerFromIp creates speaker with deviceId even when accountId present', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="ABC123DEF456">
  <name>Kitchen</name>
  <type>SoundTouch 20</type>
  <margeAccountUUID>ACCOUNT789</margeAccountUUID>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speaker = await apiService.createSpeakerFromIp('192.168.1.50', '🎵');

      // Verify deviceId comes from deviceID attribute, not margeAccountUUID
      expect(speaker.deviceId, 'ABC123DEF456');
      expect(speaker.deviceId, isNot('ACCOUNT789'));
    });

    test('createSpeakerFromIp throws exception when fetchSpeakerInfo fails', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => apiService.createSpeakerFromIp('192.168.1.100', '🔊'),
        throwsA(isA<Exception>()),
      );
    });

    test('createSpeakerFromIp creates unique IDs for speakers', () async {
      const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<info deviceID="TEST123">
  <name>Test Speaker</name>
  <type>SoundTouch 10</type>
</info>''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
      );

      final speaker1 = await apiService.createSpeakerFromIp('192.168.1.100', '🔊');
      // Small delay to ensure different timestamp
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final speaker2 = await apiService.createSpeakerFromIp('192.168.1.100', '🔊');

      expect(speaker1.id, isNot(equals(speaker2.id)));
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

    group('Zone API', () {
      test('getZone returns null for empty zone', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<zone />''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final zone = await apiService.getZone('192.168.1.131');

        expect(zone, isNull);
      });

      test('getZone parses master zone correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<zone master="1004567890AA">
  <member ipaddress="192.168.1.131">1004567890AA</member>
  <member ipaddress="192.168.1.130">3004567890BB</member>
</zone>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final zone = await apiService.getZone('192.168.1.131');

        expect(zone, isNotNull);
        expect(zone!.masterId, '1004567890AA');
        expect(zone.members.length, 2);
        expect(zone.members[0].deviceId, '1004567890AA');
        expect(zone.members[0].ipAddress, '192.168.1.131');
        expect(zone.members[1].deviceId, '3004567890BB');
        expect(zone.members[1].ipAddress, '192.168.1.130');
        expect(zone.senderIpAddress, isNull);
        expect(zone.senderIsMaster, isNull);
      });

      test('getZone parses member zone correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<zone master="1004567890AA" senderIPAddress="192.168.1.131" senderIsMaster="true">
  <member ipaddress="192.168.1.130">3004567890BB</member>
</zone>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final zone = await apiService.getZone('192.168.1.130');

        expect(zone, isNotNull);
        expect(zone!.masterId, '1004567890AA');
        expect(zone.members.length, 1);
        expect(zone.members[0].deviceId, '3004567890BB');
        expect(zone.senderIpAddress, '192.168.1.131');
        expect(zone.senderIsMaster, true);
      });

      test('getZone correctly identifies master not in members list', () async {
        // This happens when querying the master device
        // The master is only in the "master" attribute, not in <member> elements
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<zone master="MASTER123ABC" senderIPAddress="192.168.1.100" senderIsMaster="true">
  <member ipaddress="192.168.1.101">MEMBER456DEF</member>
</zone>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final zone = await apiService.getZone('192.168.1.100');

        expect(zone, isNotNull);
        expect(zone!.masterId, 'MASTER123ABC');

        // Only one member in the XML (not including master)
        expect(zone.members.length, 1);
        expect(zone.members[0].deviceId, 'MEMBER456DEF');

        // But allMemberDeviceIds should include both master and member
        expect(zone.allMemberDeviceIds.length, 2);
        expect(zone.allMemberDeviceIds[0], 'MASTER123ABC'); // Master first
        expect(zone.allMemberDeviceIds[1], 'MEMBER456DEF'); // Member second

        // Check helper methods
        expect(zone.isMaster('MASTER123ABC'), true);
        expect(zone.isMaster('MEMBER456DEF'), false);
        expect(zone.isInZone('MASTER123ABC'), true);
        expect(zone.isInZone('MEMBER456DEF'), true);
      });

      test('getZone handles master appearing in members list', () async {
        // This happens when querying a non-master device
        // The API includes the master in the members list
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<zone master="MASTER123ABC">
  <member ipaddress="192.168.1.100">MASTER123ABC</member>
  <member ipaddress="192.168.1.101">MEMBER456DEF</member>
</zone>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final zone = await apiService.getZone('192.168.1.101');

        expect(zone, isNotNull);
        expect(zone!.masterId, 'MASTER123ABC');

        // Two members in the XML (including master)
        expect(zone.members.length, 2);
        expect(zone.members[0].deviceId, 'MASTER123ABC');
        expect(zone.members[1].deviceId, 'MEMBER456DEF');

        // allMemberDeviceIds should deduplicate and return only 2 unique devices
        expect(zone.allMemberDeviceIds.length, 2);
        expect(zone.allMemberDeviceIds[0], 'MASTER123ABC'); // Master first
        expect(zone.allMemberDeviceIds[1], 'MEMBER456DEF'); // Member second
        expect(zone.allMemberDeviceIds.toSet().length, 2); // No duplicates

        // Both devices should be considered in the zone
        expect(zone.isInZone('MASTER123ABC'), true);
        expect(zone.isInZone('MEMBER456DEF'), true);
      });

      test('createZone sends correct XML', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<status>/setZone</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final members = [
          const ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          const ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ];

        await apiService.createZone('192.168.1.131', '1004567890AA', members);

        final captured = verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[0] as String;
        expect(body, contains('<zone master="1004567890AA">'));
        expect(body, contains('<member ipaddress="192.168.1.131">1004567890AA</member>'));
        expect(body, contains('<member ipaddress="192.168.1.130">3004567890BB</member>'));
      });

      test('addZoneMembers sends correct XML', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<status>/addZoneSlave</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final newMembers = [
          const ZoneMember(deviceId: 'F9BC35A6D825', ipAddress: '192.168.1.132'),
        ];

        await apiService.addZoneMembers('192.168.1.131', '1004567890AA', newMembers);

        final captured = verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[0] as String;
        expect(body, contains('<zone master="1004567890AA">'));
        expect(body, contains('<member ipaddress="192.168.1.132">F9BC35A6D825</member>'));
      });

      test('removeZoneMembers sends correct XML', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<status>/removeZoneSlave</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final membersToRemove = [
          const ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ];

        await apiService.removeZoneMembers('192.168.1.131', '1004567890AA', membersToRemove);

        final captured = verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[0] as String;
        expect(body, contains('<zone master="1004567890AA">'));
        expect(body, contains('<member ipaddress="192.168.1.130">3004567890BB</member>'));
      });

      test('getZone throws exception on non-200 status code', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        expect(
          () => apiService.getZone('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('createZone throws exception on non-200 status code', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        final members = [
          const ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
        ];

        expect(
          () => apiService.createZone('192.168.1.131', '1004567890AA', members),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Play Control API', () {
      test('userPlayControl sends PAUSE_CONTROL correctly', () async {
        const xmlResponse = '''<?xml version='1.0' encoding='utf-8'?>
<status>/userPlayControl</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        await apiService.userPlayControl('192.168.1.131', 'PAUSE_CONTROL');

        verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: '<PlayControl>PAUSE_CONTROL</PlayControl>',
        )).called(1);
      });

      test('userPlayControl sends PLAY_CONTROL correctly', () async {
        const xmlResponse = '''<?xml version='1.0' encoding='utf-8'?>
<status>/userPlayControl</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        await apiService.userPlayControl('192.168.1.131', 'PLAY_CONTROL');

        verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: '<PlayControl>PLAY_CONTROL</PlayControl>',
        )).called(1);
      });

      test('userPlayControl sends PLAY_PAUSE_CONTROL correctly', () async {
        const xmlResponse = '''<?xml version='1.0' encoding='utf-8'?>
<status>/userPlayControl</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        await apiService.userPlayControl('192.168.1.131', 'PLAY_PAUSE_CONTROL');

        verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: '<PlayControl>PLAY_PAUSE_CONTROL</PlayControl>',
        )).called(1);
      });

      test('userPlayControl sends STOP_CONTROL correctly', () async {
        const xmlResponse = '''<?xml version='1.0' encoding='utf-8'?>
<status>/userPlayControl</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        await apiService.userPlayControl('192.168.1.131', 'STOP_CONTROL');

        verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: '<PlayControl>STOP_CONTROL</PlayControl>',
        )).called(1);
      });

      test('userPlayControl throws ArgumentError for invalid control type', () async {
        expect(
          () => apiService.userPlayControl('192.168.1.131', 'INVALID_CONTROL'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('userPlayControl throws exception on non-200 status code', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        expect(
          () => apiService.userPlayControl('192.168.1.131', 'PAUSE_CONTROL'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getPresets', () {
      test('getPresets parses multiple presets correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="1">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s33828" isPresetable="true">
      <itemName>K-LOVE Radio</itemName>
      <containerArt>http://cdn-profiles.tunein.com/s33828/images/logog.png?t=637986894890000000</containerArt>
    </ContentItem>
  </preset>
  <preset id="2">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s309606" isPresetable="true">
      <itemName>K-LOVE 2000s</itemName>
      <containerArt>http://cdn-profiles.tunein.com/s309606/images/logog.png?t=637986893640000000</containerArt>
    </ContentItem>
  </preset>
  <preset id="3" createdOn="1701220500" updatedOn="1701220500">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s309605" isPresetable="true">
      <itemName>My Copy K-Love 90s</itemName>
      <containerArt>http://cdn-profiles.tunein.com/s309605/images/logog.png?t=637986891960000000</containerArt>
    </ContentItem>
  </preset>
</presets>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final presets = await apiService.getPresets('192.168.1.131');

        expect(presets.length, 3);

        expect(presets[0].id, '1');
        expect(presets[0].itemName, 'K-LOVE Radio');
        expect(presets[0].source, 'TUNEIN');
        expect(presets[0].location, '/v1/playback/station/s33828');
        expect(presets[0].type, 'stationurl');
        expect(presets[0].isPresetable, true);
        expect(presets[0].containerArt, contains('s33828'));
        expect(presets[0].createdOn, isNull);
        expect(presets[0].updatedOn, isNull);

        expect(presets[1].id, '2');
        expect(presets[1].itemName, 'K-LOVE 2000s');

        expect(presets[2].id, '3');
        expect(presets[2].itemName, 'My Copy K-Love 90s');
        expect(presets[2].createdOn, 1701220500);
        expect(presets[2].updatedOn, 1701220500);
      });

      test('getPresets returns empty list when no presets', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
</presets>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final presets = await apiService.getPresets('192.168.1.131');

        expect(presets, isEmpty);
      });

      test('getPresets throws exception on non-200 status code', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        expect(
          () => apiService.getPresets('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('getPresets throws exception on timeout', () async {
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.get(any)).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('', 200),
          ),
        );

        expect(
          () => fastApiService.getPresets('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('getPresets throws exception on XML parsing error', () async {
        const xmlResponse = '''This is not valid XML''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        expect(
          () => apiService.getPresets('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('removePreset', () {
      test('removePreset sends correct XML and returns updated list', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="1">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s33828" isPresetable="true">
      <itemName>K-LOVE Radio</itemName>
      <containerArt>http://cdn-profiles.tunein.com/s33828/images/logog.png</containerArt>
    </ContentItem>
  </preset>
  <preset id="3">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s309605" isPresetable="true">
      <itemName>K-LOVE 90s</itemName>
      <containerArt>http://cdn-profiles.tunein.com/s309605/images/logog.png</containerArt>
    </ContentItem>
  </preset>
</presets>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final presets = await apiService.removePreset('192.168.1.131', '2');

        // Verify request was made correctly
        verify(mockClient.post(
          any,
          headers: {'Content-Type': 'text/xml'},
          body: '<preset id="2"></preset>',
        )).called(1);

        // Verify response parsing
        expect(presets.length, 2);
        expect(presets[0].id, '1');
        expect(presets[1].id, '3');
        // Preset 2 should be removed
        expect(presets.any((p) => p.id == '2'), false);
      });

      test('removePreset returns empty list when all presets deleted', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
</presets>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final presets = await apiService.removePreset('192.168.1.131', '1');

        expect(presets, isEmpty);
      });

      test('removePreset throws exception on non-200 status code', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        expect(
          () => apiService.removePreset('192.168.1.131', '1'),
          throwsA(isA<Exception>()),
        );
      });

      test('removePreset throws exception on timeout', () async {
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('', 200),
          ),
        );

        expect(
          () => fastApiService.removePreset('192.168.1.131', '1'),
          throwsA(isA<Exception>()),
        );
      });

      test('removePreset throws exception on XML parsing error', () async {
        const xmlResponse = '''This is not valid XML''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        expect(
          () => apiService.removePreset('192.168.1.131', '1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Standby API', () {
      test('standby sends GET request to correct endpoint', () async {
        const xmlResponse = '''<?xml version='1.0' encoding='utf-8'?>
<status>/standby</status>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        await apiService.standby('192.168.1.131');

        verify(mockClient.get(
          Uri.parse('http://192.168.1.131:8090/standby'),
        )).called(1);
      });

      test('standby throws exception on non-200 status code', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        expect(
          () => apiService.standby('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('standby throws exception on timeout', () async {
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.get(any)).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('', 200),
          ),
        );

        expect(
          () => fastApiService.standby('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('storePreset', () {
      test('should store preset successfully', () async {
        const ipAddress = '192.168.1.131';
        const presetId = '3';
        const spotifyUri = 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M';
        const spotifyUserId = 'testuser123';
        const itemName = 'Top 50 Global';
        const containerArt = 'https://example.com/art.jpg';

        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="3" createdOn="1701220500" updatedOn="1701220500">
    <ContentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/c3BvdGlmeTpwbGF5bGlzdDozN2k5ZFFaRjFEWGNCV0lHb1lCTTVN" sourceAccount="testuser123" isPresetable="true">
      <itemName>Top 50 Global</itemName>
      <containerArt>https://example.com/art.jpg</containerArt>
    </ContentItem>
  </preset>
</presets>''';

        final mockResponse = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final result = await apiService.storePreset(
          ipAddress,
          presetId,
          spotifyUri,
          spotifyUserId,
          itemName,
          containerArt,
        );

        expect(result.length, 1);
        expect(result[0].id, '3');
        expect(result[0].itemName, itemName);
        expect(result[0].source, 'SPOTIFY');

        verify(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });

      test('should store preset with null containerArt', () async {
        const ipAddress = '192.168.1.131';
        const presetId = '3';
        const spotifyUri = 'spotify:playlist:37i9dQZF1DXcBWIGoYBM5M';
        const spotifyUserId = 'testuser123';
        const itemName = 'Top 50 Global';

        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="3" createdOn="1701220500" updatedOn="1701220500">
    <ContentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/c3BvdGlmeTpwbGF5bGlzdDozN2k5ZFFaRjFEWGNCV0lHb1lCTTVN" sourceAccount="testuser123" isPresetable="true">
      <itemName>Top 50 Global</itemName>
    </ContentItem>
  </preset>
</presets>''';

        final mockResponse = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final result = await apiService.storePreset(
          ipAddress,
          presetId,
          spotifyUri,
          spotifyUserId,
          itemName,
          null,
        );

        expect(result.length, 1);
        expect(result[0].id, '3');
        expect(result[0].containerArt, isNull);
      });

      test('should encode Spotify URI to base64 correctly', () async {
        const ipAddress = '192.168.1.131';
        const presetId = '1';
        const spotifyUri = 'spotify:playlist:123';
        const spotifyUserId = 'user123';
        const itemName = 'Test Playlist';

        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="1">
    <ContentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/c3BvdGlmeTpwbGF5bGlzdDoxMjM=" sourceAccount="user123" isPresetable="true">
      <itemName>Test Playlist</itemName>
    </ContentItem>
  </preset>
</presets>''';

        final mockResponse = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: argThat(contains('/playback/container/c3BvdGlmeTpwbGF5bGlzdDoxMjM='), named: 'body'),
        )).thenAnswer((_) async => mockResponse);

        await apiService.storePreset(
          ipAddress,
          presetId,
          spotifyUri,
          spotifyUserId,
          itemName,
          null,
        );

        verify(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: argThat(contains('/playback/container/c3BvdGlmeTpwbGF5bGlzdDoxMjM='), named: 'body'),
        )).called(1);
      });

      test('should throw exception on non-200 status code', () async {
        const ipAddress = '192.168.1.131';
        final mockResponse = http.Response('Internal Server Error', 500);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        expect(
          () => apiService.storePreset(
            ipAddress,
            '1',
            'spotify:playlist:123',
            'user123',
            'Test',
            null,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on malformed XML', () async {
        const ipAddress = '192.168.1.131';
        final mockResponse = http.Response('not valid xml', 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        expect(
          () => apiService.storePreset(
            ipAddress,
            '1',
            'spotify:playlist:123',
            'user123',
            'Test',
            null,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        const ipAddress = '192.168.1.131';
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('{}', 200),
          ),
        );

        expect(
          () => fastApiService.storePreset(
            ipAddress,
            '1',
            'spotify:playlist:123',
            'user123',
            'Test',
            null,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('storeTuneInPreset', () {
      test('should store TuneIn preset successfully', () async {
        const ipAddress = '192.168.1.131';
        const presetId = '3';
        const stationId = 's288368';
        const itemName = 'Radio Potsdam';
        const containerArt = 'http://example.com/logo.png';

        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="3" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s288368" isPresetable="true">
      <itemName>$itemName</itemName>
      <containerArt>$containerArt</containerArt>
    </ContentItem>
  </preset>
</presets>''';

        final mockResponse = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final result = await apiService.storeTuneInPreset(
          ipAddress,
          presetId,
          stationId,
          itemName,
          containerArt,
        );

        expect(result.length, 1);
        expect(result[0].id, '3');
        expect(result[0].itemName, itemName);
        expect(result[0].source, 'TUNEIN');
        expect(result[0].location, '/v1/playback/station/s288368');

        verify(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });

      test('should store TuneIn preset without containerArt', () async {
        const ipAddress = '192.168.1.131';
        const presetId = '3';
        const stationId = 's288368';
        const itemName = 'Radio Potsdam';

        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="3" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s288368" isPresetable="true">
      <itemName>$itemName</itemName>
    </ContentItem>
  </preset>
</presets>''';

        final mockResponse = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        final result = await apiService.storeTuneInPreset(
          ipAddress,
          presetId,
          stationId,
          itemName,
          null,
        );

        expect(result.length, 1);
        expect(result[0].id, '3');
        expect(result[0].itemName, itemName);
        expect(result[0].source, 'TUNEIN');

        verify(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(1);
      });

      test('should include correct location format', () async {
        const ipAddress = '192.168.1.131';
        const presetId = '3';
        const stationId = 's288368';
        const itemName = 'Test';

        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="3" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s288368" isPresetable="true">
      <itemName>Test</itemName>
    </ContentItem>
  </preset>
</presets>''';

        final mockResponse = http.Response(responseBody, 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: argThat(contains('/v1/playback/station/s288368'), named: 'body'),
        )).thenAnswer((_) async => mockResponse);

        await apiService.storeTuneInPreset(
          ipAddress,
          presetId,
          stationId,
          itemName,
          null,
        );

        verify(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: argThat(contains('/v1/playback/station/s288368'), named: 'body'),
        )).called(1);
      });

      test('should throw exception on non-200 status code', () async {
        const ipAddress = '192.168.1.131';
        final mockResponse = http.Response('Internal Server Error', 500);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        expect(
          () => apiService.storeTuneInPreset(
            ipAddress,
            '1',
            's12345',
            'Test',
            null,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on malformed XML', () async {
        const ipAddress = '192.168.1.131';
        final mockResponse = http.Response('not valid xml', 200);

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockResponse);

        expect(
          () => apiService.storeTuneInPreset(
            ipAddress,
            '1',
            's12345',
            'Test',
            null,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        const ipAddress = '192.168.1.131';
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/storePreset'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('{}', 200),
          ),
        );

        expect(
          () => fastApiService.storeTuneInPreset(
            ipAddress,
            '1',
            's12345',
            'Test',
            null,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getNowPlaying', () {
      test('getNowPlaying parses ContentItem with location and source', () async {
        const ipAddress = '192.168.1.100';
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<nowPlaying>
  <ContentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/c3BvdGlmeTp0cmFjazoxMjM0NTY=" isPresetable="true">
    <itemName>Test Track</itemName>
    <containerArt>https://example.com/art.jpg</containerArt>
  </ContentItem>
  <track>Test Track</track>
  <artist>Test Artist</artist>
  <album>Test Album</album>
  <art>http://192.168.1.100:8090/image/1234567890</art>
  <playStatus>PLAY_STATE</playStatus>
  <shuffleSetting>SHUFFLE_OFF</shuffleSetting>
  <repeatSetting>REPEAT_OFF</repeatSetting>
</nowPlaying>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final result = await apiService.getNowPlaying(ipAddress);

        expect(result.track, equals('Test Track'));
        expect(result.artist, equals('Test Artist'));
        expect(result.album, equals('Test Album'));
        expect(result.art, equals('http://192.168.1.100:8090/image/1234567890'));
        expect(result.playStatus, equals('PLAY_STATE'));
        expect(result.shuffleSetting, equals('SHUFFLE_OFF'));
        expect(result.repeatSetting, equals('REPEAT_OFF'));
        expect(result.source, equals('SPOTIFY'));
        expect(result.location, equals('/playback/container/c3BvdGlmeTp0cmFjazoxMjM0NTY='));
      });

      test('getNowPlaying handles missing ContentItem gracefully', () async {
        const ipAddress = '192.168.1.100';
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<nowPlaying>
  <track>Test Track</track>
  <artist>Test Artist</artist>
  <playStatus>PLAY_STATE</playStatus>
</nowPlaying>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final result = await apiService.getNowPlaying(ipAddress);

        expect(result.track, equals('Test Track'));
        expect(result.artist, equals('Test Artist'));
        expect(result.playStatus, equals('PLAY_STATE'));
        expect(result.source, isNull);
        expect(result.location, isNull);
      });

      test('getNowPlaying parses TV/PRODUCT source correctly', () async {
        const ipAddress = '192.168.1.100';
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<nowPlaying deviceID="C4F312DD8A8F" source="PRODUCT" sourceAccount="TV">
  <ContentItem source="PRODUCT" sourceAccount="TV" isPresetable="false"/>
  <art artImageStatus="SHOW_DEFAULT_IMAGE"/>
  <playStatus>PLAY_STATE</playStatus>
</nowPlaying>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final result = await apiService.getNowPlaying(ipAddress);

        expect(result.source, equals('PRODUCT'));
        expect(result.sourceAccount, equals('TV'));
        expect(result.playStatus, equals('PLAY_STATE'));
        expect(result.artImageStatus, equals('SHOW_DEFAULT_IMAGE'));
        expect(result.track, isNull);
        expect(result.artist, isNull);
        expect(result.album, isNull);
      });

      test('getNowPlaying should throw exception on non-200 status code', () async {
        const ipAddress = '192.168.1.100';
        final mockResponse = http.Response('Internal Server Error', 500);

        when(mockClient.get(Uri.parse('http://$ipAddress:8090/nowPlaying')))
            .thenAnswer((_) async => mockResponse);

        expect(
          () => apiService.getNowPlaying(ipAddress),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('sendKey', () {
      test('sends key press with correct XML format', () async {
        const ipAddress = '192.168.1.100';
        const keyValue = 'POWER';
        const state = 'press';
        const expectedBody = '<key state="$state" sender="Gabbo">$keyValue</key>';

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/key'),
          headers: {'Content-Type': 'text/xml'},
          body: expectedBody,
        )).thenAnswer((_) async => http.Response('', 200));

        await apiService.sendKey(ipAddress, keyValue, state);

        verify(mockClient.post(
          Uri.parse('http://$ipAddress:8090/key'),
          headers: {'Content-Type': 'text/xml'},
          body: expectedBody,
        )).called(1);
      });

      test('sends key release with correct XML format', () async {
        const ipAddress = '192.168.1.100';
        const keyValue = 'VOLUME_UP';
        const state = 'release';
        const expectedBody = '<key state="$state" sender="Gabbo">$keyValue</key>';

        when(mockClient.post(
          Uri.parse('http://$ipAddress:8090/key'),
          headers: {'Content-Type': 'text/xml'},
          body: expectedBody,
        )).thenAnswer((_) async => http.Response('', 200));

        await apiService.sendKey(ipAddress, keyValue, state);

        verify(mockClient.post(
          Uri.parse('http://$ipAddress:8090/key'),
          headers: {'Content-Type': 'text/xml'},
          body: expectedBody,
        )).called(1);
      });

      test('throws ArgumentError for invalid key value', () async {
        const ipAddress = '192.168.1.100';
        const invalidKey = 'INVALID_KEY';
        const state = 'press';

        expect(
          () => apiService.sendKey(ipAddress, invalidKey, state),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for invalid state', () async {
        const ipAddress = '192.168.1.100';
        const keyValue = 'POWER';
        const invalidState = 'invalid';

        expect(
          () => apiService.sendKey(ipAddress, keyValue, invalidState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('key values are case sensitive', () async {
        const ipAddress = '192.168.1.100';
        const lowercaseKey = 'power'; // lowercase version should be invalid
        const state = 'press';

        expect(
          () => apiService.sendKey(ipAddress, lowercaseKey, state),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('state values are case sensitive', () async {
        const ipAddress = '192.168.1.100';
        const keyValue = 'POWER';
        const uppercaseState = 'PRESS'; // uppercase version should be invalid

        expect(
          () => apiService.sendKey(ipAddress, keyValue, uppercaseState),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws exception when HTTP request fails', () async {
        const ipAddress = '192.168.1.100';
        const keyValue = 'POWER';
        const state = 'press';

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

        expect(
          () => apiService.sendKey(ipAddress, keyValue, state),
          throwsA(isA<Exception>()),
        );
      });

      test('accepts all valid key values', () async {
        const ipAddress = '192.168.1.100';
        const state = 'press';
        const validKeys = [
          'ADD_FAVORITE',
          'AUX_INPUT',
          'BOOKMARK',
          'MUTE',
          'NEXT_TRACK',
          'PAUSE',
          'PLAY',
          'PLAY_PAUSE',
          'POWER',
          'PRESET_1',
          'PRESET_2',
          'PRESET_3',
          'PRESET_4',
          'PRESET_5',
          'PRESET_6',
          'PREV_TRACK',
          'REMOVE_FAVORITE',
          'REPEAT_ALL',
          'REPEAT_OFF',
          'REPEAT_ONE',
          'SHUFFLE_OFF',
          'SHUFFLE_ON',
          'STOP',
          'THUMBS_DOWN',
          'THUMBS_UP',
          'VOLUME_DOWN',
          'VOLUME_UP',
        ];

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('', 200));

        for (final key in validKeys) {
          await apiService.sendKey(ipAddress, key, state);
        }

        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(validKeys.length);
      });

      test('accepts all valid states', () async {
        const ipAddress = '192.168.1.100';
        const keyValue = 'POWER';
        const validStates = ['press', 'release', 'repeat'];

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('', 200));

        for (final state in validStates) {
          await apiService.sendKey(ipAddress, keyValue, state);
        }

        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).called(validStates.length);
      });
    });

    group('setSpeakerName', () {
      const ipAddress = '192.168.1.100';
      const speakerName = 'Living Room';

      test('successfully sets speaker name', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('', 200));

        await apiService.setSpeakerName(ipAddress, speakerName);

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(captured[0].toString(), 'http://$ipAddress:8090/name');
        expect(captured[1], {'Content-Type': 'text/xml'});
        expect(captured[2], '<name>$speakerName</name>');
      });

      test('throws exception on HTTP error', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Error', 500));

        expect(
          () => apiService.setSpeakerName(ipAddress, speakerName),
          throwsException,
        );
      });

      test('throws exception on timeout', () async {
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          return http.Response('', 200);
        });

        expect(
          () => fastApiService.setSpeakerName(ipAddress, speakerName),
          throwsException,
        );
      });

      test('throws exception on network error', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(Exception('Network error'));

        expect(
          () => apiService.setSpeakerName(ipAddress, speakerName),
          throwsException,
        );
      });

      test('handles special characters in name', () async {
        const specialName = 'Living Room & Kitchen';

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('', 200));

        await apiService.setSpeakerName(ipAddress, specialName);

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(captured[2], '<name>$specialName</name>');
      });
    });

    group('storeInternetRadioPreset', () {
      const ipAddress = '192.168.1.100';
      const presetId = '1';
      const url = 'https://stream.example.com/radio';
      const itemName = 'My Radio Station';
      const apiUrl = 'https://ueberboese.example.com';

      test('stores Internet Radio preset successfully', () async {
        // Expected Base64 encoded JSON: {"name":"My Radio Station","imageUrl":"","streamUrl":"https://stream.example.com/radio"}
        const expectedLocation = 'https://ueberboese.example.com/core02/svc-bmx-adapter-orion/prod/orion/station?data=eyJuYW1lIjoiTXkgUmFkaW8gU3RhdGlvbiIsImltYWdlVXJsIjoiIiwic3RyZWFtVXJsIjoiaHR0cHM6Ly9zdHJlYW0uZXhhbXBsZS5jb20vcmFkaW8ifQ==';

        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="1" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="LOCAL_INTERNET_RADIO" type="stationurl" location="https://ueberboese.example.com/core02/svc-bmx-adapter-orion/prod/orion/station?data=eyJuYW1lIjoiTXkgUmFkaW8gU3RhdGlvbiIsImltYWdlVXJsIjoiIiwic3RyZWFtVXJsIjoiaHR0cHM6Ly9zdHJlYW0uZXhhbXBsZS5jb20vcmFkaW8ifQ==" isPresetable="true">
      <itemName>My Radio Station</itemName>
    </ContentItem>
  </preset>
</presets>''';

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(xmlResponse, 200));

        final presets = await apiService.storeInternetRadioPreset(
          ipAddress,
          presetId,
          url,
          itemName,
          null,
          apiUrl,
        );

        expect(presets, hasLength(1));
        expect(presets[0].id, '1');
        expect(presets[0].source, 'LOCAL_INTERNET_RADIO');
        expect(presets[0].type, 'stationurl');
        expect(presets[0].location, expectedLocation);
        expect(presets[0].itemName, itemName);
        expect(presets[0].isPresetable, true);
      });

      test('stores Internet Radio preset with container art', () async {
        const containerArt = 'https://example.com/art.png';
        // Expected Base64 encoded JSON: {"name":"My Radio Station","imageUrl":"https://example.com/art.png","streamUrl":"https://stream.example.com/radio"}

        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="1" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="LOCAL_INTERNET_RADIO" type="stationurl" location="https://ueberboese.example.com/core02/svc-bmx-adapter-orion/prod/orion/station?data=eyJuYW1lIjoiTXkgUmFkaW8gU3RhdGlvbiIsImltYWdlVXJsIjoiaHR0cHM6Ly9leGFtcGxlLmNvbS9hcnQucG5nIiwic3RyZWFtVXJsIjoiaHR0cHM6Ly9zdHJlYW0uZXhhbXBsZS5jb20vcmFkaW8ifQ==" isPresetable="true">
      <itemName>My Radio Station</itemName>
      <containerArt>https://example.com/art.png</containerArt>
    </ContentItem>
  </preset>
</presets>''';

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(xmlResponse, 200));

        final presets = await apiService.storeInternetRadioPreset(
          ipAddress,
          presetId,
          url,
          itemName,
          containerArt,
          apiUrl,
        );

        expect(presets, hasLength(1));
        expect(presets[0].containerArt, containerArt);
      });

      test('sends correct XML body format', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="1" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="LOCAL_INTERNET_RADIO" type="stationurl" location="https://ueberboese.example.com/core02/svc-bmx-adapter-orion/prod/orion/station?data=eyJuYW1lIjoiTXkgUmFkaW8gU3RhdGlvbiIsImltYWdlVXJsIjoiIiwic3RyZWFtVXJsIjoiaHR0cHM6Ly9zdHJlYW0uZXhhbXBsZS5jb20vcmFkaW8ifQ==" isPresetable="true">
      <itemName>My Radio Station</itemName>
    </ContentItem>
  </preset>
</presets>''';

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(xmlResponse, 200));

        await apiService.storeInternetRadioPreset(
          ipAddress,
          presetId,
          url,
          itemName,
          null,
          apiUrl,
        );

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[2] as String;
        expect(body, contains('source="LOCAL_INTERNET_RADIO"'));
        expect(body, contains('type="stationurl"'));
        expect(body, contains('location="$apiUrl/core02/svc-bmx-adapter-orion/prod/orion/station?data='));
        expect(body, contains('isPresetable="true"'));
        expect(body, contains('<itemName>$itemName</itemName>'));
      });

      test('throws exception on HTTP error', () async {
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Error', 500));

        expect(
          () => apiService.storeInternetRadioPreset(
            ipAddress,
            presetId,
            url,
            itemName,
            null,
            apiUrl,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('encodes JSON data correctly in Base64', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<presets>
  <preset id="1" createdOn="1234567890" updatedOn="1234567890">
    <ContentItem source="LOCAL_INTERNET_RADIO" type="stationurl" location="https://ueberboese.example.com/core02/svc-bmx-adapter-orion/prod/orion/station?data=test" isPresetable="true">
      <itemName>My Radio Station</itemName>
    </ContentItem>
  </preset>
</presets>''';

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(xmlResponse, 200));

        await apiService.storeInternetRadioPreset(
          ipAddress,
          presetId,
          url,
          itemName,
          null,
          apiUrl,
        );

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[2] as String;

        // Extract the Base64 data from the location URL
        final locationMatch = RegExp(r'location="[^"]*\?data=([^"]+)"').firstMatch(body);
        expect(locationMatch, isNotNull);

        final base64Data = locationMatch!.group(1)!;
        final decodedBytes = base64Decode(base64Data);
        final decodedJson = utf8.decode(decodedBytes);
        final jsonData = jsonDecode(decodedJson) as Map<String, dynamic>;

        expect(jsonData['name'], itemName);
        expect(jsonData['imageUrl'], '');
        expect(jsonData['streamUrl'], url);
      });
    });

    group('getRecents', () {
      test('getRecents parses multiple recents correctly and sorts by utcTime', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<recents>
  <recent deviceID="1004567890AA" utcTime="1697087351" id="2">
    <contentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s33255" sourceAccount="" isPresetable="true">
      <itemName>89.7 | The River (College Radio)</itemName>
    </contentItem>
  </recent>
  <recent deviceID="44EAD8A17CC7" utcTime="1768323670" id="1">
    <contentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s80044" sourceAccount="" isPresetable="true">
      <itemName>Radio TEDDY</itemName>
    </contentItem>
  </recent>
  <recent deviceID="44EAD8A17CC7" utcTime="1768304677" id="4">
    <contentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu" sourceAccount="z5zt8py3wuxytbza4cxa431ge" isPresetable="true">
      <itemName>Komplett Entspannt</itemName>
    </contentItem>
  </recent>
</recents>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final recents = await apiService.getRecents('192.168.1.131');

        expect(recents.length, 3);

        // Check that items are sorted by utcTime descending (newest first)
        expect(recents[0].utcTime, 1768323670); // Newest
        expect(recents[0].id, '1');
        expect(recents[0].itemName, 'Radio TEDDY');
        expect(recents[0].deviceId, '44EAD8A17CC7');
        expect(recents[0].source, 'TUNEIN');
        expect(recents[0].location, '/v1/playback/station/s80044');
        expect(recents[0].type, 'stationurl');
        expect(recents[0].isPresetable, true);

        expect(recents[1].utcTime, 1768304677); // Second newest
        expect(recents[1].id, '4');
        expect(recents[1].itemName, 'Komplett Entspannt');
        expect(recents[1].source, 'SPOTIFY');
        expect(recents[1].sourceAccount, 'z5zt8py3wuxytbza4cxa431ge');

        expect(recents[2].utcTime, 1697087351); // Oldest
        expect(recents[2].id, '2');
        expect(recents[2].itemName, '89.7 | The River (College Radio)');
      });

      test('getRecents returns empty list when no recents', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<recents>
</recents>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final recents = await apiService.getRecents('192.168.1.131');

        expect(recents, isEmpty);
      });

      test('getRecents throws exception on non-200 status code', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        expect(
          () => apiService.getRecents('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('getRecents throws exception on timeout', () async {
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.get(any)).thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('', 200),
          ),
        );

        expect(
          () => fastApiService.getRecents('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('getRecents throws exception on XML parsing error', () async {
        const xmlResponse = '''This is not valid XML''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        expect(
          () => apiService.getRecents('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('getRecents parses LOCAL_INTERNET_RADIO recent correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8"?>
<recents>
  <recent deviceID="1004567890AA" utcTime="1699027517" id="2485930515">
    <contentItem source="LOCAL_INTERNET_RADIO" type="stationurl" location="https://content.api.bose.io/core02/svc-bmx-adapter-orion/prod/orion/station?data=eyJuYW1lIjoidGVzdCBzdGF0aW9uIiwiaW1hZ2VVcmwiOiIiLCJzdHJlYW1VcmwiOiJodHRwczovL2ZyZWV0ZXN0ZGF0YS5jb20vd3AtY29udGVudC91cGxvYWRzLzIwMjEvMDkvRnJlZV9UZXN0X0RhdGFfMU1CX01QMy5tcDMifQ%3D%3D" sourceAccount="" isPresetable="true">
      <itemName>test station</itemName>
    </contentItem>
  </recent>
</recents>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200, headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final recents = await apiService.getRecents('192.168.1.131');

        expect(recents.length, 1);
        expect(recents[0].deviceId, '1004567890AA');
        expect(recents[0].utcTime, 1699027517);
        expect(recents[0].id, '2485930515');
        expect(recents[0].itemName, 'test station');
        expect(recents[0].source, 'LOCAL_INTERNET_RADIO');
        expect(recents[0].type, 'stationurl');
        expect(recents[0].isPresetable, true);
      });
    });

    group('selectContentItem', () {
      test('selectContentItem sends correct XML for TUNEIN content', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?><status>/select</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(xmlResponse, 200));

        const recent = Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        );

        await apiService.selectContentItem('192.168.1.131', recent);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        expect(captured[0], {'Content-Type': 'text/xml'});
        final body = captured[1] as String;
        expect(body, contains('<ContentItem'));
        expect(body, contains('source="TUNEIN"'));
        expect(body, contains('type="stationurl"'));
        expect(body, contains('location="/v1/playback/station/s80044"'));
        expect(body, contains('isPresetable="true"'));
        expect(body, contains('<itemName>Radio TEDDY</itemName>'));
      });

      test('selectContentItem sends correct XML for SPOTIFY content with sourceAccount', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?><status>/select</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(xmlResponse, 200));

        const recent = Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768304677,
          id: '4',
          itemName: 'Komplett Entspannt',
          source: 'SPOTIFY',
          location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu',
          type: 'tracklisturl',
          isPresetable: true,
          sourceAccount: 'z5zt8py3wuxytbza4cxa431ge',
        );

        await apiService.selectContentItem('192.168.1.131', recent);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        expect(body, contains('source="SPOTIFY"'));
        expect(body, contains('sourceAccount="z5zt8py3wuxytbza4cxa431ge"'));
        expect(body, contains('<itemName>Komplett Entspannt</itemName>'));
      });

      test('selectContentItem does not include sourceAccount if empty', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?><status>/select</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(xmlResponse, 200));

        const recent = Recent(
          deviceId: '1004567890AA',
          utcTime: 1697087351,
          id: '2',
          itemName: '89.7 | The River (College Radio)',
          source: 'TUNEIN',
          location: '/v1/playback/station/s33255',
          type: 'stationurl',
          isPresetable: true,
          sourceAccount: '',
        );

        await apiService.selectContentItem('192.168.1.131', recent);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        expect(body, isNot(contains('sourceAccount')));
      });

      test('selectContentItem escapes special characters in itemName', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?><status>/select</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(xmlResponse, 200));

        const recent = Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Rock & Roll <with> "quotes"',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        );

        await apiService.selectContentItem('192.168.1.131', recent);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        // XML library escapes & and < but > and " don't need escaping in text content
        expect(body, contains('Rock &amp; Roll &lt;with> "quotes"'));
      });

      test('selectContentItem throws exception on non-200 status code', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        const recent = Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        );

        expect(
          () => apiService.selectContentItem('192.168.1.131', recent),
          throwsA(isA<Exception>()),
        );
      });

      test('selectContentItem throws exception on timeout', () async {
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('', 200),
          ),
        );

        const recent = Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        );

        expect(
          () => fastApiService.selectContentItem('192.168.1.131', recent),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('selectPreset', () {
      test('selectPreset sends correct XML for preset', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?><status>/select</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(xmlResponse, 200));

        const preset = Preset(
          id: '1',
          itemName: 'My Favorite Playlist',
          source: 'SPOTIFY',
          location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu',
          type: 'tracklisturl',
          isPresetable: true,
          sourceAccount: 'user123',
        );

        await apiService.selectPreset('192.168.1.131', preset);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        expect(captured[0], {'Content-Type': 'text/xml'});
        final body = captured[1] as String;
        expect(body, contains('<ContentItem'));
        expect(body, contains('source="SPOTIFY"'));
        expect(body, contains('type="tracklisturl"'));
        expect(body, contains('location="/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu"'));
        expect(body, contains('isPresetable="true"'));
        expect(body, contains('sourceAccount="user123"'));
        expect(body, contains('<itemName>My Favorite Playlist</itemName>'));
      });

      test('selectPreset does not include sourceAccount if null', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?><status>/select</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(xmlResponse, 200));

        const preset = Preset(
          id: '2',
          itemName: 'TuneIn Station',
          source: 'TUNEIN',
          location: '/v1/playback/station/s33828',
          type: 'stationurl',
          isPresetable: true,
        );

        await apiService.selectPreset('192.168.1.131', preset);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        expect(body, isNot(contains('sourceAccount')));
      });

      test('selectPreset throws exception on non-200 status code without response body', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 500));

        const preset = Preset(
          id: '1',
          itemName: 'Test Preset',
          source: 'TUNEIN',
          location: '/v1/playback/station/s33828',
          type: 'stationurl',
          isPresetable: true,
        );

        expect(
          () => apiService.selectPreset('192.168.1.131', preset),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString() == 'Exception: Failed to select preset: HTTP 500'),
          ),
        );
      });

      test('selectPreset includes response body in error message when available', () async {
        const errorResponse = '<error><errorCode>INVALID_PRESET</errorCode><message>Preset not found</message></error>';
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(errorResponse, 500));

        const preset = Preset(
          id: '1',
          itemName: 'Test Preset',
          source: 'TUNEIN',
          location: '/v1/playback/station/s33828',
          type: 'stationurl',
          isPresetable: true,
        );

        expect(
          () => apiService.selectPreset('192.168.1.131', preset),
          throwsA(
            predicate((e) =>
                e is Exception &&
                e.toString().contains('HTTP 500') &&
                e.toString().contains(errorResponse)),
          ),
        );
      });

      test('selectPreset throws exception on timeout', () async {
        final fastApiService = SpeakerApiService(
          httpClient: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer(
          (_) async => Future.delayed(
            const Duration(milliseconds: 200),
            () => http.Response('', 200),
          ),
        );

        const preset = Preset(
          id: '1',
          itemName: 'Test Preset',
          source: 'TUNEIN',
          location: '/v1/playback/station/s33828',
          type: 'stationurl',
          isPresetable: true,
        );

        expect(
          () => fastApiService.selectPreset('192.168.1.131', preset),
          throwsA(isA<Exception>()),
        );
      });

      test('selectPreset escapes special characters in itemName', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?><status>/select</status>''';

        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(xmlResponse, 200));

        const preset = Preset(
          id: '1',
          itemName: 'Rock & Roll <with> "quotes"',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        );

        await apiService.selectPreset('192.168.1.131', preset);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        // XML library escapes & and < but > and " don't need escaping in text content
        expect(body, contains('Rock &amp; Roll &lt;with> "quotes"'));
      });
    });

    group('getLanguage', () {
      test('parses language code from response', () async {
        const xmlResponse =
            '<?xml version="1.0" encoding="UTF-8" ?><sysLanguage>3</sysLanguage>';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(
            xmlResponse,
            200,
            headers: {'content-type': 'text/xml; charset=utf-8'},
          ),
        );

        final code = await apiService.getLanguage('192.168.1.100');
        expect(code, 3);
      });

      test('throws on non-200 response', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('', 500),
        );

        expect(
          () => apiService.getLanguage('192.168.1.100'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when sysLanguage element is missing', () async {
        const xmlResponse =
            '<?xml version="1.0" encoding="UTF-8" ?><other>3</other>';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(
            xmlResponse,
            200,
            headers: {'content-type': 'text/xml; charset=utf-8'},
          ),
        );

        expect(
          () => apiService.getLanguage('192.168.1.100'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setLanguage', () {
      test('sends correct XML body with language code', () async {
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('', 200));

        await apiService.setLanguage('192.168.1.100', 2);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        expect(captured[1], '<sysLanguage>2</sysLanguage>');
      });

      test('throws on non-200 response', () async {
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('', 500));

        expect(
          () => apiService.setLanguage('192.168.1.100', 3),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getBassCapabilities', () {
      test('parses full response correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<bassCapabilities deviceID="1004567890AA">
  <bassAvailable>true</bassAvailable>
  <bassMin>-9</bassMin>
  <bassMax>0</bassMax>
  <bassDefault>0</bassDefault>
</bassCapabilities>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final caps = await apiService.getBassCapabilities('192.168.1.131');

        expect(caps.bassAvailable, isTrue);
        expect(caps.bassMin, -9);
        expect(caps.bassMax, 0);
        expect(caps.bassDefault, 0);
      });

      test('parses bassAvailable=false correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<bassCapabilities deviceID="1004567890AA">
  <bassAvailable>false</bassAvailable>
  <bassMin>-9</bassMin>
  <bassMax>0</bassMax>
  <bassDefault>0</bassDefault>
</bassCapabilities>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final caps = await apiService.getBassCapabilities('192.168.1.131');

        expect(caps.bassAvailable, isFalse);
      });

      test('throws on non-200 response', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('', 500),
        );

        expect(
          () => apiService.getBassCapabilities('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getBass', () {
      test('parses bass response correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<bass deviceID="1004567890AA">
  <targetbass>-5</targetbass>
  <actualbass>-5</actualbass>
</bass>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final bass = await apiService.getBass('192.168.1.131');

        expect(bass.targetBass, -5);
        expect(bass.actualBass, -5);
      });

      test('throws when targetbass element missing', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<bass deviceID="1004567890AA">
  <actualbass>0</actualbass>
</bass>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        expect(
          () => apiService.getBass('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on non-200 response', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('', 500),
        );

        expect(
          () => apiService.getBass('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setBass', () {
      test('sends correct XML body with bass value', () async {
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('', 200));

        await apiService.setBass('192.168.1.131', -5);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        expect(captured[1], '<bass>-5</bass>');
      });

      test('throws on non-200 response', () async {
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('', 500));

        expect(
          () => apiService.setBass('192.168.1.131', -5),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('isClockDisplaySupported', () {
      test('returns true when /clockDisplay is in supportedURLs', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<supportedURLs deviceID="1004567890AA">
  <URL location="/volume"/>
  <URL location="/clockDisplay"/>
  <URL location="/bass"/>
</supportedURLs>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final supported =
            await apiService.isClockDisplaySupported('192.168.1.131');
        expect(supported, isTrue);
      });

      test('returns false when /clockDisplay is not in supportedURLs',
          () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<supportedURLs deviceID="1004567890AA">
  <URL location="/volume"/>
  <URL location="/bass"/>
</supportedURLs>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final supported =
            await apiService.isClockDisplaySupported('192.168.1.131');
        expect(supported, isFalse);
      });

      test('returns false on non-200 response (e.g. 404 on older devices)',
          () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('', 404),
        );

        final supported =
            await apiService.isClockDisplaySupported('192.168.1.131');
        expect(supported, isFalse);
      });
    });

    group('getClockDisplay', () {
      test('parses all clockConfig attributes correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<clockDisplay>
  <clockConfig timezoneInfo="America/Chicago"
               userEnable="false"
               timeFormat="TIME_FORMAT_12HOUR_ID"
               userOffsetMinute="0"
               brightnessLevel="70"
               userUtcTime="1701824606" />
</clockDisplay>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final config = await apiService.getClockDisplay('192.168.1.131');

        expect(config.userEnable, isFalse);
        expect(config.timeFormat, 'TIME_FORMAT_12HOUR_ID');
        expect(config.brightnessLevel, 70);
        expect(config.timezoneInfo, 'America/Chicago');
        expect(config.userOffsetMinute, 0);
        expect(config.userUtcTime, 1701824606);
        expect(config.is24Hour, isFalse);
      });

      test('is24Hour returns true for 24h format', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<clockDisplay>
  <clockConfig timezoneInfo="Europe/Berlin"
               userEnable="true"
               timeFormat="TIME_FORMAT_24HOUR_ID"
               userOffsetMinute="60"
               brightnessLevel="50"
               userUtcTime="0" />
</clockDisplay>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        final config = await apiService.getClockDisplay('192.168.1.131');

        expect(config.is24Hour, isTrue);
        expect(config.userEnable, isTrue);
        expect(config.brightnessLevel, 50);
      });

      test('throws when clockConfig element is missing', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<clockDisplay />''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        expect(
          () => apiService.getClockDisplay('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });

      test('throws on non-200 response', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('', 500),
        );

        expect(
          () => apiService.getClockDisplay('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setClockDisplay', () {
      test('sends correct XML body', () async {
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('', 200));

        const config = ClockConfig(
          userEnable: true,
          timeFormat: ClockConfig.format12h,
          brightnessLevel: 70,
          timezoneInfo: 'America/Chicago',
          userOffsetMinute: 0,
          userUtcTime: 0,
        );

        await apiService.setClockDisplay('192.168.1.131', config);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        expect(body, contains('userEnable="true"'));
        expect(body, contains('timeFormat="${ClockConfig.format12h}"'));
        expect(body, contains('brightnessLevel="70"'));
        expect(body, contains('timezoneInfo="America/Chicago"'));
        expect(body, contains('userOffsetMinute="0"'));
      });

      test('sends correct XML body for 24h disabled clock', () async {
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('', 200));

        const config = ClockConfig(
          userEnable: false,
          timeFormat: ClockConfig.format24h,
          brightnessLevel: 30,
          timezoneInfo: 'Europe/Berlin',
          userOffsetMinute: 60,
          userUtcTime: 0,
        );

        await apiService.setClockDisplay('192.168.1.131', config);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        expect(body, contains('userEnable="false"'));
        expect(body, contains('timeFormat="${ClockConfig.format24h}"'));
        expect(body, contains('brightnessLevel="30"'));
        expect(body, contains('timezoneInfo="Europe/Berlin"'));
        expect(body, contains('userOffsetMinute="60"'));
      });

      test('throws on non-200 response', () async {
        when(
          mockClient.post(
            any,
            headers: anyNamed('headers'),
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => http.Response('', 500));

        const config = ClockConfig(
          userEnable: true,
          timeFormat: ClockConfig.format12h,
          brightnessLevel: 70,
          timezoneInfo: '',
          userOffsetMinute: 0,
          userUtcTime: 0,
        );

        expect(
          () => apiService.setClockDisplay('192.168.1.131', config),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getSources', () {
      const singleAuxXml = '''<?xml version="1.0" encoding="UTF-8" ?>
<sources deviceID="9884E39E1EA8">
  <sourceItem source="AUX" sourceAccount="AUX" status="READY" isLocal="true" multiroomallowed="true">AUX IN</sourceItem>
  <sourceItem source="AIRPLAY" sourceAccount="AirPlay2DefaultUserName" status="UNAVAILABLE" isLocal="false" multiroomallowed="false">AirPlay2DefaultUserName</sourceItem>
  <sourceItem source="STORED_MUSIC_MEDIA_RENDERER" sourceAccount="StoredMusicUserName" status="UNAVAILABLE" isLocal="false" multiroomallowed="true">StoredMusicUserName</sourceItem>
  <sourceItem source="QPLAY" sourceAccount="QPlay1UserName" status="UNAVAILABLE" isLocal="true" multiroomallowed="true">QPlay1UserName</sourceItem>
  <sourceItem source="BLUETOOTH" status="UNAVAILABLE" isLocal="true" multiroomallowed="true"/>
  <sourceItem source="UPNP" sourceAccount="UPnPUserName" status="UNAVAILABLE" isLocal="false" multiroomallowed="true">UPnPUserName</sourceItem>
  <sourceItem source="NOTIFICATION" status="UNAVAILABLE" isLocal="false" multiroomallowed="true"/>
  <sourceItem source="SPOTIFY" sourceAccount="z5zt8py3wuxytbza4cxa431ge" status="READY" isLocal="false" multiroomallowed="true">Julius</sourceItem>
  <sourceItem source="SPOTIFY" sourceAccount="SpotifyConnectUserName" status="UNAVAILABLE" isLocal="false" multiroomallowed="true">SpotifyConnectUserName</sourceItem>
  <sourceItem source="ALEXA" status="READY" isLocal="false" multiroomallowed="true"/>
  <sourceItem source="TUNEIN" status="READY" isLocal="false" multiroomallowed="true"/>
</sources>''';

      const threeAuxXml = '''<?xml version="1.0" encoding="UTF-8" ?>
<sources deviceID="EC24B88118C4">
  <sourceItem source="AUX" sourceAccount="AUX1" status="READY" isLocal="true" multiroomallowed="true">AUX IN 1</sourceItem>
  <sourceItem source="AUX" sourceAccount="AUX2" status="READY" isLocal="true" multiroomallowed="true">AUX IN 2</sourceItem>
  <sourceItem source="AUX" sourceAccount="AUX3" status="READY" isLocal="true" multiroomallowed="true">AUX IN 3</sourceItem>
  <sourceItem source="STORED_MUSIC_MEDIA_RENDERER" sourceAccount="StoredMusicUserName" status="UNAVAILABLE" isLocal="false" multiroomallowed="true">StoredMusicUserName</sourceItem>
  <sourceItem source="BLUETOOTH" status="UNAVAILABLE" isLocal="true" multiroomallowed="true"/>
  <sourceItem source="UPNP" sourceAccount="UPnPUserName" status="UNAVAILABLE" isLocal="false" multiroomallowed="true">UPnPUserName</sourceItem>
  <sourceItem source="NOTIFICATION" status="UNAVAILABLE" isLocal="false" multiroomallowed="true"/>
  <sourceItem source="SPOTIFY" sourceAccount="SpotifyConnectUserName" status="UNAVAILABLE" isLocal="false" multiroomallowed="true">SpotifyConnectUserName</sourceItem>
  <sourceItem source="ALEXA" status="READY" isLocal="false" multiroomallowed="true"/>
</sources>''';

      test('returns all source types from the device without filtering', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(singleAuxXml, 200,
              headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final sources = await apiService.getSources('192.168.1.131');

        final sourceTypes = sources.map((s) => s.source).toSet();
        expect(sourceTypes, containsAll({'AUX', 'BLUETOOTH', 'TUNEIN', 'SPOTIFY', 'UPNP'}));
        expect(sourceTypes, contains('AIRPLAY'));
        expect(sourceTypes, contains('NOTIFICATION'));
      });

      test('parses single AUX with display name', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(singleAuxXml, 200,
              headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final sources = await apiService.getSources('192.168.1.131');
        final aux = sources.firstWhere((s) => s.source == 'AUX');

        expect(aux.sourceAccount, 'AUX');
        expect(aux.displayName, 'AUX IN');
        expect(aux.status, 'READY');
      });

      test('uses source name as fallback when inner text is blank (BLUETOOTH)', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(singleAuxXml, 200,
              headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final sources = await apiService.getSources('192.168.1.131');
        final bluetooth = sources.firstWhere((s) => s.source == 'BLUETOOTH');

        expect(bluetooth.displayName, 'BLUETOOTH');
        expect(bluetooth.sourceAccount, isNull);
      });

      test('returns three separate AUX entries for a three-AUX device', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(threeAuxXml, 200,
              headers: {'content-type': 'text/xml; charset=utf-8'}),
        );

        final sources = await apiService.getSources('192.168.1.131');
        final auxSources = sources.where((s) => s.source == 'AUX').toList();

        expect(auxSources.length, 3);
        expect(auxSources[0].sourceAccount, 'AUX1');
        expect(auxSources[0].displayName, 'AUX IN 1');
        expect(auxSources[1].sourceAccount, 'AUX2');
        expect(auxSources[1].displayName, 'AUX IN 2');
        expect(auxSources[2].sourceAccount, 'AUX3');
        expect(auxSources[2].displayName, 'AUX IN 3');
      });

      test('throws on non-200 response', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('', 500),
        );

        expect(
          () => apiService.getSources('192.168.1.131'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('selectSource', () {
      test('sends correct XML for source without sourceAccount (BLUETOOTH)', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        const source = SpeakerSource(
          source: 'BLUETOOTH',
          displayName: 'BLUETOOTH',
        );

        await apiService.selectSource('192.168.1.131', source);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        expect(captured[0], {'Content-Type': 'text/xml'});
        final body = captured[1] as String;
        expect(body, contains('<ContentItem'));
        expect(body, contains('source="BLUETOOTH"'));
        expect(body, isNot(contains('sourceAccount')));
      });

      test('sends correct XML for AUX source with sourceAccount', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        const source = SpeakerSource(
          source: 'AUX',
          sourceAccount: 'AUX1',
          displayName: 'AUX IN 1',
        );

        await apiService.selectSource('192.168.1.131', source);

        final captured = verify(
          mockClient.post(
            any,
            headers: captureAnyNamed('headers'),
            body: captureAnyNamed('body'),
          ),
        ).captured;

        final body = captured[1] as String;
        expect(body, contains('source="AUX"'));
        expect(body, contains('sourceAccount="AUX1"'));
      });

      test('throws on non-200 response', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 500));

        const source = SpeakerSource(source: 'TUNEIN', displayName: 'TuneIn');

        expect(
          () => apiService.selectSource('192.168.1.131', source),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
