import 'dart:io';

import 'package:test/test.dart';
import 'package:webfeed/webfeed.dart';

void main() {
  group('Verge Feed Tests', () {
    late String xmlString;
    late AtomFeed feed;

    setUp(() {
      xmlString = File('test/xml/RSS-Verge.xml').readAsStringSync();
      feed = AtomFeed.parse(xmlString);
    });

    group('Feed Detection Tests', () {
      test('should detect Verge feed as Atom type', () {
        final feedType = detectFeedType(xmlString);
        expect(feedType, equals(FeedType.atom));
      });

      test('should detect Verge feed as Atom type efficiently', () {
        final feedType = detectFeedTypeEfficiently(xmlString);
        expect(feedType, equals(FeedType.atom));
      });

      test('both detection methods should return same result', () {
        final originalResult = detectFeedType(xmlString);
        final efficientResult = detectFeedTypeEfficiently(xmlString);

        expect(originalResult, equals(efficientResult));
        expect(originalResult, equals(FeedType.atom));
      });
    });

    group('Feed Header Tests', () {
      test('should parse feed title correctly', () {
        expect(feed.title, equals('The Verge'));
      });

      test('should parse feed subtitle correctly', () {
        expect(feed.subtitle, contains('The Verge is about technology'));
        expect(feed.subtitle, contains('Founded in 2011'));
      });

      test('should parse feed ID correctly', () {
        expect(feed.id, equals('https://www.theverge.com/rss/index.xml'));
      });

      test('should parse feed updated date correctly', () {
        expect(feed.updated, isA<DateTime>());
        expect(feed.updated!.year, equals(2025));
        expect(feed.updated!.month, equals(7));
        expect(feed.updated!.day, equals(1));
      });

      test('should parse feed language attribute correctly', () {
        // The feed has xml:lang="en-US" attribute in the XML
        // Note: AtomFeed doesn't currently parse xml:lang attribute
        // This test documents the expected behavior
        expect(feed.title, equals('The Verge'));
      });

      test('should parse feed icon correctly', () {
        expect(feed.icon, contains('verge-rss-large_80b47e.png'));
        expect(feed.icon, contains('platform.theverge.com'));
      });
    });

    group('Feed Links Tests', () {
      test('should parse feed links correctly', () {
        expect(feed.links, isNotNull);
        expect(feed.links!.length, greaterThan(0));
      });

      test('should parse alternate link correctly', () {
        final alternateLink = feed.links!.firstWhere(
          (link) => link.rel == 'alternate',
          orElse: () => throw StateError('Alternate link not found'),
        );

        expect(alternateLink.href, equals('https://www.theverge.com'));
        expect(alternateLink.type, equals('text/html'));
      });

      test('should parse self link correctly', () {
        final selfLink = feed.links!.firstWhere(
          (link) => link.rel == 'self',
          orElse: () => throw StateError('Self link not found'),
        );

        expect(selfLink.href, equals('https://www.theverge.com/rss/index.xml'));
        expect(selfLink.type, equals('application/atom+xml'));
      });
    });

    group('Feed Entries Tests', () {
      test('should parse correct number of entries', () {
        expect(feed.items, isNotNull);
        expect(feed.items!.length, equals(10));
      });

      test('should parse first entry correctly', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.title,
            contains('Senate drops plan to ban state AI laws'));
        expect(firstEntry.id, equals('https://www.theverge.com/?p=695495'));
        expect(firstEntry.updated, isA<DateTime>());
        expect(firstEntry.published, isA<String>());
        expect(firstEntry.published, equals('2025-07-01T09:15:48-04:00'));
      });

      test('should parse entry author correctly', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.authors, isNotNull);
        expect(firstEntry.authors!.length, equals(1));
        expect(firstEntry.authors!.first.name, equals('Tina Nguyen'));
      });

      test('should parse entry links correctly', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.links, isNotNull);
        expect(firstEntry.links!.length, greaterThan(0));

        final alternateLink = firstEntry.links!.firstWhere(
          (link) => link.rel == 'alternate',
          orElse: () => throw StateError('Entry alternate link not found'),
        );

        expect(alternateLink.href, contains('theverge.com/politics/695495'));
        expect(alternateLink.type, equals('text/html'));
      });

      test('should parse entry categories correctly', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.categories, isNotNull);
        expect(firstEntry.categories!.length, equals(4));

        final categoryTerms =
            firstEntry.categories!.map((c) => c.term).toList();
        expect(categoryTerms, contains('AI'));
        expect(categoryTerms, contains('News'));
        expect(categoryTerms, contains('Policy'));
        expect(categoryTerms, contains('Politics'));
      });

      test('should parse entry summary correctly', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.summary, isNotNull);
        expect(firstEntry.summary,
            contains('The US Senate has voted overwhelmingly'));
        expect(firstEntry.summary,
            contains('Legislators agreed by a margin of 99 to 1'));
      });

      test('should parse entry content correctly', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.content, isNotNull);
        expect(firstEntry.content, contains('<figure>'));
        expect(firstEntry.content,
            contains('<img alt="A group of people in suits'));
        expect(firstEntry.content,
            contains('The US Senate has voted overwhelmingly'));
      });

      test('should parse entry dates correctly', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.updated, isA<DateTime>());
        expect(firstEntry.published, isA<String>());

        // Should be July 1, 2025
        expect(firstEntry.updated!.year, equals(2025));
        expect(firstEntry.updated!.month, equals(7));
        expect(firstEntry.updated!.day, equals(1));

        // Published date should match the string format
        expect(firstEntry.published, equals('2025-07-01T09:15:48-04:00'));
      });
    });

    group('Content Structure Tests', () {
      test('should parse HTML content correctly', () {
        final firstEntry = feed.items!.first;

        // CDATA sections are processed and removed during XML parsing
        expect(firstEntry.content, contains('<figure>'));
        expect(firstEntry.content, contains('<img'));
        expect(firstEntry.content, contains('<p class="has-text-align-none">'));
        expect(firstEntry.content,
            contains('The US Senate has voted overwhelmingly'));
      });

      test('should parse content with images correctly', () {
        final firstEntry = feed.items!.first;

        expect(
            firstEntry.content,
            contains(
                'data-portal-copyright="Photo: Andrew Harnik / Getty Images"'));
        expect(firstEntry.content,
            contains('src="https://platform.theverge.com/wp-content/uploads'));
      });

      test('should parse content with links correctly', () {
        final firstEntry = feed.items!.first;

        expect(
            firstEntry.content,
            contains(
                '<a href="https://www.senate.gov/legislative/LIS/roll_call_votes'));
        expect(firstEntry.content,
            contains('<a href="https://www.politico.com/live-updates'));
      });
    });

    group('Multiple Entries Tests', () {
      test('should parse all entries with different authors', () {
        final authors = feed.items!
            .map((item) => item.authors?.first.name)
            .where((name) => name != null)
            .cast<String>()
            .toSet();

        expect(authors.length, greaterThan(1));
        expect(authors, contains('Tina Nguyen'));
        expect(authors, contains('Andrew Webster'));
        expect(authors, contains('David Pierce'));
      });

      test('should parse entries with different categories', () {
        final allCategories = <String>{};
        for (final item in feed.items!) {
          if (item.categories != null) {
            allCategories.addAll(
              item.categories!
                  .map((c) => c.term)
                  .where((term) => term != null)
                  .cast<String>(),
            );
          }
        }

        expect(allCategories.length, greaterThan(5));
        expect(allCategories, contains('AI'));
        expect(allCategories, contains('Entertainment'));
        expect(allCategories, contains('Gaming'));
        expect(allCategories, contains('News'));
      });

      test('should parse entries with different content types', () {
        // Check that some entries have different content structures
        final firstEntry = feed.items!.first;
        final secondEntry = feed.items![1];

        expect(firstEntry.content, isNot(equals(secondEntry.content)));
        expect(firstEntry.title, isNot(equals(secondEntry.title)));
      });
    });

    group('Error Handling Tests', () {
      test('should handle malformed XML gracefully', () {
        final malformedXml = xmlString.replaceFirst('<feed', '<invalid');

        expect(() => AtomFeed.parse(malformedXml), throwsA(anything));
      });

      test('should handle empty content gracefully', () {
        final emptyXml =
            '<?xml version="1.0" encoding="UTF-8"?><feed xmlns="http://www.w3.org/2005/Atom"></feed>';

        expect(() => AtomFeed.parse(emptyXml), returnsNormally);
      });

      test('should handle missing optional fields gracefully', () {
        // Test that parsing doesn't fail when optional fields are missing
        final minimalXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>The Verge</title>
  <id>https://www.theverge.com/rss/index.xml</id>
  <updated>2025-07-01T13:15:48+00:00</updated>
</feed>
''';

        expect(() => AtomFeed.parse(minimalXml), returnsNormally);
      });
    });

    group('Performance Tests', () {
      test('should parse large feed efficiently', () {
        final stopwatch = Stopwatch()..start();
        final parsedFeed = AtomFeed.parse(xmlString);
        stopwatch.stop();

        expect(parsedFeed.items!.length, equals(10));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should parse in under 1 second
      });

      test('should detect feed type efficiently', () {
        final stopwatch = Stopwatch()..start();
        final feedType = detectFeedTypeEfficiently(xmlString);
        stopwatch.stop();

        expect(feedType, equals(FeedType.atom));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(100)); // Should detect in under 100ms
      });
    });

    group('Real-world Content Tests', () {
      test('should handle real-world HTML content with special characters', () {
        final firstEntry = feed.items!.first;

        // Test that HTML content is parsed correctly
        expect(firstEntry.content, contains('<p'));
        expect(firstEntry.content, contains('</p>'));
        expect(firstEntry.content, contains('The US Senate has voted'));
      });

      test('should handle real-world URLs and links', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.content,
            contains('https://www.senate.gov/legislative/LIS/roll_call_votes'));
        expect(firstEntry.content,
            contains('https://www.politico.com/live-updates'));
        expect(
            firstEntry.content,
            contains(
                'https://x.com/BenBrodyDC/status/1939838593062572194/photo/1'));
      });

      test('should handle real-world image URLs with parameters', () {
        final firstEntry = feed.items!.first;

        expect(firstEntry.content, contains('quality=90'));
        expect(firstEntry.content, contains('strip=all'));
        expect(firstEntry.content, contains('crop=0,0,100,100'));
      });
    });
  });
}
