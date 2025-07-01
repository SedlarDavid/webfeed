import 'dart:io';
import 'package:test/test.dart';
import 'package:webfeed/domain/atom_feed.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:webfeed/util/feed_detection.dart';

void main() {
  group('Efficient Parsing Performance Tests', () {
    late String largeRssXml;
    late String largeAtomXml;

    setUpAll(() {
      // Load large test files
      final rssFile = File('test/xml/RSS-Detect-Long.xml');
      if (rssFile.existsSync()) {
        largeRssXml = rssFile.readAsStringSync();
      } else {
        // Create a large RSS feed for testing
        largeRssXml = _createLargeRssFeed();
      }

      // Create a large Atom feed for testing
      largeAtomXml = _createLargeAtomFeed();
    });

    test('RSS parsing performance comparison', () {
      if (largeRssXml.isEmpty) {
        print('Skipping RSS performance test - no large RSS file available');
        return;
      }

      final iterations = 10;

      // Test standard parsing
      final standardStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feed = RssFeed.parse(largeRssXml, withArticles: true);
        expect(feed.title, equals('Large Test RSS Feed'));
        expect(feed.items!.length, equals(1000));
      }
      final standardEnd = DateTime.now();
      final standardDuration = standardEnd.difference(standardStart);

      // Test efficient parsing
      final efficientStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feed = RssFeed.parseEfficiently(largeRssXml, withArticles: true);
        expect(feed.title, equals('Large Test RSS Feed'));
        expect(feed.items!.length, equals(1000));
      }
      final efficientEnd = DateTime.now();
      final efficientDuration = efficientEnd.difference(efficientStart);

      final speedup =
          standardDuration.inMicroseconds / efficientDuration.inMicroseconds;

      print('\n=== RSS Parsing Performance ===');
      print('File size: ${(largeRssXml.length / 1024).toStringAsFixed(1)} KB');
      print(
          'Standard parsing (${iterations} iterations): ${standardDuration.inMilliseconds}ms');
      print(
          'Efficient parsing (${iterations} iterations): ${efficientDuration.inMilliseconds}ms');
      print('Speedup: ${speedup.toStringAsFixed(1)}x');

      // Verify significant performance improvement
      expect(speedup, greaterThan(1.5),
          reason: 'Efficient parsing should be at least 1.5x faster');
    });

    test('Atom parsing performance comparison', () {
      final iterations = 10;

      // Test standard parsing
      final standardStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feed = AtomFeed.parse(largeAtomXml, withArticles: true);
        expect(feed.title, equals('Large Test Atom Feed'));
        expect(feed.items!.length, equals(1000));
      }
      final standardEnd = DateTime.now();
      final standardDuration = standardEnd.difference(standardStart);

      // Test efficient parsing
      final efficientStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feed =
            AtomFeed.parseEfficiently(largeAtomXml, withArticles: true);
        expect(feed.title, equals('Large Test Atom Feed'));
        expect(feed.items!.length, equals(1000));
      }
      final efficientEnd = DateTime.now();
      final efficientDuration = efficientEnd.difference(efficientStart);

      final speedup =
          standardDuration.inMicroseconds / efficientDuration.inMicroseconds;

      print('\n=== Atom Parsing Performance ===');
      print('File size: ${(largeAtomXml.length / 1024).toStringAsFixed(1)} KB');
      print(
          'Standard parsing (${iterations} iterations): ${standardDuration.inMilliseconds}ms');
      print(
          'Efficient parsing (${iterations} iterations): ${efficientDuration.inMilliseconds}ms');
      print('Speedup: ${speedup.toStringAsFixed(1)}x');

      // Verify significant performance improvement
      expect(speedup, greaterThan(1.5),
          reason: 'Efficient parsing should be at least 1.5x faster');
    });

    test('metadata-only parsing performance', () {
      if (largeRssXml.isEmpty) {
        print('Skipping metadata-only test - no large RSS file available');
        return;
      }

      final iterations = 50;

      // Test standard parsing with articles
      final standardStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feed = RssFeed.parse(largeRssXml, withArticles: true);
        expect(feed.title, equals('Large Test RSS Feed'));
        expect(feed.items!.length, equals(1000));
      }
      final standardEnd = DateTime.now();
      final standardDuration = standardEnd.difference(standardStart);

      // Test efficient parsing without articles
      final efficientStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feed = RssFeed.parseEfficiently(largeRssXml, withArticles: false);
        expect(feed.title, equals('Large Test RSS Feed'));
        expect(feed.items, isNull); // Should be null when withArticles is false
      }
      final efficientEnd = DateTime.now();
      final efficientDuration = efficientEnd.difference(efficientStart);

      final speedup =
          standardDuration.inMicroseconds / efficientDuration.inMicroseconds;

      print('\n=== Metadata-Only Parsing Performance ===');
      print(
          'Standard parsing with articles (${iterations} iterations): ${standardDuration.inMilliseconds}ms');
      print(
          'Efficient parsing without articles (${iterations} iterations): ${efficientDuration.inMilliseconds}ms');
      print('Speedup: ${speedup.toStringAsFixed(1)}x');

      // Verify significant performance improvement
      expect(speedup, greaterThan(5.0),
          reason: 'Metadata-only parsing should be at least 5x faster');
    });

    test('feed detection performance', () {
      if (largeRssXml.isEmpty) {
        print('Skipping feed detection test - no large RSS file available');
        return;
      }

      final iterations = 100;

      // Test standard detection
      final standardStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feedType = detectFeedType(largeRssXml);
        expect(feedType, equals(FeedType.rss));
        // Verify the detection is correct by parsing a small sample
        final sample = largeRssXml.substring(0, 500);
        expect(detectFeedType(sample), equals(FeedType.rss));
      }
      final standardEnd = DateTime.now();
      final standardDuration = standardEnd.difference(standardStart);

      // Test efficient detection
      final efficientStart = DateTime.now();
      for (var i = 0; i < iterations; i++) {
        final feedType = detectFeedTypeEfficiently(largeRssXml);
        expect(feedType, equals(FeedType.rss));
        // Verify the detection is correct by parsing a small sample
        final sample = largeRssXml.substring(0, 500);
        expect(detectFeedTypeEfficiently(sample), equals(FeedType.rss));
      }
      final efficientEnd = DateTime.now();
      final efficientDuration = efficientEnd.difference(efficientStart);

      final speedup =
          standardDuration.inMicroseconds / efficientDuration.inMicroseconds;

      print('\n=== Feed Detection Performance ===');
      print(
          'Standard detection (${iterations} iterations): ${standardDuration.inMilliseconds}ms');
      print(
          'Efficient detection (${iterations} iterations): ${efficientDuration.inMilliseconds}ms');
      print('Speedup: ${speedup.toStringAsFixed(1)}x');

      // Verify significant performance improvement
      expect(speedup, greaterThan(10.0),
          reason: 'Efficient detection should be at least 10x faster');
    });
  });
}

String _createLargeRssFeed() {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<rss version="2.0">');
  buffer.writeln('<channel>');
  buffer.writeln('<title>Large Test RSS Feed</title>');
  buffer.writeln(
      '<description>This is a large RSS feed for performance testing</description>');
  buffer.writeln('<link>https://example.com</link>');
  buffer.writeln('<language>en-US</language>');

  // Add many items to make the feed large
  for (var i = 1; i <= 1000; i++) {
    buffer.writeln('<item>');
    buffer.writeln('<title>Test Item $i</title>');
    buffer.writeln(
        '<description>This is test item number $i with some content to make it larger.</description>');
    buffer.writeln('<link>https://example.com/item$i</link>');
    buffer.writeln('<guid>item-$i</guid>');
    buffer.writeln('<pubDate>Mon, 26 Mar 2018 14:00:00 GMT</pubDate>');
    buffer.writeln('<author>Test Author</author>');
    buffer.writeln('</item>');
  }

  buffer.writeln('</channel>');
  buffer.writeln('</rss>');

  return buffer.toString();
}

String _createLargeAtomFeed() {
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<feed xmlns="http://www.w3.org/2005/Atom">');
  buffer.writeln('<title>Large Test Atom Feed</title>');
  buffer.writeln(
      '<subtitle>This is a large Atom feed for performance testing</subtitle>');
  buffer.writeln('<id>https://example.com/feed</id>');
  buffer.writeln('<updated>2018-03-26T14:00:00Z</updated>');
  buffer.writeln('<link href="https://example.com"/>');

  // Add many entries to make the feed large
  for (var i = 1; i <= 1000; i++) {
    buffer.writeln('<entry>');
    buffer.writeln('<title>Test Entry $i</title>');
    buffer.writeln('<id>entry-$i</id>');
    buffer.writeln('<updated>2018-03-26T14:00:00Z</updated>');
    buffer.writeln(
        '<summary>This is test entry number $i with some content to make it larger.</summary>');
    buffer.writeln('<link href="https://example.com/entry$i"/>');
    buffer.writeln('</entry>');
  }

  buffer.writeln('</feed>');

  return buffer.toString();
}
