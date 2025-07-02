import 'dart:io';
import 'package:test/test.dart';
import 'package:webfeed/domain/atom_feed.dart';

void main() {
  group('Atom-Kottke.xml parsing tests', () {
    late String xmlContent;

    setUpAll(() {
      xmlContent = File('test/xml/Atom-Kottke.xml').readAsStringSync();
    });

    test('should parse Atom-Kottke.xml with both parsing methods', () {
      final regularFeed = AtomFeed.parse(xmlContent);
      final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

      // Basic feed metadata
      expect(regularFeed.title, equals('kottke.org'));
      expect(efficientFeed.title, equals('kottke.org'));
      expect(regularFeed.id, equals('tag:kottke.org,2009-08-11:05118'));
      expect(efficientFeed.id, equals('tag:kottke.org,2009-08-11:05118'));
      expect(regularFeed.subtitle, contains('Jason Kottke'));
      expect(efficientFeed.subtitle, contains('Jason Kottke'));

      // Check that items are parsed
      expect(regularFeed.items, isNotNull);
      expect(efficientFeed.items, isNotNull);
      expect(regularFeed.items!.length, greaterThan(0));
      expect(efficientFeed.items!.length, greaterThan(0));
    });

    test('should parse feed-level links correctly', () {
      final regularFeed = AtomFeed.parse(xmlContent);
      final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

      // Check that links are parsed (should not be empty)
      expect(regularFeed.links, isNotNull);
      expect(efficientFeed.links, isNotNull);

      // The feed should have at least 2 links: alternate and self
      expect(regularFeed.links!.length, greaterThanOrEqualTo(2));
      expect(efficientFeed.links!.length, greaterThanOrEqualTo(2));

      // Check for specific links
      final regularAlternateLink = regularFeed.links!.firstWhere(
        (link) => link.rel == 'alternate',
        orElse: () => throw StateError('No alternate link found'),
      );
      final efficientAlternateLink = efficientFeed.links!.firstWhere(
        (link) => link.rel == 'alternate',
        orElse: () => throw StateError('No alternate link found'),
      );

      expect(regularAlternateLink.href, equals('https://kottke.org/'));
      expect(efficientAlternateLink.href, equals('https://kottke.org/'));
      expect(regularAlternateLink.type, equals('text/html'));
      expect(efficientAlternateLink.type, equals('text/html'));

      // Check for self link
      final regularSelfLink = regularFeed.links!.firstWhere(
        (link) => link.rel == 'self',
        orElse: () => throw StateError('No self link found'),
      );
      final efficientSelfLink = efficientFeed.links!.firstWhere(
        (link) => link.rel == 'self',
        orElse: () => throw StateError('No self link found'),
      );

      expect(regularSelfLink.href, equals('https://feeds.kottke.org/main'));
      expect(efficientSelfLink.href, equals('https://feeds.kottke.org/main'));
      expect(regularSelfLink.type, equals('application/atom+xml'));
      expect(efficientSelfLink.type, equals('application/atom+xml'));
    });

    test('should parse entry links correctly', () {
      final regularFeed = AtomFeed.parse(xmlContent);
      final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

      // Check first entry
      final firstRegularEntry = regularFeed.items!.first;
      final firstEfficientEntry = efficientFeed.items!.first;

      // Entry should have a link
      expect(firstRegularEntry.links, isNotNull);
      expect(firstEfficientEntry.links, isNotNull);

      if (firstRegularEntry.links!.isNotEmpty) {
        final regularEntryLink = firstRegularEntry.links!.first;
        expect(regularEntryLink.rel, equals('alternate'));
        expect(regularEntryLink.type, equals('text/html'));
        expect(regularEntryLink.href, contains('kottke.org'));
      }

      if (firstEfficientEntry.links!.isNotEmpty) {
        final efficientEntryLink = firstEfficientEntry.links!.first;
        expect(efficientEntryLink.rel, equals('alternate'));
        expect(efficientEntryLink.type, equals('text/html'));
        expect(efficientEntryLink.href, contains('kottke.org'));
      }
    });

    test('should parse authors correctly', () {
      final regularFeed = AtomFeed.parse(xmlContent);
      final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

      // Check feed-level authors
      expect(regularFeed.authors, isNotNull);
      expect(efficientFeed.authors, isNotNull);

      // Check entry-level authors
      final firstEntry = regularFeed.items!.first;
      expect(firstEntry.authors, isNotNull);
      expect(firstEntry.authors!.length, greaterThan(0));
      expect(firstEntry.authors!.first.name, equals('Jason Kottke'));
      expect(firstEntry.authors!.first.uri, equals('http://www.kottke.org'));
    });

    test('should parse content with CDATA correctly', () {
      final regularFeed = AtomFeed.parse(xmlContent);
      final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

      final firstRegularEntry = regularFeed.items!.first;
      final firstEfficientEntry = efficientFeed.items!.first;

      expect(firstRegularEntry.content, isNotNull);
      expect(firstEfficientEntry.content, isNotNull);
      expect(firstRegularEntry.content!.contains('The plot of this movie'),
          isTrue);
      expect(firstEfficientEntry.content!.contains('The plot of this movie'),
          isTrue);
      expect(firstRegularEntry.content!.contains('The Running Man'), isTrue);
      expect(firstEfficientEntry.content!.contains('The Running Man'), isTrue);
    });

    test('should parse generator correctly', () {
      final regularFeed = AtomFeed.parse(xmlContent);
      final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

      expect(regularFeed.generator, isNotNull);
      expect(efficientFeed.generator, isNotNull);
      expect(regularFeed.generator!.uri,
          equals('http://www.sixapart.com/movabletype/'));
      expect(efficientFeed.generator!.uri,
          equals('http://www.sixapart.com/movabletype/'));
      expect(regularFeed.generator!.value, contains('Movable Type'));
      expect(efficientFeed.generator!.value, contains('Movable Type'));
    });
  });
}
