import 'package:test/test.dart';
import 'package:webfeed/domain/atom_feed.dart';

void main() {
  test(
    'Atom feed with CDATA sections - both parsing methods should produce same results',
    () {
      final xmlString = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <id>https://example.com/feed</id>
          <title><![CDATA[Test Atom Feed with <b>HTML</b> in title]]></title>
          <updated>2024-01-01T12:00:00Z</updated>
          <subtitle><![CDATA[This subtitle has <em>HTML</em> and special chars: &amp; &lt; &gt;]]></subtitle>
          <icon>https://example.com/icon.ico</icon>
          <logo>https://example.com/logo.png</logo>
          <rights><![CDATA[Copyright © 2024]]></rights>
          <link href="https://example.com" rel="self" type="application/atom+xml"/>
          <link href="https://example.com/alternate" rel="alternate" type="text/html"/>
          <author>
            <name><![CDATA[John Doe]]></name>
            <email>john@example.com</email>
            <uri>https://example.com/john</uri>
          </author>
          <contributor>
            <name><![CDATA[Jane Smith]]></name>
            <email>jane@example.com</email>
            <uri>https://example.com/jane</uri>
          </contributor>
          <category term="technology" scheme="https://example.com/categories" label="Technology"/>
          <category term="news" scheme="https://example.com/categories" label="News"/>
          <generator uri="https://example.com/generator" version="1.0"><![CDATA[Test Generator <v1.0>]]></generator>
          <entry>
            <id>https://example.com/entry1</id>
            <title><![CDATA[Entry Title with <strong>HTML</strong> and special chars: &amp; &lt; &gt;]]></title>
            <updated>2024-01-01T12:00:00Z</updated>
            <summary><![CDATA[Entry summary with <a href="https://example.com">link</a> and line breaks
            on multiple lines]]></summary>
            <content type="html"><![CDATA[<p>Full content with <strong>HTML</strong> and <img src="https://example.com/image.jpg" alt="test"/></p>]]></content>
            <link href="https://example.com/entry1" rel="alternate" type="text/html"/>
            <author>
              <name><![CDATA[Jane Smith]]></name>
              <email>jane@example.com</email>
              <uri>https://example.com/jane</uri>
            </author>
            <category term="technology" scheme="https://example.com/categories" label="Technology"/>
          </entry>
          <entry>
            <id>https://example.com/entry2</id>
            <title><![CDATA[Second Entry with <em>emphasis</em>]]></title>
            <updated>2024-01-01T13:00:00Z</updated>
            <summary><![CDATA[Second entry summary]]></summary>
            <link href="https://example.com/entry2" rel="alternate" type="text/html"/>
          </entry>
        </feed>
      ''';

      // Parse with regular method
      final regularFeed = AtomFeed.parse(xmlString, withArticles: true);

      // Parse with efficient method
      final efficientFeed =
          AtomFeed.parseEfficiently(xmlString, withArticles: true);

      // Verify both methods produce the same results
      expect(regularFeed.title,
          equals('Test Atom Feed with <b>HTML</b> in title'));
      expect(efficientFeed.title,
          equals('Test Atom Feed with <b>HTML</b> in title'));
      expect(regularFeed.title, equals(efficientFeed.title));

      expect(regularFeed.subtitle,
          equals('This subtitle has <em>HTML</em> and special chars: & < >'));
      expect(efficientFeed.subtitle,
          equals('This subtitle has <em>HTML</em> and special chars: & < >'));
      expect(regularFeed.subtitle, equals(efficientFeed.subtitle));

      expect(regularFeed.rights, equals('Copyright © 2024'));
      expect(efficientFeed.rights, equals('Copyright © 2024'));
      expect(regularFeed.rights, equals(efficientFeed.rights));

      expect(regularFeed.icon, equals('https://example.com/icon.ico'));
      expect(efficientFeed.icon, equals('https://example.com/icon.ico'));
      expect(regularFeed.icon, equals(efficientFeed.icon));

      expect(regularFeed.logo, equals('https://example.com/logo.png'));
      expect(efficientFeed.logo, equals('https://example.com/logo.png'));
      expect(regularFeed.logo, equals(efficientFeed.logo));

      // Verify items
      expect(regularFeed.items!.length, equals(2));
      expect(efficientFeed.items!.length, equals(2));
      expect(regularFeed.items!.length, equals(efficientFeed.items!.length));

      // Verify first item
      final regularItem = regularFeed.items![0];
      final efficientItem = efficientFeed.items![0];

      expect(
          regularItem.title,
          equals(
              'Entry Title with <strong>HTML</strong> and special chars: & < >'));
      expect(
          efficientItem.title,
          equals(
              'Entry Title with <strong>HTML</strong> and special chars: & < >'));
      expect(regularItem.title, equals(efficientItem.title));

      expect(regularItem.summary, contains('line breaks'));
      expect(efficientItem.summary, contains('line breaks'));
      expect(regularItem.summary, equals(efficientItem.summary));

      // Verify links
      expect(regularFeed.links!.length, equals(2));
      expect(efficientFeed.links!.length, equals(2));
      expect(regularFeed.links!.length, equals(efficientFeed.links!.length));

      // Verify authors
      expect(regularFeed.authors!.length, equals(1));
      expect(efficientFeed.authors!.length, equals(1));
      expect(
          regularFeed.authors!.length, equals(efficientFeed.authors!.length));

      expect(regularFeed.authors![0].name, equals('John Doe'));
      expect(efficientFeed.authors![0].name, equals('John Doe'));
      expect(
          regularFeed.authors![0].name, equals(efficientFeed.authors![0].name));

      // Verify contributors
      expect(regularFeed.contributors!.length, equals(1));
      expect(efficientFeed.contributors!.length, equals(1));
      expect(regularFeed.contributors!.length,
          equals(efficientFeed.contributors!.length));

      expect(regularFeed.contributors![0].name, equals('Jane Smith'));
      expect(efficientFeed.contributors![0].name, equals('Jane Smith'));
      expect(regularFeed.contributors![0].name,
          equals(efficientFeed.contributors![0].name));

      // Verify categories
      expect(regularFeed.categories!.length, equals(2));
      expect(efficientFeed.categories!.length, equals(2));
      expect(regularFeed.categories!.length,
          equals(efficientFeed.categories!.length));

      // Verify generator
      expect(regularFeed.generator?.value, equals('Test Generator <v1.0>'));
      expect(efficientFeed.generator?.value, equals('Test Generator <v1.0>'));
      expect(
          regularFeed.generator?.value, equals(efficientFeed.generator?.value));
    },
  );
}
