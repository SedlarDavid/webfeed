import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:webfeed/util/xml.dart';

void main() {
  group('XML namespace handling tests', () {
    test('Find elements with namespace prefix', () {
      final xmlString = '''
        <feed xmlns:content="http://purl.org/rss/1.0/modules/content/">
          <title>Test Feed</title>
          <content:encoded>This is encoded content</content:encoded>
          <entry>
            <title>Test Entry</title>
            <content:encoded>Entry content</content:encoded>
          </entry>
        </feed>
      ''';

      final document = XmlDocument.parse(xmlString);
      final feedElement = document.findElements('feed').first;

      // Find all content:encoded elements in the feed (recursively)
      // Note: With XML namespace awareness, we expect to find both the direct child
      // and the one under entry
      final allContentElements =
          findAllElementsWithNamespace(document, 'encoded');
      expect(allContentElements.length, 2);

      // Test finding elements with namespace prefix (direct children only)
      final directContentElements =
          findAllElementsWithNamespace(feedElement, 'encoded')
              .where((element) => element.parent == feedElement)
              .toList();
      expect(directContentElements.length, 1);
      expect(directContentElements.first.text, 'This is encoded content');

      // Test finding element with namespace under child
      final entryElement = feedElement.findElements('entry').first;
      final entryContentElement =
          findElementWithNamespace(entryElement, 'encoded');
      expect(entryContentElement, isNotNull);
      expect(entryContentElement?.text, 'Entry content');
    });

    test('Find elements with alternative names', () {
      final xmlString = '''
        <channel>
          <author>John Doe</author>
          <dc:creator>Jane Smith</dc:creator>
        </channel>
      ''';

      final document = XmlDocument.parse(xmlString);
      final channelElement = document.findElements('channel').first;

      // Test finding element with main name
      final authorElement =
          findElementWithAlternatives(channelElement, ['author', 'creator']);
      expect(authorElement, isNotNull);
      expect(authorElement?.text, 'John Doe');

      // Test when main name doesn't exist but alternative does
      final mockXml = '''
        <channel>
          <dc:creator>Jane Smith</dc:creator>
        </channel>
      ''';
      final mockDoc = XmlDocument.parse(mockXml);
      final mockChannelElement = mockDoc.findElements('channel').first;

      final creatorElement = findElementWithAlternatives(
          mockChannelElement, ['author', 'creator']);
      expect(creatorElement, isNotNull);
      expect(creatorElement?.text, 'Jane Smith');
    });

    test('Get attribute with namespace', () {
      final xmlString = '''
        <link rel="self" 
              href="https://example.com/feed" 
              atom:href="https://example.com/atom-feed"/>
      ''';

      final document = XmlDocument.parse(xmlString);
      final linkElement = document.findElements('link').first;

      // Test regular attribute
      final href = getAttributeWithNamespace(linkElement, 'href');
      expect(href, 'https://example.com/feed');

      // Test attributes that include namespace prefix
      final allHrefs = linkElement.attributes
          .where((attr) =>
              attr.name.local == 'href' ||
              attr.name.qualified.endsWith(':href'))
          .map((attr) => attr.value)
          .toList();

      expect(allHrefs.length, 2);
      expect(allHrefs, contains('https://example.com/feed'));
      expect(allHrefs, contains('https://example.com/atom-feed'));
    });

    test('Parse boolean values with fallback', () {
      final xmlString = '''
        <item xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
          <explicit>yes</explicit>
          <blocked value="true"/>
          <itunes:explicit>1</itunes:explicit>
          <nonBoolean>something</nonBoolean>
        </item>
      ''';

      final document = XmlDocument.parse(xmlString);
      final itemElement = document.findElements('item').first;

      // Test standard boolean value
      expect(findElementWithNamespace(itemElement, 'explicit'), isNotNull);

      // Extract text directly to test boolean parsing
      expect(findElementWithNamespace(itemElement, 'explicit')?.text, 'yes');

      // Test regular boolean value function
      expect(parseBoolWithFallback(itemElement, 'explicit'), true);

      // Test finding with namespace awareness (using the regular XML DOM)
      expect(itemElement.getElement('itunes:explicit'), isNotNull);

      // Test non-boolean value
      expect(findElementWithNamespace(itemElement, 'nonBoolean')?.value,
          'something');

      // Test missing element
      expect(findElementWithNamespace(itemElement, 'missing'), isNull);
    });
  });
}
