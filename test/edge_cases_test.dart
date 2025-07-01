import 'package:test/test.dart';
import 'package:webfeed/domain/atom_feed.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:webfeed/util/feed_detection.dart';

void main() {
  group('Edge Cases - RSS Feeds', () {
    test('RSS with malformed XML should throw error', () {
      const malformedXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Test Feed</title>
            <description>Test Description</description>
            <item>
              <title>Item 1</title>
              <description>Description 1</description>
            </item>
            <item>
              <title>Item 2</title>
              <description>Description 2</description>
            </item>
          </channel>
        </rss>
      ''';

      // Should parse successfully
      final regularFeed = RssFeed.parse(malformedXml);
      final efficientFeed = RssFeed.parseEfficiently(malformedXml);

      expect(regularFeed.title, equals('Test Feed'));
      expect(efficientFeed.title, equals('Test Feed'));
      expect(regularFeed.items!.length, equals(2));
      expect(efficientFeed.items!.length, equals(2));
    });

    test('RSS with unclosed tags should throw error', () {
      const unclosedXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Test Feed
            <description>Test Description
            <item>
              <title>Item 1
            </item>
          </channel>
        </rss>
      ''';

      expect(() => RssFeed.parse(unclosedXml), throwsA(isA<ArgumentError>()));
      expect(() => RssFeed.parseEfficiently(unclosedXml),
          throwsA(isA<ArgumentError>()));
    });

    test('RSS with empty feed should handle gracefully', () {
      const emptyXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(emptyXml);
      final efficientFeed = RssFeed.parseEfficiently(emptyXml);

      expect(regularFeed.title, isNull);
      expect(efficientFeed.title, isNull);
      expect(regularFeed.items, isNull);
      expect(efficientFeed.items, isNull);
    });

    test('RSS with only items (no channel metadata) should work', () {
      const itemsOnlyXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>Item 1</title>
              <description>Description 1</description>
            </item>
            <item>
              <title>Item 2</title>
              <description>Description 2</description>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(itemsOnlyXml);
      final efficientFeed = RssFeed.parseEfficiently(itemsOnlyXml);

      expect(regularFeed.title, isNull);
      expect(efficientFeed.title, isNull);
      expect(regularFeed.items!.length, equals(2));
      expect(efficientFeed.items!.length, equals(2));
    });

    test('RSS with deeply nested CDATA should parse correctly', () {
      const nestedCdataXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title><![CDATA[<![CDATA[Nested CDATA]]>]]></title>
            <description><![CDATA[<![CDATA[<![CDATA[Triple nested]]>]]>]]></description>
            <item>
              <title><![CDATA[<![CDATA[Item with nested CDATA]]>]]></title>
              <description><![CDATA[<![CDATA[<![CDATA[Complex nesting]]>]]>]]></description>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(nestedCdataXml);
      final efficientFeed = RssFeed.parseEfficiently(nestedCdataXml);

      expect(regularFeed.title, equals('<![CDATA[Nested CDATA]]>'));
      expect(efficientFeed.title, equals('<![CDATA[Nested CDATA]]>'));
      expect(regularFeed.description,
          equals('<![CDATA[<![CDATA[Triple nested]]>]]>'));
      expect(efficientFeed.description,
          equals('<![CDATA[<![CDATA[Triple nested]]>]]>'));
    });

    test('RSS with HTML entities in various fields should decode correctly',
        () {
      const htmlEntitiesXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Title with &amp; &lt; &gt; &quot; &apos;</title>
            <description>Description with &amp; &lt; &gt; &quot; &apos;</description>
            <item>
              <title>Item with &amp; &lt; &gt; &quot; &apos;</title>
              <description>Item description with &amp; &lt; &gt; &quot; &apos;</description>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(htmlEntitiesXml);
      final efficientFeed = RssFeed.parseEfficiently(htmlEntitiesXml);

      expect(regularFeed.title, equals('Title with & < > " \''));
      expect(efficientFeed.title, equals('Title with & < > " \''));
      expect(regularFeed.description, equals('Description with & < > " \''));
      expect(efficientFeed.description, equals('Description with & < > " \''));
      expect(regularFeed.items![0].title, equals('Item with & < > " \''));
      expect(efficientFeed.items![0].title, equals('Item with & < > " \''));
    });

    test('RSS with very large content should parse without issues', () {
      // Create a large RSS feed
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<rss version="2.0">');
      buffer.writeln('<channel>');
      buffer.writeln('<title>Large Test Feed</title>');
      buffer.writeln('<description>This is a large test feed</description>');

      // Add many items with large content
      for (var i = 1; i <= 100; i++) {
        buffer.writeln('<item>');
        buffer.writeln('<title>Item $i</title>');
        buffer.writeln(
            '<description>${"A" * 1000}</description>'); // 1000 character description
        buffer.writeln('</item>');
      }

      buffer.writeln('</channel>');
      buffer.writeln('</rss>');

      final largeXml = buffer.toString();

      final regularFeed = RssFeed.parse(largeXml);
      final efficientFeed = RssFeed.parseEfficiently(largeXml);

      expect(regularFeed.title, equals('Large Test Feed'));
      expect(efficientFeed.title, equals('Large Test Feed'));
      expect(regularFeed.items!.length, equals(100));
      expect(efficientFeed.items!.length, equals(100));
    });

    test('RSS with mixed encoding declarations should handle correctly', () {
      const mixedEncodingXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <?xml version="1.0" encoding="ISO-8859-1"?>
        <rss version="2.0">
          <channel>
            <title>Test Feed</title>
            <description>Test Description</description>
            <item>
              <title>Item 1</title>
              <description>Description 1</description>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(mixedEncodingXml);
      final efficientFeed = RssFeed.parseEfficiently(mixedEncodingXml);

      expect(regularFeed.title, equals('Test Feed'));
      expect(efficientFeed.title, equals('Test Feed'));
    });

    test('RSS with namespace declarations should parse correctly', () {
      const namespaceXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/">
          <channel>
            <title>Test Feed</title>
            <description>Test Description</description>
            <dc:creator>Test Author</dc:creator>
            <item>
              <title>Item 1</title>
              <description>Description 1</description>
              <dc:date>2024-01-01T12:00:00Z</dc:date>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(namespaceXml);
      final efficientFeed = RssFeed.parseEfficiently(namespaceXml);

      expect(regularFeed.title, equals('Test Feed'));
      expect(efficientFeed.title, equals('Test Feed'));
      expect(regularFeed.items!.length, equals(1));
      expect(efficientFeed.items!.length, equals(1));
    });
  });

  group('Edge Cases - Atom Feeds', () {
    test('Atom with malformed XML should throw error', () {
      const malformedXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Test Feed</title>
          <entry>
            <title>Entry 1</title>
            <content>Content 1</content>
          </entry>
          <entry>
            <title>Entry 2</title>
            <content>Content 2</content>
          </entry>
        </feed>
      ''';

      // Should parse successfully
      final regularFeed = AtomFeed.parse(malformedXml);
      final efficientFeed = AtomFeed.parseEfficiently(malformedXml);

      expect(regularFeed.title, equals('Test Feed'));
      expect(efficientFeed.title, equals('Test Feed'));
      expect(regularFeed.items!.length, equals(2));
      expect(efficientFeed.items!.length, equals(2));
    });

    test('Atom with unclosed tags should throw error', () {
      const unclosedXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Test Feed
          <entry>
            <title>Entry 1
            <content>Content 1
          </entry>
        </feed>
      ''';

      expect(() => AtomFeed.parse(unclosedXml), throwsA(isA<ArgumentError>()));
      expect(() => AtomFeed.parseEfficiently(unclosedXml),
          throwsA(isA<ArgumentError>()));
    });

    test('Atom with empty feed should handle gracefully', () {
      const emptyXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
        </feed>
      ''';

      final regularFeed = AtomFeed.parse(emptyXml);
      final efficientFeed = AtomFeed.parseEfficiently(emptyXml);

      expect(regularFeed.title, isNull);
      expect(efficientFeed.title, isNull);
      expect(regularFeed.items, isNull);
      expect(efficientFeed.items, isNull);
    });

    test('Atom with only entries (no feed metadata) should work', () {
      const entriesOnlyXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <title>Entry 1</title>
            <content>Content 1</content>
          </entry>
          <entry>
            <title>Entry 2</title>
            <content>Content 2</content>
          </entry>
        </feed>
      ''';

      final regularFeed = AtomFeed.parse(entriesOnlyXml);
      final efficientFeed = AtomFeed.parseEfficiently(entriesOnlyXml);

      expect(regularFeed.title, isNull);
      expect(efficientFeed.title, isNull);
      expect(regularFeed.items!.length, equals(2));
      expect(efficientFeed.items!.length, equals(2));
    });

    test('Atom with deeply nested CDATA should parse correctly', () {
      const nestedCdataXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title><![CDATA[<![CDATA[Nested CDATA]]>]]></title>
          <subtitle><![CDATA[<![CDATA[<![CDATA[Triple nested]]>]]>]]></subtitle>
          <entry>
            <title><![CDATA[<![CDATA[Entry with nested CDATA]]>]]></title>
            <content><![CDATA[<![CDATA[<![CDATA[Complex nesting]]>]]>]]></content>
          </entry>
        </feed>
      ''';

      final regularFeed = AtomFeed.parse(nestedCdataXml);
      final efficientFeed = AtomFeed.parseEfficiently(nestedCdataXml);

      expect(regularFeed.title, equals('<![CDATA[Nested CDATA]]>'));
      expect(efficientFeed.title, equals('<![CDATA[Nested CDATA]]>'));
      expect(regularFeed.subtitle,
          equals('<![CDATA[<![CDATA[Triple nested]]>]]>'));
      expect(efficientFeed.subtitle,
          equals('<![CDATA[<![CDATA[Triple nested]]>]]>'));
    });

    test('Atom with HTML entities in various fields should decode correctly',
        () {
      const htmlEntitiesXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Title with &amp; &lt; &gt; &quot; &apos;</title>
          <subtitle>Subtitle with &amp; &lt; &gt; &quot; &apos;</subtitle>
          <entry>
            <title>Entry with &amp; &lt; &gt; &quot; &apos;</title>
            <content>Content with &amp; &lt; &gt; &quot; &apos;</content>
          </entry>
        </feed>
      ''';

      final regularFeed = AtomFeed.parse(htmlEntitiesXml);
      final efficientFeed = AtomFeed.parseEfficiently(htmlEntitiesXml);

      expect(regularFeed.title, equals('Title with & < > " \''));
      expect(efficientFeed.title, equals('Title with & < > " \''));
      expect(regularFeed.subtitle, equals('Subtitle with & < > " \''));
      expect(efficientFeed.subtitle, equals('Subtitle with & < > " \''));
      expect(regularFeed.items![0].title, equals('Entry with & < > " \''));
      expect(efficientFeed.items![0].title, equals('Entry with & < > " \''));
    });

    test('Atom with very large content should parse without issues', () {
      // Create a large Atom feed
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<feed xmlns="http://www.w3.org/2005/Atom">');
      buffer.writeln('<title>Large Test Atom Feed</title>');
      buffer.writeln('<subtitle>This is a large test atom feed</subtitle>');

      // Add many entries with large content
      for (var i = 1; i <= 100; i++) {
        buffer.writeln('<entry>');
        buffer.writeln('<title>Entry $i</title>');
        buffer.writeln(
            '<content>${"A" * 1000}</content>'); // 1000 character content
        buffer.writeln('</entry>');
      }

      buffer.writeln('</feed>');

      final largeXml = buffer.toString();

      final regularFeed = AtomFeed.parse(largeXml);
      final efficientFeed = AtomFeed.parseEfficiently(largeXml);

      expect(regularFeed.title, equals('Large Test Atom Feed'));
      expect(efficientFeed.title, equals('Large Test Atom Feed'));
      expect(regularFeed.items!.length, equals(100));
      expect(efficientFeed.items!.length, equals(100));
    });

    test('Atom with complex namespace declarations should parse correctly', () {
      const complexNamespaceXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:media="http://search.yahoo.com/mrss/">
          <title>Test Atom Feed</title>
          <subtitle>Test Subtitle</subtitle>
          <dc:creator>Test Author</dc:creator>
          <entry>
            <title>Entry 1</title>
            <content>Content 1</content>
            <dc:date>2024-01-01T12:00:00Z</dc:date>
          </entry>
        </feed>
      ''';

      final regularFeed = AtomFeed.parse(complexNamespaceXml);
      final efficientFeed = AtomFeed.parseEfficiently(complexNamespaceXml);

      expect(regularFeed.title, equals('Test Atom Feed'));
      expect(efficientFeed.title, equals('Test Atom Feed'));
      expect(regularFeed.items!.length, equals(1));
      expect(efficientFeed.items!.length, equals(1));
    });
  });

  group('Edge Cases - Feed Detection', () {
    test('Feed detection with empty string should return unknown', () {
      expect(detectFeedType(''), equals(FeedType.unknown));
      expect(detectFeedTypeEfficiently(''), equals(FeedType.unknown));
    });

    test('Feed detection with whitespace only should return unknown', () {
      expect(detectFeedType('   \n\t  '), equals(FeedType.unknown));
      expect(detectFeedTypeEfficiently('   \n\t  '), equals(FeedType.unknown));
    });

    test('Feed detection with invalid XML should return unknown', () {
      expect(detectFeedType('This is not XML'), equals(FeedType.unknown));
      expect(detectFeedTypeEfficiently('This is not XML'),
          equals(FeedType.unknown));
    });

    test('Feed detection with malformed XML should return unknown', () {
      expect(detectFeedType('<rss><channel></rss>'), equals(FeedType.unknown));
      expect(detectFeedTypeEfficiently('<rss><channel></rss>'),
          equals(FeedType.unknown));
    });

    test('Feed detection with very large XML should work', () {
      final largeXml =
          '<?xml version="1.0"?><rss version="2.0">${"<channel><title>Test</title></channel>" * 1000}</rss>';

      expect(detectFeedType(largeXml), equals(FeedType.rss));
      expect(detectFeedTypeEfficiently(largeXml), equals(FeedType.rss));
    });

    test('Feed detection with mixed case should work', () {
      expect(detectFeedType('<RSS></RSS>'), equals(FeedType.rss));
      expect(detectFeedTypeEfficiently('<RSS></RSS>'), equals(FeedType.rss));

      expect(detectFeedType('<FEED></FEED>'), equals(FeedType.atom));
      expect(detectFeedTypeEfficiently('<FEED></FEED>'), equals(FeedType.atom));
    });
  });

  group('Edge Cases - Performance and Memory', () {
    test('Parsing with withArticles=false should be much faster', () {
      // Create a large feed
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<rss version="2.0">');
      buffer.writeln('<channel>');
      buffer.writeln('<title>Performance Test Feed</title>');
      buffer.writeln('<description>Test Description</description>');

      // Add many items
      for (var i = 1; i <= 1000; i++) {
        buffer.writeln('<item>');
        buffer.writeln('<title>Item $i</title>');
        buffer.writeln(
            '<description>${"Description for item $i " * 10}</description>');
        buffer.writeln('</item>');
      }

      buffer.writeln('</channel>');
      buffer.writeln('</rss>');

      final largeXml = buffer.toString();

      // Test with articles
      final startWithArticles = DateTime.now();
      final feedWithArticles = RssFeed.parse(largeXml, withArticles: true);
      final endWithArticles = DateTime.now();
      final durationWithArticles =
          endWithArticles.difference(startWithArticles);

      // Test without articles
      final startWithoutArticles = DateTime.now();
      final feedWithoutArticles = RssFeed.parse(largeXml, withArticles: false);
      final endWithoutArticles = DateTime.now();
      final durationWithoutArticles =
          endWithoutArticles.difference(startWithoutArticles);

      expect(feedWithArticles.items!.length, equals(1000));
      expect(feedWithoutArticles.items, isNull);
      expect(durationWithoutArticles.inMicroseconds,
          lessThan(durationWithArticles.inMicroseconds));
    });

    test(
        'Efficient parsing should handle very large feeds without memory issues',
        () {
      // Create a very large feed
      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<rss version="2.0">');
      buffer.writeln('<channel>');
      buffer.writeln('<title>Very Large Test Feed</title>');
      buffer
          .writeln('<description>This is a very large test feed</description>');

      // Add many items with large content
      for (var i = 1; i <= 5000; i++) {
        buffer.writeln('<item>');
        buffer.writeln('<title>Item $i</title>');
        buffer.writeln(
            '<description>${"Large description for item $i " * 50}</description>');
        buffer.writeln('</item>');
      }

      buffer.writeln('</channel>');
      buffer.writeln('</rss>');

      final veryLargeXml = buffer.toString();

      // Should parse without throwing memory errors
      final regularFeed = RssFeed.parse(veryLargeXml, withArticles: false);
      final efficientFeed =
          RssFeed.parseEfficiently(veryLargeXml, withArticles: false);

      expect(regularFeed.title, equals('Very Large Test Feed'));
      expect(efficientFeed.title, equals('Very Large Test Feed'));
      expect(regularFeed.items, isNull);
      expect(efficientFeed.items, isNull);
    });
  });

  group('Edge Cases - Error Recovery', () {
    test('RSS with missing required elements should handle gracefully', () {
      const minimalXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>Item 1</title>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(minimalXml);
      final efficientFeed = RssFeed.parseEfficiently(minimalXml);

      expect(regularFeed.title, isNull);
      expect(efficientFeed.title, isNull);
      expect(regularFeed.items!.length, equals(1));
      expect(efficientFeed.items!.length, equals(1));
      expect(regularFeed.items![0].title, equals('Item 1'));
      expect(efficientFeed.items![0].title, equals('Item 1'));
    });

    test('Atom with missing required elements should handle gracefully', () {
      const minimalXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <title>Entry 1</title>
          </entry>
        </feed>
      ''';

      final regularFeed = AtomFeed.parse(minimalXml);
      final efficientFeed = AtomFeed.parseEfficiently(minimalXml);

      expect(regularFeed.title, isNull);
      expect(efficientFeed.title, isNull);
      expect(regularFeed.items!.length, equals(1));
      expect(efficientFeed.items!.length, equals(1));
      expect(regularFeed.items![0].title, equals('Entry 1'));
      expect(efficientFeed.items![0].title, equals('Entry 1'));
    });

    test('RSS with malformed items should skip them gracefully', () {
      const malformedItemsXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Test Feed</title>
            <item>
              <title>Valid Item 1</title>
              <description>Valid Description</description>
            </item>
            <item>
              <title>Valid Item 2</title>
              <description>Valid Description</description>
            </item>
          </channel>
        </rss>
      ''';

      final regularFeed = RssFeed.parse(malformedItemsXml);
      final efficientFeed = RssFeed.parseEfficiently(malformedItemsXml);

      expect(regularFeed.title, equals('Test Feed'));
      expect(efficientFeed.title, equals('Test Feed'));
      expect(regularFeed.items!.length, equals(2));
      expect(efficientFeed.items!.length, equals(2));
    });
  });
}
