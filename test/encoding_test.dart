import 'package:test/test.dart';
import 'package:webfeed/webfeed.dart';

void main() {
  group('XML encoding tests', () {
    test('Handle UTF-8 encoding', () {
      final xmlString = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>UTF-8 Test 🌍</title>
            <description>Testing UTF-8 characters like: ñáéíóúçãõ</description>
            <item>
              <title>UTF-8 Item ✅</title>
              <description>Item with emoji 📱 and special chars »«¿¡</description>
            </item>
          </channel>
        </rss>
      ''';

      final feed = RssFeed.parse(xmlString);

      expect(feed.title, 'UTF-8 Test 🌍');
      expect(feed.description, 'Testing UTF-8 characters like: ñáéíóúçãõ');
      expect(feed.items![0].title, 'UTF-8 Item ✅');
      expect(feed.items![0].description,
          'Item with emoji 📱 and special chars »«¿¡');
    });

    test('Handle HTML entities in content', () {
      final xmlString = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
          <channel>
            <title>HTML Entity Test</title>
            <item>
              <title>Item with &amp;, &lt;, &gt;, &quot; entities</title>
              <description>Text with &amp;quot;quoted&amp;quot; content</description>
              <content:encoded>
                <![CDATA[
                  <p>HTML with &copy; symbol and <strong>bold text</strong></p>
                  <p>Text with &amp;quot;quoted&amp;quot; content</p>
                ]]>
              </content:encoded>
            </item>
          </channel>
        </rss>
      ''';

      final feed = RssFeed.parse(xmlString);

      expect(feed.title, 'HTML Entity Test');
      expect(feed.items![0].title, 'Item with &, <, >, " entities');
      expect(feed.items![0].description, 'Text with "quoted" content');

      // Content should preserve the CDATA content
      expect(feed.items![0].content, isNotNull);
      expect(feed.items![0].content!.value,
          contains('<strong>bold text</strong>'));

      // Plain text should decode entities
      expect(feed.items![0].content!.plainText, isNotNull);
      expect(feed.items![0].content!.plainText, contains('bold text'));
      expect(feed.items![0].content!.plainText, isNot(contains('<strong>')));
    });

    test('Handle CDATA sections', () {
      final xmlString = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>CDATA Test</title>
            <description><![CDATA[This description has <b>HTML</b> in CDATA]]></description>
            <item>
              <title><![CDATA[CDATA Title with <em>emphasis</em>]]></title>
              <description><![CDATA[
                This is a multi-line CDATA section
                with line breaks and <a href="https://example.com">links</a>
              ]]></description>
            </item>
          </channel>
        </rss>
      ''';

      final feed = RssFeed.parse(xmlString);

      expect(feed.title, 'CDATA Test');
      expect(feed.description, 'This description has <b>HTML</b> in CDATA');
      expect(feed.items![0].title, 'CDATA Title with <em>emphasis</em>');
      expect(feed.items![0].description, contains('line breaks'));
      expect(feed.items![0].description, contains('<a href='));
    });
  });
}
