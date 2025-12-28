import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/tunein_api_service.dart';

@GenerateMocks([http.Client])
import 'tunein_api_service_test.mocks.dart';

void main() {
  group('TuneInApiService', () {
    late MockClient mockClient;
    late TuneInApiService service;

    setUp(() {
      mockClient = MockClient();
      service = TuneInApiService(httpClient: mockClient);
    });

    group('searchStations', () {
      test('should return list of stations on successful search', () async {
        const query = 'radio potsdam';
        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="1">
  <head>
    <title>Search Results: radio potsdam</title>
    <status>200</status>
  </head>
  <body>
    <outline type="audio" text="Radio Potsdam" URL="http://opml.radiotime.com/Tune.ashx?id=s288368"
             bitrate="192" reliability="100" guide_id="s288368"
             subtext="WILLKOMMEN ZUHAUSE" genre_id="g3" formats="mp3"
             item="station" image="http://cdn-profiles.tunein.com/s288368/images/logoq.png"
             now_playing_id="s288368" preset_id="s288368"/>
    <outline type="link" text="Some Podcast" URL="http://opml.radiotime.com/Tune.ashx?id=p123"
             guide_id="p123" item="show"/>
    <outline type="audio" text="Test Station" guide_id="s999" item="station" bitrate="128" reliability="95"/>
  </body>
</opml>''';

        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/search.ashx?query=radio%20potsdam'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer((_) async => response);

        final result = await service.searchStations(query);

        expect(result.length, 2); // Only stations, not podcasts
        expect(result[0].guideId, 's288368');
        expect(result[0].text, 'Radio Potsdam');
        expect(result[0].subtext, 'WILLKOMMEN ZUHAUSE');
        expect(result[0].bitrate, '192');
        expect(result[0].reliability, '100');
        expect(result[1].guideId, 's999');
        expect(result[1].text, 'Test Station');

        verify(mockClient.get(
          Uri.parse('https://opml.radiotime.com/search.ashx?query=radio%20potsdam'),
          headers: {'Accept': 'text/xml'},
        )).called(1);
      });

      test('should return empty list for empty query', () async {
        final result = await service.searchStations('');

        expect(result, isEmpty);
        verifyNever(mockClient.get(any, headers: anyNamed('headers')));
      });

      test('should return empty list for whitespace query', () async {
        final result = await service.searchStations('   ');

        expect(result, isEmpty);
        verifyNever(mockClient.get(any, headers: anyNamed('headers')));
      });

      test('should throw exception on non-200 status code', () async {
        const query = 'test';
        final response = http.Response('Not Found', 404);

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/search.ashx?query=test'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer((_) async => response);

        expect(
          () => service.searchStations(query),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on malformed XML', () async {
        const query = 'test';
        final response = http.Response('not valid xml', 200);

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/search.ashx?query=test'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer((_) async => response);

        expect(
          () => service.searchStations(query),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        const query = 'test';

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/search.ashx?query=test'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer(
          (_) async => Future.delayed(
            const Duration(seconds: 11),
            () => http.Response('{}', 200),
          ),
        );

        expect(
          () => service.searchStations(query),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getStationDetails', () {
      test('should return station details on successful fetch', () async {
        const stationId = 's288368';
        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="1">
  <head>
    <status>200</status>
  </head>
  <body>
    <outline type="object" text="Radio Potsdam">
      <station>
        <guide_id>s288368</guide_id>
        <name>Radio Potsdam</name>
        <slogan>WILLKOMMEN ZUHAUSE</slogan>
        <logo>https://cdn-profiles.tunein.com/s288368/images/logoq.png</logo>
        <description>Das Radio fuer Potsdam</description>
        <url>http://www.radio-potsdam.de</url>
        <location>Germany</location>
        <genre_name>Adult Hits</genre_name>
        <content_classification>music</content_classification>
        <is_family_content>false</is_family_content>
        <is_mature_content>false</is_mature_content>
      </station>
    </outline>
  </body>
</opml>''';

        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/describe.ashx?id=s288368'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer((_) async => response);

        final result = await service.getStationDetails(stationId);

        expect(result.guideId, 's288368');
        expect(result.name, 'Radio Potsdam');
        expect(result.slogan, 'WILLKOMMEN ZUHAUSE');
        expect(result.logo, 'https://cdn-profiles.tunein.com/s288368/images/logoq.png');
        expect(result.description, 'Das Radio fuer Potsdam');
        expect(result.url, 'http://www.radio-potsdam.de');
        expect(result.location, 'Germany');
        expect(result.genreName, 'Adult Hits');
        expect(result.contentClassification, 'music');
        expect(result.isFamilyContent, false);
        expect(result.isMatureContent, false);

        verify(mockClient.get(
          Uri.parse('https://opml.radiotime.com/describe.ashx?id=s288368'),
          headers: {'Accept': 'text/xml'},
        )).called(1);
      });

      test('should throw ArgumentError for empty station ID', () async {
        expect(
          () => service.getStationDetails(''),
          throwsA(isA<ArgumentError>()),
        );

        verifyNever(mockClient.get(any, headers: anyNamed('headers')));
      });

      test('should throw ArgumentError for whitespace station ID', () async {
        expect(
          () => service.getStationDetails('   '),
          throwsA(isA<ArgumentError>()),
        );

        verifyNever(mockClient.get(any, headers: anyNamed('headers')));
      });

      test('should throw exception on non-200 status code', () async {
        const stationId = 's12345';
        final response = http.Response('Not Found', 404);

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/describe.ashx?id=s12345'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer((_) async => response);

        expect(
          () => service.getStationDetails(stationId),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when station element not found', () async {
        const stationId = 's12345';
        const responseBody = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="1">
  <head>
    <status>200</status>
  </head>
  <body>
    <outline type="object" text="Test"></outline>
  </body>
</opml>''';

        final response = http.Response(responseBody, 200);

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/describe.ashx?id=s12345'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer((_) async => response);

        expect(
          () => service.getStationDetails(stationId),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on malformed XML', () async {
        const stationId = 's12345';
        final response = http.Response('not valid xml', 200);

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/describe.ashx?id=s12345'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer((_) async => response);

        expect(
          () => service.getStationDetails(stationId),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception on timeout', () async {
        const stationId = 's12345';

        when(mockClient.get(
          Uri.parse('https://opml.radiotime.com/describe.ashx?id=s12345'),
          headers: {'Accept': 'text/xml'},
        )).thenAnswer(
          (_) async => Future.delayed(
            const Duration(seconds: 11),
            () => http.Response('{}', 200),
          ),
        );

        expect(
          () => service.getStationDetails(stationId),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
