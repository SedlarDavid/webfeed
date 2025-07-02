import 'dart:io';
import 'package:test/test.dart';
import 'package:webfeed/domain/rss_feed.dart';

void main() {
  test('RSS-Marginalian.xml should parse without unclosed tag error', () {
    final xmlContent = File('test/xml/RSS-Marginalian.xml').readAsStringSync();

    // This should not throw an error about unclosed <hr> tag
    expect(() {
      final feed = RssFeed.parseEfficiently(xmlContent);
      expect(feed.title, isNotNull);
      expect(feed.items, isNotNull);
      expect(feed.items!.isNotEmpty, isTrue);
    }, returnsNormally);
  });
}
