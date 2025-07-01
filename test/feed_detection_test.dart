import 'dart:io';

import 'package:test/test.dart';
import 'package:webfeed/webfeed.dart';

void main() {
  group('Feed Detection Tests', () {
    test('should detect RSS 2.0 feed', () {
      final file = File('test/xml/RSS.xml');
      final xmlString = file.readAsStringSync();

      final feedType = detectFeedType(xmlString);

      expect(feedType, equals(FeedType.rss));
    });

    test('should detect Atom feed', () {
      final file = File('test/xml/Atom.xml');
      final xmlString = file.readAsStringSync();

      final feedType = detectFeedType(xmlString);

      expect(feedType, equals(FeedType.atom));
    });

    test('should detect RDF (RSS 1.0) feed', () {
      final file = File('test/xml/RSS-RDF.xml');
      final xmlString = file.readAsStringSync();

      final feedType = detectFeedType(xmlString);

      expect(feedType, equals(FeedType.rdf));
    });

    test('should return unknown for invalid XML', () {
      final xmlString = 'This is not a valid XML document';

      final feedType = detectFeedType(xmlString);

      expect(feedType, equals(FeedType.unknown));
    });

    test('should still detect feed type with whitespace before XML declaration',
        () {
      // XML with whitespace before declaration - still valid XML but some parsers may fail
      final xmlString =
          '  \n  <?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"></rss>';

      final feedType = detectFeedType(xmlString);

      expect(feedType, equals(FeedType.rss));
    });
  });

  group('Efficient Feed Detection Tests', () {
    test('should detect RSS 2.0 feed efficiently', () {
      final file = File('test/xml/RSS.xml');
      final xmlString = file.readAsStringSync();

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.rss));
    });

    test('should detect Atom feed efficiently', () {
      final file = File('test/xml/Atom.xml');
      final xmlString = file.readAsStringSync();

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.atom));
    });

    test('should detect RDF (RSS 1.0) feed efficiently', () {
      final file = File('test/xml/RSS-RDF.xml');
      final xmlString = file.readAsStringSync();

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.rdf));
    });

    test('should return unknown for invalid XML efficiently', () {
      final xmlString = 'This is not a valid XML document';

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.unknown));
    });

    test('should handle XML with whitespace before declaration efficiently',
        () {
      final xmlString =
          '  \n  <?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"></rss>';

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.rss));
    });

    test('should handle XML with attributes efficiently', () {
      final xmlString =
          '<?xml version="1.0" encoding="utf-8"?><rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/"></rss>';

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.rss));
    });

    test('should handle self-closing tags efficiently', () {
      final xmlString = '<?xml version="1.0"?><rss version="2.0" />';

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.rss));
    });

    test('should handle RDF with namespace efficiently', () {
      final xmlString =
          '<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"></rdf:RDF>';

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.rdf));
    });

    test('should handle Atom with attributes efficiently', () {
      final xmlString =
          '<?xml version="1.0"?><feed xmlns="http://www.w3.org/2005/Atom"></feed>';

      final feedType = detectFeedTypeEfficiently(xmlString);

      expect(feedType, equals(FeedType.atom));
    });
  });

  group('Performance Comparison Tests', () {
    test('both functions should return same result for RSS', () {
      final file = File('test/xml/RSS.xml');
      final xmlString = file.readAsStringSync();

      final originalResult = detectFeedType(xmlString);
      final efficientResult = detectFeedTypeEfficiently(xmlString);

      expect(originalResult, equals(efficientResult));
      expect(originalResult, equals(FeedType.rss));
    });

    test('both functions should return same result for Atom', () {
      final file = File('test/xml/Atom.xml');
      final xmlString = file.readAsStringSync();

      final originalResult = detectFeedType(xmlString);
      final efficientResult = detectFeedTypeEfficiently(xmlString);

      expect(originalResult, equals(efficientResult));
      expect(originalResult, equals(FeedType.atom));
    });

    test('both functions should return same result for RDF', () {
      final file = File('test/xml/RSS-RDF.xml');
      final xmlString = file.readAsStringSync();

      final originalResult = detectFeedType(xmlString);
      final efficientResult = detectFeedTypeEfficiently(xmlString);

      expect(originalResult, equals(efficientResult));
      expect(originalResult, equals(FeedType.rdf));
    });

    test('efficient function should be significantly faster on large files',
        () {
      final file = File('test/xml/RSS-Detect-Long.xml');
      final xmlString = file.readAsStringSync();

      // Measure time for efficient function
      final efficientStart = DateTime.now();
      final efficientResult = detectFeedTypeEfficiently(xmlString);
      final efficientEnd = DateTime.now();
      final efficientDuration = efficientEnd.difference(efficientStart);

      // Measure time for original function
      final originalStart = DateTime.now();
      final originalResult = detectFeedType(xmlString);
      final originalEnd = DateTime.now();
      final originalDuration = originalEnd.difference(originalStart);

      // Both should return the same result
      expect(originalResult, equals(efficientResult));
      expect(originalResult, equals(FeedType.rss));

      // Efficient function should be significantly faster
      // We expect the efficient function to be at least 10x faster
      expect(efficientDuration.inMicroseconds,
          lessThan(originalDuration.inMicroseconds ~/ 10));

      // Log the performance difference for verification
      print('Performance comparison for RSS-Detect-Long.xml:');
      print(
          'Original function: ${originalDuration.inMicroseconds} microseconds');
      print(
          'Efficient function: ${efficientDuration.inMicroseconds} microseconds');
      print(
          'Speed improvement: ${(originalDuration.inMicroseconds / efficientDuration.inMicroseconds).toStringAsFixed(1)}x faster');
    });

    test('efficient function should handle edge cases correctly', () {
      // Test with various edge cases
      final testCases = [
        '<rss></rss>',
        '<?xml version="1.0"?><rss></rss>',
        '  <?xml version="1.0"?>  <rss></rss>',
        '<feed></feed>',
        '<?xml version="1.0"?><feed></feed>',
        '<RDF></RDF>',
        '<?xml version="1.0"?><RDF></RDF>',
        '<rdf:RDF></rdf:RDF>',
        '<?xml version="1.0"?><rdf:RDF></rdf:RDF>',
        '<unknown></unknown>',
        'not xml at all',
        '',
        '   ',
      ];

      for (final testCase in testCases) {
        final originalResult = detectFeedType(testCase);
        final efficientResult = detectFeedTypeEfficiently(testCase);

        expect(originalResult, equals(efficientResult),
            reason: 'Failed for test case: "$testCase"');
      }
    });
  });
}
