import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/pages/album_art_viewer_page.dart';

void main() {
  group('AlbumArtViewerPage', () {
    const testImageUrl = 'https://example.com/album-art.jpg';
    const testHeroTag = 'test-album-art';

    testWidgets('displays album art image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
          ),
        ),
      );

      // Verify the Image.network widget is present
      expect(find.byType(Image), findsOneWidget);

      // Verify the image has the correct URL
      final Image imageWidget = tester.widget(find.byType(Image));
      final NetworkImage imageProvider = imageWidget.image as NetworkImage;
      expect(imageProvider.url, testImageUrl);
    });

    testWidgets('dismisses when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AlbumArtViewerPage(
                        imageUrl: testImageUrl,
                        heroTag: testHeroTag,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the viewer
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify the viewer is displayed
      expect(find.byType(AlbumArtViewerPage), findsOneWidget);

      // Tap to dismiss
      await tester.tap(find.byType(AlbumArtViewerPage));
      await tester.pumpAndSettle();

      // Verify the viewer is no longer displayed
      expect(find.byType(AlbumArtViewerPage), findsNothing);
    });

    testWidgets('displays track information when provided', (tester) async {
      const testTrack = 'Test Track';
      const testArtist = 'Test Artist';
      const testAlbum = 'Test Album';

      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
            track: testTrack,
            artist: testArtist,
            album: testAlbum,
          ),
        ),
      );

      // Verify track info is displayed
      expect(find.text(testTrack), findsOneWidget);
      expect(find.text(testArtist), findsOneWidget);
      expect(find.text(testAlbum), findsOneWidget);
    });

    testWidgets('does not display track info overlay when no info provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
          ),
        ),
      );

      // Verify no Positioned widget for track info overlay
      expect(find.byType(Positioned), findsNothing);
    });

    testWidgets('displays partial track information', (tester) async {
      const testTrack = 'Test Track';

      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
            track: testTrack,
          ),
        ),
      );

      // Verify only track is displayed
      expect(find.text(testTrack), findsOneWidget);
    });

    testWidgets('uses Hero animation with correct tag', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
          ),
        ),
      );

      // Verify Hero widget exists
      expect(find.byType(Hero), findsOneWidget);

      // Verify the Hero tag is correct
      final Hero heroWidget = tester.widget(find.byType(Hero));
      expect(heroWidget.tag, testHeroTag);
    });

    testWidgets('uses default hero tag when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
          ),
        ),
      );

      // Verify Hero widget exists
      expect(find.byType(Hero), findsOneWidget);

      // Verify the default Hero tag is used
      final Hero heroWidget = tester.widget(find.byType(Hero));
      expect(heroWidget.tag, 'album-art');
    });

    testWidgets('contains InteractiveViewer for zoom functionality', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
          ),
        ),
      );

      // Verify InteractiveViewer is present
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
          ),
        ),
      );

      // Verify Scaffold has black background
      final Scaffold scaffold = tester.widget(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('contains SafeArea widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AlbumArtViewerPage(
            imageUrl: testImageUrl,
            heroTag: testHeroTag,
          ),
        ),
      );

      // Verify SafeArea is present
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('handles back button press', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const AlbumArtViewerPage(
                        imageUrl: testImageUrl,
                        heroTag: testHeroTag,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the viewer
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify the viewer is displayed
      expect(find.byType(AlbumArtViewerPage), findsOneWidget);

      // Simulate back button press
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Verify the viewer is no longer displayed
      expect(find.byType(AlbumArtViewerPage), findsNothing);
    });
  });
}
