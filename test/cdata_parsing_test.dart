import 'package:test/test.dart';
import 'package:webfeed/domain/rss_feed.dart';

void main() {
  group('CDATA Parsing Tests', () {
    test('Mixed CDATA and regular text handling', () {
      final xmlString = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Regular Title</title>
            <description><![CDATA[CDATA Description]]></description>
            <item>
              <title><![CDATA[CDATA Title]]></title>
              <description>Regular Description</description>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(xmlString, withArticles: true);
      final efficientFeed =
          RssFeed.parseEfficiently(xmlString, withArticles: true);

      // Verify mixed content is handled correctly
      expect(regularFeed.title, equals('Regular Title'));
      expect(efficientFeed.title, equals('Regular Title'));
      expect(regularFeed.title, equals(efficientFeed.title));

      expect(regularFeed.description, equals('CDATA Description'));
      expect(efficientFeed.description, equals('CDATA Description'));
      expect(regularFeed.description, equals(efficientFeed.description));

      expect(regularFeed.items![0].title, equals('CDATA Title'));
      expect(efficientFeed.items![0].title, equals('CDATA Title'));
      expect(
          regularFeed.items![0].title, equals(efficientFeed.items![0].title));

      expect(regularFeed.items![0].description, equals('Regular Description'));
      expect(
          efficientFeed.items![0].description, equals('Regular Description'));
      expect(regularFeed.items![0].description,
          equals(efficientFeed.items![0].description));
    });

    test('Empty CDATA sections handling', () {
      final xmlString = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title><![CDATA[]]></title>
            <description><![CDATA[   ]]></description>
            <item>
              <title><![CDATA[]]></title>
              <description><![CDATA[   ]]></description>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(xmlString, withArticles: true);
      final efficientFeed =
          RssFeed.parseEfficiently(xmlString, withArticles: true);

      // Verify empty CDATA sections are handled consistently
      expect(regularFeed.title, equals(''));
      expect(efficientFeed.title, equals(''));
      expect(regularFeed.title, equals(efficientFeed.title));

      expect(regularFeed.description, equals(''));
      expect(efficientFeed.description, equals(''));
      expect(regularFeed.description, equals(efficientFeed.description));

      expect(regularFeed.items![0].title, equals(''));
      expect(efficientFeed.items![0].title, equals(''));
      expect(
          regularFeed.items![0].title, equals(efficientFeed.items![0].title));

      expect(regularFeed.items![0].description, equals(''));
      expect(efficientFeed.items![0].description, equals(''));
      expect(regularFeed.items![0].description,
          equals(efficientFeed.items![0].description));
    });
  });
}
