import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

import 'main_test.mocks.dart';

@GenerateMocks([SpeakerApiService])
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MyAppState', () {
    test('addSpeaker adds speaker to list', () async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      final initialCount = appState.speakers.length;

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 10',
        deviceId: 'device-test',
      );

      appState.addSpeaker(newSpeaker);

      expect(appState.speakers.length, initialCount + 1);
      expect(appState.speakers.last, newSpeaker);
    });

    test('addSpeaker notifies listeners', () async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      var notified = false;

      appState.addListener(() {
        notified = true;
      });

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 10',
        deviceId: 'device-test',
      );

      appState.addSpeaker(newSpeaker);

      expect(notified, true);
    });

    group('pollAllSpeakersNowPlaying', () {
      const speaker1 = Speaker(
        id: 'sp-1',
        name: 'Kitchen',
        emoji: '🍳',
        ipAddress: '192.168.1.10',
        type: 'SoundTouch 10',
        deviceId: 'dev-1',
      );
      const speaker2 = Speaker(
        id: 'sp-2',
        name: 'Living Room',
        emoji: '🛋️',
        ipAddress: '192.168.1.11',
        type: 'SoundTouch 20',
        deviceId: 'dev-2',
      );
      const nowPlaying1 = NowPlaying(
        track: 'Song A',
        artist: 'Artist A',
        playStatus: 'PLAY_STATE',
      );
      const nowPlaying2 = NowPlaying(
        track: 'Song B',
        artist: 'Artist B',
        playStatus: 'PAUSE_STATE',
      );

      test('fetches all speakers and updates cache', () async {
        final mockApi = MockSpeakerApiService();
        when(mockApi.getNowPlaying('192.168.1.10'))
            .thenAnswer((_) async => nowPlaying1);
        when(mockApi.getNowPlaying('192.168.1.11'))
            .thenAnswer((_) async => nowPlaying2);

        final appState = MyAppState(speakerApiService: mockApi);
        await appState.initializeSpeakers();
        appState.addSpeaker(speaker1);
        appState.addSpeaker(speaker2);

        await appState.pollAllSpeakersNowPlaying();

        expect(appState.getCachedNowPlaying('192.168.1.10'), nowPlaying1);
        expect(appState.getCachedNowPlaying('192.168.1.11'), nowPlaying2);
        expect(appState.getSpeakerConnectionStatus('192.168.1.10'), true);
        expect(appState.getSpeakerConnectionStatus('192.168.1.11'), true);
        verify(mockApi.getNowPlaying('192.168.1.10')).called(1);
        verify(mockApi.getNowPlaying('192.168.1.11')).called(1);
      });

      test('marks speaker as disconnected when API throws', () async {
        final mockApi = MockSpeakerApiService();
        when(mockApi.getNowPlaying('192.168.1.10'))
            .thenAnswer((_) async => nowPlaying1);
        when(mockApi.getNowPlaying('192.168.1.11'))
            .thenThrow(Exception('connection refused'));

        final appState = MyAppState(speakerApiService: mockApi);
        await appState.initializeSpeakers();
        appState.addSpeaker(speaker1);
        appState.addSpeaker(speaker2);

        await appState.pollAllSpeakersNowPlaying();

        expect(appState.getCachedNowPlaying('192.168.1.10'), nowPlaying1);
        expect(appState.getCachedNowPlaying('192.168.1.11'), isNull);
        expect(appState.getSpeakerConnectionStatus('192.168.1.10'), true);
        expect(appState.getSpeakerConnectionStatus('192.168.1.11'), false);
      });

      test('notifies listeners after each speaker resolves', () async {
        final mockApi = MockSpeakerApiService();
        // Use completer to control resolution order
        when(mockApi.getNowPlaying('192.168.1.10'))
            .thenAnswer((_) async => nowPlaying1);
        when(mockApi.getNowPlaying('192.168.1.11'))
            .thenAnswer((_) async => nowPlaying2);

        final appState = MyAppState(speakerApiService: mockApi);
        await appState.initializeSpeakers();
        appState.addSpeaker(speaker1);
        appState.addSpeaker(speaker2);

        var notifyCount = 0;
        appState.addListener(() => notifyCount++);

        await appState.pollAllSpeakersNowPlaying();

        // Should notify once per speaker (2 speakers = 2 notifications)
        expect(notifyCount, 2);
      });

      test('runs all fetches concurrently', () async {
        final callOrder = <String>[];
        final completer1 = Completer<NowPlaying>();
        final completer2 = Completer<NowPlaying>();
        final mockApi = MockSpeakerApiService();

        when(mockApi.getNowPlaying('192.168.1.10')).thenAnswer((_) {
          callOrder.add('start-1');
          return completer1.future.then((v) {
            callOrder.add('end-1');
            return v;
          });
        });
        when(mockApi.getNowPlaying('192.168.1.11')).thenAnswer((_) {
          callOrder.add('start-2');
          return completer2.future.then((v) {
            callOrder.add('end-2');
            return v;
          });
        });

        final appState = MyAppState(speakerApiService: mockApi);
        await appState.initializeSpeakers();
        appState.addSpeaker(speaker1);
        appState.addSpeaker(speaker2);

        final pollFuture = appState.pollAllSpeakersNowPlaying();

        // Both fetches must have started before either completes
        await Future<void>.microtask(() {});
        expect(callOrder, containsAll(['start-1', 'start-2']));
        expect(callOrder, isNot(contains('end-1')));
        expect(callOrder, isNot(contains('end-2')));

        // Complete speaker-2 first, then speaker-1
        completer2.complete(nowPlaying2);
        await Future<void>.microtask(() {});
        expect(callOrder, contains('end-2'));
        expect(callOrder, isNot(contains('end-1')));

        completer1.complete(nowPlaying1);
        await pollFuture;

        // If concurrent, both starts happened before either end
        expect(callOrder.indexOf('start-1'), lessThan(callOrder.indexOf('end-2')));
        expect(callOrder.indexOf('start-2'), lessThan(callOrder.indexOf('end-1')));
      });
    });
  });

  group('MyApp', () {
    testWidgets('builds correctly in light mode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(MyApp(appState: appState));
      await tester.pumpAndSettle();

      // Verify that the app builds without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('builds correctly in dark mode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MyApp(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the app builds without errors in dark mode
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
