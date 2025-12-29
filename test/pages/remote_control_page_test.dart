import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/remote_control_page.dart';

void main() {
  group('RemoteControlPage', () {
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    testWidgets('displays speaker name in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemoteControlPage(speaker: testSpeaker),
        ),
      );

      expect(find.text('🔊'), findsOneWidget);
      expect(find.text('Remote Control'), findsOneWidget);
      expect(find.text('Test Speaker'), findsOneWidget);
    });

    testWidgets('displays all required buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemoteControlPage(speaker: testSpeaker),
        ),
      );

      // Check for all button labels
      expect(find.text('Power'), findsOneWidget);
      expect(find.text('AUX Input'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Volume Down'), findsOneWidget);
      expect(find.text('Volume Up'), findsOneWidget);
      expect(find.text('Play/Pause'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('displays all required icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemoteControlPage(speaker: testSpeaker),
        ),
      );

      // Check for all button icons
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
      expect(find.byIcon(Icons.input), findsOneWidget);
      expect(find.byIcon(Icons.filter_1), findsOneWidget);
      expect(find.byIcon(Icons.filter_2), findsOneWidget);
      expect(find.byIcon(Icons.filter_3), findsOneWidget);
      expect(find.byIcon(Icons.filter_4), findsOneWidget);
      expect(find.byIcon(Icons.filter_5), findsOneWidget);
      expect(find.byIcon(Icons.filter_6), findsOneWidget);
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(find.byIcon(Icons.volume_down), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });
  });
}
