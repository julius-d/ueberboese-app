class NetworkStats {
  final String? ssid;
  final String? rssi;
  final int? frequencyKHz;
  final String? ipAddress;
  final String? macAddress;
  final String kind;

  const NetworkStats({
    this.ssid,
    this.rssi,
    this.frequencyKHz,
    this.ipAddress,
    this.macAddress,
    required this.kind,
  });

  bool get isWireless => kind.toLowerCase() == 'wireless';

  /// Wi-Fi band derived from the frequency, e.g. "5 GHz".
  String? get band {
    final khz = frequencyKHz;
    if (khz == null || khz <= 0) return null;
    final ghz = khz / 1000000;
    if (ghz < 3) return '2.4 GHz';
    if (ghz < 5.9) return '5 GHz';
    return '6 GHz';
  }
}
