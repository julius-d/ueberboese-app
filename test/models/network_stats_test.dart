import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/network_stats.dart';

void main() {
  group('NetworkStats', () {
    test('band is derived from the frequency', () {
      expect(
        const NetworkStats(kind: 'Wireless', frequencyKHz: 2437000).band,
        '2.4 GHz',
      );
      expect(
        const NetworkStats(kind: 'Wireless', frequencyKHz: 5180000).band,
        '5 GHz',
      );
      expect(
        const NetworkStats(kind: 'Wireless', frequencyKHz: 6115000).band,
        '6 GHz',
      );
      expect(const NetworkStats(kind: 'Wireless').band, isNull);
    });

    test('isWireless is case-insensitive', () {
      expect(const NetworkStats(kind: 'wireless').isWireless, true);
      expect(const NetworkStats(kind: 'Wired').isWireless, false);
    });
  });
}
