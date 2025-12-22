class ZoneMember {
  final String deviceId;
  final String ipAddress;

  const ZoneMember({
    required this.deviceId,
    required this.ipAddress,
  });

  factory ZoneMember.fromXml(dynamic memberElement) {
    final ipAddress = memberElement.getAttribute('ipaddress') ?? '';
    final deviceId = memberElement.text;
    return ZoneMember(
      deviceId: deviceId,
      ipAddress: ipAddress,
    );
  }

  String toXml() {
    return '<member ipaddress="$ipAddress">$deviceId</member>';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoneMember &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          ipAddress == other.ipAddress;

  @override
  int get hashCode => Object.hash(deviceId, ipAddress);
}

class Zone {
  final String masterId;
  final List<ZoneMember> members;
  final String? senderIpAddress;
  final bool? senderIsMaster;

  const Zone({
    required this.masterId,
    required this.members,
    this.senderIpAddress,
    this.senderIsMaster,
  });

  bool get isEmpty => members.isEmpty;
  bool get isNotEmpty => members.isNotEmpty;

  /// Returns all devices in the zone, including the master
  /// The master is always listed first, followed by members (excluding duplicates)
  List<String> get allMemberDeviceIds {
    // Start with master, then add members that are not the master
    final memberIds = members
        .map((m) => m.deviceId)
        .where((id) => id != masterId)
        .toList();
    return [masterId, ...memberIds];
  }

  bool isMaster(String deviceId) => masterId == deviceId;
  bool isMember(String deviceId) => members.any((m) => m.deviceId == deviceId);
  bool isInZone(String deviceId) => masterId == deviceId || isMember(deviceId);

  String toXml() {
    final membersXml = members.map((m) => m.toXml()).join('\n  ');
    return '<zone master="$masterId">\n  $membersXml\n</zone>';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Zone &&
          runtimeType == other.runtimeType &&
          masterId == other.masterId &&
          members.length == other.members.length &&
          members.every((m) => other.members.contains(m));

  @override
  int get hashCode => Object.hash(masterId, Object.hashAll(members));
}
