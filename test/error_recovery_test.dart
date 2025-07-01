import 'package:test/test.dart';
import 'package:webfeed/webfeed.dart';

void main() {
  group('Error recovery tests', () {
    test('Handle missing fields gracefully', () {
      final xmlString = '''
        <rss version="2.0">
          <channel>
            <title>Test Feed</title>
            <link>https://example.com</link>
            <description>Test description</description>
            <item>
              <title>Complete item</title>
              <link>https://example.com/complete</link>
              <description>This item has all standard fields</description>
              <pubDate>Mon, 26 Mar 2018 14:00:00 GMT</pubDate>
            </item>
            <item>
              <!-- Item with missing fields -->
              <title>Partial item</title>
              <!-- No link -->
              <!-- No description -->
              <!-- No pubDate -->
            </item>
            <item>
              <!-- Item with only link -->
              <link>https://example.com/link-only</link>
            </item>
          </channel>
        </rss>
      ''';

      // Should parse successfully despite missing fields
      final feed = RssFeed.parse(xmlString);

      // The feed itself should be parsed correctly
      expect(feed.title, 'Test Feed');
      expect(feed.link, 'https://example.com');
      expect(feed.description, 'Test description');

      // All items should be parsed
      expect(feed.items, isNotNull);
      expect(feed.items!.length, 3);

      // Check complete item
      expect(feed.items![0].title, 'Complete item');
      expect(feed.items![0].link, 'https://example.com/complete');
      expect(feed.items![0].description, 'This item has all standard fields');
      expect(feed.items![0].pubDate, isNotNull);

      // Check partial item
      expect(feed.items![1].title, 'Partial item');
      expect(feed.items![1].link, null);
      expect(feed.items![1].description, null);
      expect(feed.items![1].pubDate, null);

      // Check link-only item
      expect(feed.items![2].title, null);
      expect(feed.items![2].link, 'https://example.com/link-only');
    });

    test('Handle namespace prefixes in element names', () {
      final xmlString = '''
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
          <channel>
            <title>Test Feed</title>
            <dc:language>en-us</dc:language>
            <item>
              <title>Test Item</title>
              <dc:creator>John Doe</dc:creator>
            </item>
          </channel>
        </rss>
      ''';

      final feed = RssFeed.parse(xmlString);

      // Namespace elements should be correctly parsed
      expect(feed.dc, isNotNull);
      expect(feed.dc!.language, 'en-us');

      // Item namespace elements should be correctly parsed
      expect(feed.items![0].dc, isNotNull);
      expect(feed.items![0].dc!.creator, 'John Doe');
    });

    test('Handle different date formats', () {
      // Use separate XML strings to test each date format individually

      // RFC 822 date
      final rfc822Xml = '''
        <rss version="2.0">
          <channel>
            <title>RFC 822 Date Test</title>
            <item>
              <title>RFC 822 date</title>
              <pubDate>Mon, 26 Mar 2018 14:00:00 GMT</pubDate>
            </item>
          </channel>
        </rss>
      ''';

      final rfc822Feed = RssFeed.parse(rfc822Xml);
      expect(rfc822Feed.items, isNotNull);
      expect(rfc822Feed.items!.length, 1);
      expect(rfc822Feed.items![0].pubDate, isNotNull);
      expect(rfc822Feed.items![0].pubDate!.year, 2018);
      expect(rfc822Feed.items![0].pubDate!.month, 3);
      expect(rfc822Feed.items![0].pubDate!.day, 26);

      // ISO 8601 date
      final isoXml = '''
        <rss version="2.0">
          <channel>
            <title>ISO 8601 Date Test</title>
            <item>
              <title>ISO 8601 date</title>
              <pubDate>2018-03-26T14:00:00Z</pubDate>
            </item>
          </channel>
        </rss>
      ''';

      final isoFeed = RssFeed.parse(isoXml);
      expect(isoFeed.items, isNotNull);
      expect(isoFeed.items!.length, 1);
      expect(isoFeed.items![0].pubDate, isNotNull);
      expect(isoFeed.items![0].pubDate!.year, 2018);
      expect(isoFeed.items![0].pubDate!.month, 3);
      expect(isoFeed.items![0].pubDate!.day, 26);

      // Date with timezone abbreviation
      final tzXml = '''
        <rss version="2.0">
          <channel>
            <title>Timezone Abbreviation Test</title>
            <item>
              <title>Date with timezone abbreviation</title>
              <pubDate>Mon, 26 Mar 2018 14:00:00 PDT</pubDate>
            </item>
          </channel>
        </rss>
      ''';

      final tzFeed = RssFeed.parse(tzXml);
      expect(tzFeed.items, isNotNull);
      expect(tzFeed.items!.length, 1);
      expect(tzFeed.items![0].pubDate, isNotNull);
      expect(tzFeed.items![0].pubDate!.year, 2018);
      expect(tzFeed.items![0].pubDate!.month, 3);
      expect(tzFeed.items![0].pubDate!.day, 26);
    });

    test('Extract content with different types of media', () {
      final xmlString = '''
        <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
          <channel>
            <title>Content Test Feed</title>
            <item>
              <title>Content Item</title>
              <content:encoded>
                <![CDATA[
                  <p>This is a test paragraph.</p>
                  <img src="https://example.com/image1.jpg" alt="Test image 1" />
                  <video controls>
                    <source src="https://example.com/video1.mp4" type="video/mp4">
                  </video>
                  <iframe src="https://www.youtube.com/embed/abc123"></iframe>
                ]]>
              </content:encoded>
            </item>
          </channel>
        </rss>
      ''';

      final feed = RssFeed.parse(xmlString);

      // Content should be correctly parsed
      expect(feed.items![0].content, isNotNull);

      // Images should be extracted
      expect(feed.items![0].content!.images.length, 1);
      expect(feed.items![0].content!.images.first,
          'https://example.com/image1.jpg');

      // Videos should be extracted
      expect(feed.items![0].content!.videos.length, 1);
      expect(feed.items![0].content!.videos.first,
          'https://example.com/video1.mp4');

      // Iframes should be extracted
      expect(feed.items![0].content!.iframes.length, 1);
      expect(feed.items![0].content!.iframes.first,
          'https://www.youtube.com/embed/abc123');

      // Plain text should be generated
      expect(feed.items![0].content!.plainText, isNotNull);
      expect(feed.items![0].content!.plainText,
          contains('This is a test paragraph.'));
    });
  });
}
