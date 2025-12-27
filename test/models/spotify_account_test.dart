import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/models/spotify_account.dart';

void main() {
  group('SpotifyAccount', () {
    test('creates account with required fields', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user123',
      );

      expect(account.displayName, 'John Doe');
      expect(account.createdAt, createdAt);
      expect(account.spotifyUserId, 'user123');
    });

    test('equality is based on displayName, createdAt, and spotifyUserId', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account1 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user123',
      );
      final account2 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user123',
      );
      final account3 = SpotifyAccount(
        displayName: 'Jane Smith',
        createdAt: createdAt,
        spotifyUserId: 'user456',
      );
      final account4 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user456',
      );

      expect(account1, equals(account2));
      expect(account1, isNot(equals(account3)));
      expect(account1, isNot(equals(account4)));
    });

    test('hashCode is based on displayName, createdAt, and spotifyUserId', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account1 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user123',
      );
      final account2 = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user123',
      );

      expect(account1.hashCode, equals(account2.hashCode));
    });

    test('toJson serializes account correctly', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final account = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user123',
      );

      final json = account.toJson();

      expect(json['displayName'], 'John Doe');
      expect(json['createdAt'], '2025-12-23T10:30:00.000');
      expect(json['spotifyUserId'], 'user123');
    });

    test('fromJson deserializes account correctly', () {
      final json = {
        'displayName': 'John Doe',
        'createdAt': '2025-12-23T10:30:00.000Z',
        'spotifyUserId': 'user123',
      };

      final account = SpotifyAccount.fromJson(json);

      expect(account.displayName, 'John Doe');
      expect(account.createdAt.year, 2025);
      expect(account.createdAt.month, 12);
      expect(account.createdAt.day, 23);
      expect(account.spotifyUserId, 'user123');
    });

    test('roundtrip serialization preserves data', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);
      final original = SpotifyAccount(
        displayName: 'John Doe',
        createdAt: createdAt,
        spotifyUserId: 'user123',
      );

      final json = original.toJson();
      final restored = SpotifyAccount.fromJson(json);

      expect(restored.displayName, original.displayName);
      expect(restored.createdAt, original.createdAt);
      expect(restored.spotifyUserId, original.spotifyUserId);
    });

    test('handles different display names', () {
      final createdAt = DateTime(2025, 12, 23, 10, 30, 0);

      final account1 = SpotifyAccount(
        displayName: 'Simple Name',
        createdAt: createdAt,
        spotifyUserId: 'user1',
      );
      final account2 = SpotifyAccount(
        displayName: 'Name with Spaces',
        createdAt: createdAt,
        spotifyUserId: 'user2',
      );
      final account3 = SpotifyAccount(
        displayName: 'Name_with-special.chars',
        createdAt: createdAt,
        spotifyUserId: 'user3',
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
        'spotifyUserId': 'user1',
      };
      final account1 = SpotifyAccount.fromJson(json1);
      expect(account1.createdAt.year, 2025);

      // ISO 8601 without Z
      final json2 = {
        'displayName': 'Jane Smith',
        'createdAt': '2025-12-23T10:30:00.000',
        'spotifyUserId': 'user2',
      };
      final account2 = SpotifyAccount.fromJson(json2);
      expect(account2.createdAt.year, 2025);
    });
  });
}
