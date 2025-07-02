import 'package:webfeed/util/xml.dart';
import 'package:xml/xml.dart';

void main() {
  const nestedCdataXml = '''
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title><![CDATA[<![CDATA[Nested CDATA]]>]]></title>
        <description><![CDATA[<![CDATA[<![CDATA[Triple nested]]>]]>]]></description>
      </channel>
    </rss>
  ''';

  try {
    // Parse with XML parser
    final document = XmlDocument.parse(nestedCdataXml);
    final titleElements = document.findElements('title');

    if (titleElements.isNotEmpty) {
      final titleElement = titleElements.first;

      print('Raw XML for title element:');
      print(titleElement.toXmlString());
      print('---');

      print('Title element text: "${titleElement.text}"');
      print('Title element innerText: "${titleElement.innerText}"');
      print('Title element value: "${titleElement.value}"');
      print('---');

      // Test our extraction
      final result = extractTextContent(titleElement);
      print('Our extraction result: "$result"');
      print('---');

      // Test stripCdataWithFlag directly
      final stripResult = stripCdataWithFlag(titleElement.text);
      print('stripCdataWithFlag result: "${stripResult.value}"');
      print('Is CDATA: ${stripResult.isCdata}');
    } else {
      print('No title elements found');
    }
  } catch (e) {
    print('XML parsing failed: $e');
    print('This suggests nested CDATA is causing parsing issues');
  }
}
