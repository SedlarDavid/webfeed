import 'dart:io';
import 'package:test/test.dart';
import 'package:webfeed/domain/json_feed.dart';
import 'package:webfeed/util/feed_detection.dart';
import 'package:webfeed/util/json_feed_parser.dart';

void main() {
  group('JSON Feed Tests', () {
    test('should detect JSON Feed type efficiently', () {
      final jsonFeed = File('test/json/Json-1.json').readAsStringSync();
      final feedType = detectFeedTypeEfficiently(jsonFeed);
      expect(feedType, equals(FeedType.json));
    });

    test('should detect JSON Feed type with regular detection', () {
      final jsonFeed = File('test/json/Json-1.json').readAsStringSync();
      final feedType = detectFeedType(jsonFeed);
      expect(feedType, equals(FeedType.json));
    });

    test('should parse real JSON Feed (Json-1.json)', () {
      final jsonFeed = File('test/json/Json-1.json').readAsStringSync();
      final feed = JsonFeed.fromJson(jsonFeed);

      expect(feed.version, equals('https://jsonfeed.org/version/1'));
      expect(feed.title, equals('inessential'));
      expect(feed.description, contains('Brent Simmons'));
      expect(feed.homePageUrl, equals('https://inessential.com/'));
      expect(feed.feedUrl, equals('https://inessential.com/feed.json'));
      expect(
          feed.userComment, contains('This feed allows you to read the posts'));

      expect(feed.items, isNotNull);
      expect(feed.items!.length, equals(5));

      final firstItem = feed.items!.first;
      expect(firstItem.title, equals('Saturday March'));
      expect(firstItem.id,
          equals('https://inessential.com/2025/06/13/saturday-march.html'));
      expect(firstItem.url,
          equals('https://inessential.com/2025/06/13/saturday-march.html'));
      expect(
          firstItem.contentHtml,
          contains(
              'Tomorrow is <a href="https://www.nokings.org/">No Kings</a>'));
    });

    test('should parse real JSON Feed (Json-2.json)', () {
      final jsonFeed = File('test/json/Json-2.json').readAsStringSync();
      final feed = JsonFeed.fromJson(jsonFeed);

      expect(feed.version, isNotNull);
      expect(feed.items, isNotNull);
      expect(feed.items!.length, greaterThan(0));
    });

    test('should parse real JSON Feed (Json-3.json)', () {
      final jsonFeed = File('test/json/Json-3.json').readAsStringSync();
      final feed = JsonFeed.fromJson(jsonFeed);

      expect(feed.version, isNotNull);
      expect(feed.items, isNotNull);
      expect(feed.items!.length, greaterThan(0));
    });

    test('should handle minimal JSON Feed', () {
      final jsonFeed = '''
{
  "version": "https://jsonfeed.org/version/1.1",
  "items": []
}
''';

      final feed = JsonFeed.fromJson(jsonFeed);

      expect(feed.version, equals('https://jsonfeed.org/version/1.1'));
      expect(feed.title, isNull);
      expect(feed.items, isNotNull);
      expect(feed.items!.length, equals(0));
    });

    test('should parse JSON Feed with parser utility', () {
      final jsonFeed = File('test/json/Json-1.json').readAsStringSync();
      final feed = JsonFeedParser.parse(jsonFeed);
      expect(feed.title, equals('inessential'));
    });

    test('should handle parsing errors gracefully with tryParse', () {
      final invalidJson = '{"invalid": json}';

      final feed = JsonFeedParser.tryParse(invalidJson);
      expect(feed, isNull);
    });

    test('should detect likely JSON Feed content', () {
      final jsonContent = File('test/json/Json-1.json').readAsStringSync();
      final xmlContent = '<rss><channel></channel></rss>';

      expect(JsonFeedParser.isLikelyJsonFeed(jsonContent), isTrue);
      expect(JsonFeedParser.isLikelyJsonFeed(xmlContent), isFalse);
    });

    test('should extract basic metadata without full parsing', () {
      final jsonFeed = File('test/json/Json-1.json').readAsStringSync();
      final metadata = JsonFeedParser.extractBasicMetadata(jsonFeed);

      expect(metadata, isNotNull);
      expect(metadata!['title'], equals('inessential'));
      expect(metadata['description'], contains('Brent Simmons'));
      expect(metadata['itemCount'], equals(5));
    });

    test('should sanitize JSON content', () {
      final jsonWithBom =
          '\uFEFF{"version": "https://jsonfeed.org/version/1.1", "items": []}';
      final sanitized = JsonFeedParser.sanitize(jsonWithBom);

      expect(sanitized.startsWith('\uFEFF'), isFalse);
      expect(sanitized.startsWith('{'), isTrue);
    });

    test('should handle strict validation', () {
      final invalidFeed = '{"title": "Missing required fields"}';

      expect(() => JsonFeedParser.parse(invalidFeed, strict: true),
          throwsA(isA<FormatException>()));
    });

    test('should convert back to JSON', () {
      final originalJson = File('test/json/Json-1.json').readAsStringSync();
      final feed = JsonFeed.fromJson(originalJson);
      final convertedJson = feed.toJson();

      expect(convertedJson['title'], equals('inessential'));
      expect(
          convertedJson['version'], equals('https://jsonfeed.org/version/1'));
      expect(convertedJson['items'], isA<List>());
    });

    test('should handle different JSON Feed versions', () {
      final jsonFeed = File('test/json/Json-1.json').readAsStringSync();
      final feed = JsonFeed.fromJson(jsonFeed);

      // Json-1.json uses version 1, not 1.1
      expect(feed.version, equals('https://jsonfeed.org/version/1'));
      expect(feed.items!.length, equals(5));
    });

    test('should parse items with various content types', () {
      final jsonFeed = File('test/json/Json-1.json').readAsStringSync();
      final feed = JsonFeed.fromJson(jsonFeed);

      final items = feed.items!;

      // Check that items have the expected structure
      for (final item in items) {
        expect(item.id, isNotNull);
        expect(item.title, isNotNull);
        expect(item.url, isNotNull);
        expect(item.datePublished, isNotNull);
        expect(item.contentHtml, isNotNull);
      }
    });
  });
}
