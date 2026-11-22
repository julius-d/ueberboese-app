import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F-Droid Metadata Tests', () {
    test('short_description.txt exists and meets requirements', () {
      final file = File('metadata/en-US/short_description.txt');
      expect(
        file.existsSync(),
        true,
        reason: 'short_description.txt must exist',
      );

      final content = file.readAsStringSync().trim();
      expect(
        content.isNotEmpty,
        true,
        reason: 'short_description.txt must not be empty',
      );
      expect(
        content.length,
        greaterThanOrEqualTo(30),
        reason: 'Short description must be at least 30 characters',
      );
      expect(
        content.length,
        lessThanOrEqualTo(50),
        reason: 'Short description must not exceed 50 characters',
      );
      expect(
        content.endsWith('.'),
        false,
        reason: 'Short description must not end with a period',
      );
    });

    test('full_description.txt exists and is not empty', () {
      final file = File('metadata/en-US/full_description.txt');
      expect(
        file.existsSync(),
        true,
        reason: 'full_description.txt must exist',
      );

      final content = file.readAsStringSync().trim();
      expect(
        content.isNotEmpty,
        true,
        reason: 'full_description.txt must not be empty',
      );
      expect(
        content.length,
        greaterThan(100),
        reason: 'Full description should be descriptive (>100 chars)',
      );
    });

    test('icon.png exists', () {
      final file = File('metadata/en-US/images/icon.png');
      expect(file.existsSync(), true, reason: 'icon.png must exist');
    });

    test('phoneScreenshots directory has at least one screenshot', () {
      final dir = Directory('metadata/en-US/images/phoneScreenshots');
      expect(
        dir.existsSync(),
        true,
        reason: 'phoneScreenshots directory must exist',
      );

      final screenshots = dir
          .listSync()
          .where((file) => file.path.endsWith('.png'))
          .toList();
      expect(
        screenshots.isNotEmpty,
        true,
        reason: 'At least one screenshot must exist',
      );
      expect(
        screenshots.length,
        greaterThanOrEqualTo(3),
        reason: 'At least 3 screenshots are recommended',
      );
    });

    group('changelog files', () {
      late List<File> changelogFiles;

      setUp(() {
        final dir = Directory('metadata/en-US/changelogs');
        changelogFiles = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.txt'))
            .toList();
      });

      test('changelog directory has at least one file', () {
        expect(
          changelogFiles.isNotEmpty,
          true,
          reason: 'At least one changelog file must exist',
        );
      });

      test('no changelog file starts with a blank line', () {
        for (final file in changelogFiles) {
          final content = file.readAsStringSync();
          if (content.isEmpty) continue;
          expect(
            content.startsWith('\n'),
            false,
            reason: '${file.path} must not start with a blank line',
          );
        }
      });

      test('no changelog file ends with more than one newline', () {
        for (final file in changelogFiles) {
          final content = file.readAsStringSync();
          if (content.isEmpty) continue;
          expect(
            content.endsWith('\n\n'),
            false,
            reason: '${file.path} must not end with extra blank lines',
          );
        }
      });

      test('no changelog file contains consecutive blank lines', () {
        for (final file in changelogFiles) {
          final content = file.readAsStringSync();
          expect(
            content.contains('\n\n\n'),
            false,
            reason: '${file.path} must not contain consecutive blank lines',
          );
        }
      });
    });
  });
}
