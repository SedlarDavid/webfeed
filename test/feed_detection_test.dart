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
    
    test('should still detect feed type with whitespace before XML declaration', () {
      // XML with whitespace before declaration - still valid XML but some parsers may fail
      final xmlString = '  \n  <?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0"></rss>';
      
      final feedType = detectFeedType(xmlString);
      
      expect(feedType, equals(FeedType.rss));
    });
  });
}