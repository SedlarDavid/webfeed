import 'package:test/test.dart';
import 'package:webfeed/domain/rss_feed.dart';

void main() {
  test('Simple RSS feed with exactly 2 items', () {
    final xmlString = '''
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <description>Test Description</description>
          <link>https://example.com</link>
          <item>
            <title>Item 1</title>
            <description>Description 1</description>
            <link>https://example.com/1</link>
          </item>
          <item>
            <title>Item 2</title>
            <description>Description 2</description>
            <link>https://example.com/2</link>
          </item>
        </channel>
      </rss>
    ''';

    final feed = RssFeed.parse(xmlString, withArticles: true);

    print('DEBUG: Feed items count: ${feed.items?.length}');
    if (feed.items != null) {
      for (var i = 0; i < feed.items!.length; i++) {
        print('DEBUG: Item $i title: ${feed.items![i].title}');
      }
    }

    expect(feed.items?.length, equals(2));
  });
}
