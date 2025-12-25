import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/models/zone.dart';

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
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
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
          ZoneMember(deviceId: 'F9BC35A6D825', ipAddress: '192.168.1.132'),
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
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
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
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
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
  });
}
