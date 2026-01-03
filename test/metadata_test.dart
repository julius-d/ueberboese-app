import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('F-Droid Metadata Tests', () {
    test('short_description.txt exists and meets requirements', () {
      final file = File('metadata/en-US/short_description.txt');
      expect(file.existsSync(), true,
          reason: 'short_description.txt must exist');

      final content = file.readAsStringSync().trim();
      expect(content.isNotEmpty, true,
          reason: 'short_description.txt must not be empty');
      expect(content.length, greaterThanOrEqualTo(30),
          reason: 'Short description must be at least 30 characters');
      expect(content.length, lessThanOrEqualTo(50),
          reason: 'Short description must not exceed 50 characters');
      expect(content.endsWith('.'), false,
          reason: 'Short description must not end with a period');
    });

    test('full_description.txt exists and is not empty', () {
      final file = File('metadata/en-US/full_description.txt');
      expect(file.existsSync(), true,
          reason: 'full_description.txt must exist');

      final content = file.readAsStringSync().trim();
      expect(content.isNotEmpty, true,
          reason: 'full_description.txt must not be empty');
      expect(content.length, greaterThan(100),
          reason: 'Full description should be descriptive (>100 chars)');
    });

    test('icon.png exists', () {
      final file = File('metadata/en-US/images/icon.png');
      expect(file.existsSync(), true, reason: 'icon.png must exist');
    });

    test('phoneScreenshots directory has at least one screenshot', () {
      final dir = Directory('metadata/en-US/images/phoneScreenshots');
      expect(dir.existsSync(), true,
          reason: 'phoneScreenshots directory must exist');

      final screenshots =
          dir.listSync().where((file) => file.path.endsWith('.png')).toList();
      expect(screenshots.isNotEmpty, true,
          reason: 'At least one screenshot must exist');
      expect(screenshots.length, greaterThanOrEqualTo(3),
          reason: 'At least 3 screenshots are recommended');
    });

  });
}
