import 'package:test/test.dart';
import 'package:webfeed/domain/rss_feed.dart';

void main() {
  test('Debug empty CDATA parsing', () {
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

    final feed = RssFeed.parse(xmlString, withArticles: true);

    print('Feed title: "${feed.title}"');
    print('Feed description: "${feed.description}"');
    print('Item title: "${feed.items![0].title}"');
    print('Item description: "${feed.items![0].description}"');

    expect(feed.title, equals(''));
    expect(feed.description, equals(''));
    expect(feed.items![0].title, equals(''));
    expect(feed.items![0].description, equals(''));
  });
}
