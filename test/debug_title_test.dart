import 'package:test/test.dart';
import 'package:webfeed/domain/rss_feed.dart';

void main() {
  test('Debug title fallback issue', () {
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

    print('Testing regular parsing...');
    final regularFeed = RssFeed.parse(itemsOnlyXml);
    print('Regular feed title: "${regularFeed.title}"');

    print('Testing efficient parsing...');
    final efficientFeed = RssFeed.parseEfficiently(itemsOnlyXml);
    print('Efficient feed title: "${efficientFeed.title}"');

    expect(regularFeed.title, isNull);
    expect(efficientFeed.title, isNull);
  });
}
