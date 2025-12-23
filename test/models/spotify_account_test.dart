import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/spotify_account.dart';

void main() {
  group('SpotifyAccount', () {
    test('creates account with required fields', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
      );

      expect(account.displayName, 'John Doe');
      expect(account.createdAt, createdAt);
    });

    test('equality is based on displayName and createdAt', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account1 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
      );
      final account2 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
      );
      final account3 = SpotifyAccount(
        displayName: 'Jane Smith',
        createdAt: createdAt,
      );

      expect(account1, equals(account2));
      expect(account1, isNot(equals(account3)));
    });

    test('hashCode is based on displayName and createdAt', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account1 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
      );
      final account2 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
      );

      expect(account1.hashCode, equals(account2.hashCode));
    });

    test('toJson serializes account correctly', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
      );

      final json = account.toJson();

      expect(json['displayName'], 'John Doe');
      expect(json['createdAt'], '2025-12-23T10:30:00.000');
    });

    test('fromJson deserializes account correctly', () {
      final json = {
        'displayName': 'John Doe',
        'createdAt': '2025-12-23T10:30:00.000Z',
      };

      final account = SpotifyAccount.fromJson(json);

      expect(account.displayName, 'John Doe');
      expect(account.createdAt.year, 2025);
      expect(account.createdAt.month, 12);
      expect(account.createdAt.day, 23);
    });

    test('roundtrip serialization preserves data', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final original = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
      );

      final json = original.toJson();
      final restored = SpotifyAccount.fromJson(json);

      expect(restored.displayName, original.displayName);
      expect(restored.createdAt, original.createdAt);
    });

    test('handles different display names', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);

      final account1 = SpotifyAccount(
        displayName: 'Simple Name',
        createdAt: createdAt,
      );
      final account2 = SpotifyAccount(
        displayName: 'Name with Spaces',
        createdAt: createdAt,
      );
      final account3 = SpotifyAccount(
        displayName: 'Name_with-special.chars',
        createdAt: createdAt,
      );

      expect(account1.displayName, 'Simple Name');
      expect(account2.displayName, 'Name with Spaces');
      expect(account3.displayName, 'Name_with-special.chars');
    });

    test('handles different date formats in JSON', () {
      // ISO 8601 with Z timezone
      final json1 = {
        'displayName': 'John Doe',
        'createdAt': '2025-12-23T10:30:00.000Z',
      };
      final account1 = SpotifyAccount.fromJson(json1);
      expect(account1.createdAt.year, 2025);

      // ISO 8601 without Z
      final json2 = {
        'displayName': 'Jane Smith',
        'createdAt': '2025-12-23T10:30:00.000',
      };
      final account2 = SpotifyAccount.fromJson(json2);
      expect(account2.createdAt.year, 2025);
    });
  });
}
