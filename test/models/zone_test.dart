import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/zone.dart';

void main() {
  group('ZoneMember', () {
    test('creates ZoneMember from XML', () {
      final xmlString = '<member ipaddress="192.168.1.131">1004567890AA</member>';
      final element = XmlDocument.parse(xmlString).rootElement;

      final member = ZoneMember.fromXml(element);

      expect(member.deviceId, '1004567890AA');
      expect(member.ipAddress, '192.168.1.131');
    });

    test('converts ZoneMember to XML', () {
      final member = ZoneMember(
        deviceId: '1004567890AA',
        ipAddress: '192.168.1.131',
      );

      final xml = member.toXml();

      expect(xml, '<member ipaddress="192.168.1.131">1004567890AA</member>');
    });

    test('ZoneMember equality works correctly', () {
      final member1 = ZoneMember(
        deviceId: '1004567890AA',
        ipAddress: '192.168.1.131',
      );
      final member2 = ZoneMember(
        deviceId: '1004567890AA',
        ipAddress: '192.168.1.131',
      );
      final member3 = ZoneMember(
        deviceId: '3004567890BB',
        ipAddress: '192.168.1.130',
      );

      expect(member1, member2);
      expect(member1, isNot(member3));
      expect(member1.hashCode, member2.hashCode);
    });
  });

  group('Zone', () {
    test('creates Zone with members', () {
      final zone = Zone(
        masterId: '1004567890AA',
        members: [
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ],
      );

      expect(zone.masterId, '1004567890AA');
      expect(zone.members.length, 2);
      expect(zone.isNotEmpty, true);
      expect(zone.isEmpty, false);
    });

    test('isEmpty returns true for empty zone', () {
      final zone = Zone(
        masterId: '1004567890AA',
        members: [],
      );

      expect(zone.isEmpty, true);
      expect(zone.isNotEmpty, false);
    });

    test('isMaster identifies master correctly', () {
      final zone = Zone(
        masterId: '1004567890AA',
        members: [
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ],
      );

      expect(zone.isMaster('1004567890AA'), true);
      expect(zone.isMaster('3004567890BB'), false);
    });

    test('isMember identifies members correctly', () {
      final zone = Zone(
        masterId: '1004567890AA',
        members: [
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ],
      );

      expect(zone.isMember('1004567890AA'), true);
      expect(zone.isMember('3004567890BB'), true);
      expect(zone.isMember('UNKNOWN'), false);
    });

    test('converts Zone to XML', () {
      final zone = Zone(
        masterId: '1004567890AA',
        members: [
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ],
      );

      final xml = zone.toXml();

      expect(xml, contains('<zone master="1004567890AA">'));
      expect(xml, contains('<member ipaddress="192.168.1.131">1004567890AA</member>'));
      expect(xml, contains('<member ipaddress="192.168.1.130">3004567890BB</member>'));
      expect(xml, contains('</zone>'));
    });

    test('Zone equality works correctly', () {
      final zone1 = Zone(
        masterId: '1004567890AA',
        members: [
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ],
      );
      final zone2 = Zone(
        masterId: '1004567890AA',
        members: [
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
          ZoneMember(deviceId: '3004567890BB', ipAddress: '192.168.1.130'),
        ],
      );
      final zone3 = Zone(
        masterId: 'DIFFERENT',
        members: [
          ZoneMember(deviceId: '1004567890AA', ipAddress: '192.168.1.131'),
        ],
      );

      expect(zone1, zone2);
      expect(zone1, isNot(zone3));
      expect(zone1.hashCode, zone2.hashCode);
    });

    test('Zone with optional attributes', () {
      final zone = Zone(
        masterId: '1004567890AA',
        members: [],
        senderIpAddress: '192.168.1.131',
        senderIsMaster: true,
      );

      expect(zone.senderIpAddress, '192.168.1.131');
      expect(zone.senderIsMaster, true);
    });
  });
}
