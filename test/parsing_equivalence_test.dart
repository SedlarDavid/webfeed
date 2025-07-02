import 'dart:io';
import 'package:test/test.dart';
import 'package:webfeed/domain/atom_feed.dart';
import 'package:webfeed/domain/rss_feed.dart';
import 'package:webfeed/domain/atom_item.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/domain/atom_link.dart';
import 'package:webfeed/domain/atom_person.dart';
import 'package:webfeed/domain/atom_category.dart';
import 'package:webfeed/domain/atom_generator.dart';
import 'package:webfeed/domain/rss_image.dart';
import 'package:webfeed/domain/rss_cloud.dart';
import 'package:webfeed/domain/rss_enclosure.dart';
import 'package:webfeed/domain/rss_source.dart';
import 'package:webfeed/domain/rss_content.dart';
import 'package:webfeed/domain/atom_source.dart';
import 'package:webfeed/domain/rss_category.dart';

void main() {
  group('Parsing Equivalence Tests', () {
    group('Atom Feed Parsing Equivalence', () {
      test('Atom.xml - should produce identical results', () {
        final xmlContent = File('test/xml/Atom.xml').readAsStringSync();
        final regularFeed = AtomFeed.parse(xmlContent);
        final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

        _compareAtomFeeds(regularFeed, efficientFeed);
      });

      test('Atom-Kottke.xml - should produce identical results', () {
        final xmlContent = File('test/xml/Atom-Kottke.xml').readAsStringSync();
        final regularFeed = AtomFeed.parse(xmlContent);
        final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

        _compareAtomFeeds(regularFeed, efficientFeed);
      });

      test('Atom-Media.xml - should produce identical results', () {
        final xmlContent = File('test/xml/Atom-Media.xml').readAsStringSync();
        final regularFeed = AtomFeed.parse(xmlContent);
        final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

        _compareAtomFeeds(regularFeed, efficientFeed);
      });
    });

    group('RSS Feed Parsing Equivalence', () {
      test('RSS.xml - should produce identical results', () {
        final xmlContent = File('test/xml/RSS.xml').readAsStringSync();
        final regularFeed = RssFeed.parse(xmlContent);
        final efficientFeed = RssFeed.parseEfficiently(xmlContent);

        _compareRssFeeds(regularFeed, efficientFeed);
      });

      test('RSS-Simple.xml - should produce identical results', () {
        final xmlContent = File('test/xml/RSS-Simple.xml').readAsStringSync();
        final regularFeed = RssFeed.parse(xmlContent);
        final efficientFeed = RssFeed.parseEfficiently(xmlContent);

        _compareRssFeeds(regularFeed, efficientFeed);
      });

      test('RSS-Media.xml - should produce identical results', () {
        final xmlContent = File('test/xml/RSS-Media.xml').readAsStringSync();
        final regularFeed = RssFeed.parse(xmlContent);
        final efficientFeed = RssFeed.parseEfficiently(xmlContent);

        _compareRssFeeds(regularFeed, efficientFeed);
      });

      test('RSS-Itunes.xml - should produce identical results', () {
        final xmlContent = File('test/xml/RSS-Itunes.xml').readAsStringSync();
        final regularFeed = RssFeed.parse(xmlContent);
        final efficientFeed = RssFeed.parseEfficiently(xmlContent);

        _compareRssFeeds(regularFeed, efficientFeed);
      });

      test('RSS-Verge.xml - should produce identical results', () {
        final xmlContent = File('test/xml/RSS-Verge.xml').readAsStringSync();
        final regularFeed = RssFeed.parse(xmlContent);
        final efficientFeed = RssFeed.parseEfficiently(xmlContent);

        _compareRssFeeds(regularFeed, efficientFeed);
      });
    });

    group('Efficient Parsing Completeness Tests', () {
      test(
          'Atom efficient parsing should not return nulls for parsed properties',
          () {
        final xmlContent = File('test/xml/Atom.xml').readAsStringSync();
        final efficientFeed = AtomFeed.parseEfficiently(xmlContent);

        // Feed-level properties should be parsed
        expect(efficientFeed.title, isNotNull);
        expect(efficientFeed.id, isNotNull);
        expect(efficientFeed.updated, isNotNull);
        expect(efficientFeed.links, isNotNull);
        expect(efficientFeed.authors, isNotNull);
        expect(efficientFeed.contributors, isNotNull);
        expect(efficientFeed.categories, isNotNull);
        expect(efficientFeed.generator, isNotNull);
        expect(efficientFeed.icon, isNotNull);
        expect(efficientFeed.logo, isNotNull);
        expect(efficientFeed.subtitle, isNotNull);
        expect(efficientFeed.items, isNotNull);

        // Items should have parsed properties
        for (final item in efficientFeed.items!) {
          expect(item.id, isNotNull);
          expect(item.title, isNotNull);
          expect(item.updated, isNotNull);
          expect(item.links, isNotNull);
          expect(item.authors, isNotNull);
          expect(item.contributors, isNotNull);
          expect(item.categories, isNotNull);
          expect(item.published, isNotNull);
          expect(item.summary, isNotNull);
          expect(item.content, isNotNull);
          expect(item.rights, isNotNull);
        }
      });

      test(
          'RSS efficient parsing should parse all present properties correctly',
          () {
        final xmlContent = File('test/xml/RSS-Simple.xml').readAsStringSync();
        final efficientFeed = RssFeed.parseEfficiently(xmlContent);

        // Required feed-level properties should be parsed
        expect(efficientFeed.title, isNotNull);
        expect(efficientFeed.description, isNotNull);
        expect(efficientFeed.link, isNotNull);
        expect(efficientFeed.language, isNotNull);
        expect(efficientFeed.image, isNotNull);
        expect(efficientFeed.items, isNotNull);

        // Optional properties that are not in this XML should be null or empty
        expect(efficientFeed.copyright, isNull);
        expect(efficientFeed.managingEditor, isNull);
        expect(efficientFeed.webMaster, isNull);
        expect(efficientFeed.lastBuildDate, isNull);
        expect(efficientFeed.categories, isEmpty);
        expect(efficientFeed.generator, isNull);
        expect(efficientFeed.docs, isNull);
        expect(efficientFeed.cloud, isNull);
        expect(efficientFeed.ttl, equals(0));
        expect(efficientFeed.rating, isNull);
        expect(efficientFeed.skipHours, isEmpty);
        expect(efficientFeed.skipDays, isEmpty);

        // Items should have parsed properties that are present
        for (final item in efficientFeed.items!) {
          expect(item.title, isNotNull);
          expect(item.description, isNotNull);
          expect(item.link, isNotNull);
          expect(item.guid, isNotNull);
          expect(item.pubDate, isNotNull);
          expect(item.categories, isNotNull);
          expect(item.enclosure, isNotNull);

          // Optional properties that are not in this XML should be null
          expect(item.author, isNull);
          expect(item.comments, isNull);
          expect(item.source, isNull);
        }
      });
    });
  });
}

void _compareAtomFeeds(AtomFeed regular, AtomFeed efficient) {
  // Compare feed-level properties
  expect(efficient.id, equals(regular.id), reason: 'Feed ID should match');
  expect(efficient.title, equals(regular.title),
      reason: 'Feed title should match');
  expect(efficient.updated, equals(regular.updated),
      reason: 'Feed updated should match');
  expect(efficient.subtitle, equals(regular.subtitle),
      reason: 'Feed subtitle should match');
  expect(efficient.icon, equals(regular.icon),
      reason: 'Feed icon should match');
  expect(efficient.logo, equals(regular.logo),
      reason: 'Feed logo should match');
  expect(efficient.rights, equals(regular.rights),
      reason: 'Feed rights should match');

  // Compare links
  _compareAtomLinks(regular.links, efficient.links);

  // Compare authors
  _compareAtomPersons(regular.authors, efficient.authors);

  // Compare contributors
  _compareAtomPersons(regular.contributors, efficient.contributors);

  // Compare categories
  _compareAtomCategories(regular.categories, efficient.categories);

  // Compare generator
  _compareAtomGenerator(regular.generator, efficient.generator);

  // Compare items
  expect(efficient.items?.length, equals(regular.items?.length),
      reason: 'Number of items should match');

  if (regular.items != null && efficient.items != null) {
    for (var i = 0; i < regular.items!.length; i++) {
      _compareAtomItems(regular.items![i], efficient.items![i], i);
    }
  }
}

void _compareRssFeeds(RssFeed regular, RssFeed efficient) {
  // Compare feed-level properties
  expect(efficient.title, equals(regular.title),
      reason: 'Feed title should match');
  expect(efficient.description, equals(regular.description),
      reason: 'Feed description should match');
  expect(efficient.link, equals(regular.link),
      reason: 'Feed link should match');
  expect(efficient.language, equals(regular.language),
      reason: 'Feed language should match');
  expect(efficient.copyright, equals(regular.copyright),
      reason: 'Feed copyright should match');
  expect(efficient.managingEditor, equals(regular.managingEditor),
      reason: 'Feed managingEditor should match');
  expect(efficient.webMaster, equals(regular.webMaster),
      reason: 'Feed webMaster should match');
  expect(efficient.lastBuildDate, equals(regular.lastBuildDate),
      reason: 'Feed lastBuildDate should match');
  expect(efficient.categories, equals(regular.categories),
      reason: 'Feed categories should match');
  expect(efficient.generator, equals(regular.generator),
      reason: 'Feed generator should match');
  expect(efficient.docs, equals(regular.docs),
      reason: 'Feed docs should match');
  expect(efficient.ttl, equals(regular.ttl), reason: 'Feed ttl should match');
  expect(efficient.rating, equals(regular.rating),
      reason: 'Feed rating should match');

  // Compare cloud
  _compareRssCloud(regular.cloud, efficient.cloud);

  // Compare image
  _compareRssImage(regular.image, efficient.image);

  // Compare skipHours and skipDays
  expect(efficient.skipHours, equals(regular.skipHours),
      reason: 'Feed skipHours should match');
  expect(efficient.skipDays, equals(regular.skipDays),
      reason: 'Feed skipDays should match');

  // Compare categories by value
  _compareRssCategories(regular.categories, efficient.categories);

  // Compare items
  expect(efficient.items?.length, equals(regular.items?.length),
      reason: 'Number of items should match');

  if (regular.items != null && efficient.items != null) {
    for (var i = 0; i < regular.items!.length; i++) {
      _compareRssItems(regular.items![i], efficient.items![i], i);
    }
  }
}

void _compareAtomLinks(List<AtomLink>? regular, List<AtomLink>? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull, reason: 'Efficient links should not be null');
  expect(regular, isNotNull, reason: 'Regular links should not be null');
  expect(efficient!.length, equals(regular!.length),
      reason: 'Number of links should match');

  for (var i = 0; i < regular.length; i++) {
    final regularLink = regular[i];
    final efficientLink = efficient[i];

    expect(efficientLink.href, equals(regularLink.href),
        reason: 'Link $i href should match');
    expect(efficientLink.rel, equals(regularLink.rel),
        reason: 'Link $i rel should match');
    expect(efficientLink.type, equals(regularLink.type),
        reason: 'Link $i type should match');
    expect(efficientLink.hreflang, equals(regularLink.hreflang),
        reason: 'Link $i hreflang should match');
    expect(efficientLink.title, equals(regularLink.title),
        reason: 'Link $i title should match');
    expect(efficientLink.length, equals(regularLink.length),
        reason: 'Link $i length should match');
  }
}

void _compareAtomPersons(
    List<AtomPerson>? regular, List<AtomPerson>? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull, reason: 'Efficient persons should not be null');
  expect(regular, isNotNull, reason: 'Regular persons should not be null');
  expect(efficient!.length, equals(regular!.length),
      reason: 'Number of persons should match');

  for (var i = 0; i < regular.length; i++) {
    final regularPerson = regular[i];
    final efficientPerson = efficient[i];

    expect(efficientPerson.name, equals(regularPerson.name),
        reason: 'Person $i name should match');
    expect(efficientPerson.email, equals(regularPerson.email),
        reason: 'Person $i email should match');
    expect(efficientPerson.uri, equals(regularPerson.uri),
        reason: 'Person $i uri should match');
  }
}

void _compareAtomCategories(
    List<AtomCategory>? regular, List<AtomCategory>? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull,
      reason: 'Efficient categories should not be null');
  expect(regular, isNotNull, reason: 'Regular categories should not be null');
  expect(efficient!.length, equals(regular!.length),
      reason: 'Number of categories should match');

  for (var i = 0; i < regular.length; i++) {
    final regularCategory = regular[i];
    final efficientCategory = efficient[i];
    expect(efficientCategory.term, equals(regularCategory.term),
        reason: 'Category $i term should match');
    expect(efficientCategory.scheme, equals(regularCategory.scheme),
        reason: 'Category $i scheme should match');
    expect(efficientCategory.label, equals(regularCategory.label),
        reason: 'Category $i label should match');
  }
}

void _compareAtomGenerator(AtomGenerator? regular, AtomGenerator? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull,
      reason: 'Efficient generator should not be null');
  expect(regular, isNotNull, reason: 'Regular generator should not be null');

  expect(efficient!.uri, equals(regular!.uri),
      reason: 'Generator uri should match');
  expect(efficient.version, equals(regular.version),
      reason: 'Generator version should match');
  expect(efficient.value, equals(regular.value),
      reason: 'Generator value should match');
}

void _compareAtomItems(AtomItem regular, AtomItem efficient, int index) {
  expect(efficient.id, equals(regular.id),
      reason: 'Item $index id should match');
  expect(efficient.title, equals(regular.title),
      reason: 'Item $index title should match');
  expect(efficient.updated, equals(regular.updated),
      reason: 'Item $index updated should match');
  expect(efficient.published, equals(regular.published),
      reason: 'Item $index published should match');
  expect(efficient.summary, equals(regular.summary),
      reason: 'Item $index summary should match');
  expect(efficient.content, equals(regular.content),
      reason: 'Item $index content should match');
  expect(efficient.rights, equals(regular.rights),
      reason: 'Item $index rights should match');

  _compareAtomLinks(regular.links, efficient.links);
  _compareAtomPersons(regular.authors, efficient.authors);
  _compareAtomPersons(regular.contributors, efficient.contributors);
  _compareAtomCategories(regular.categories, efficient.categories);
  _compareAtomSource(regular.source, efficient.source);
}

void _compareAtomSource(AtomSource? regular, AtomSource? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull, reason: 'Efficient source should not be null');
  expect(regular, isNotNull, reason: 'Regular source should not be null');

  expect(efficient!.id, equals(regular!.id), reason: 'Source id should match');
  expect(efficient.title, equals(regular.title),
      reason: 'Source title should match');
  expect(efficient.updated, equals(regular.updated),
      reason: 'Source updated should match');
  expect(efficient.icon, equals(regular.icon),
      reason: 'Source icon should match');
  expect(efficient.logo, equals(regular.logo),
      reason: 'Source logo should match');
}

void _compareRssCloud(RssCloud? regular, RssCloud? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull, reason: 'Efficient cloud should not be null');
  expect(regular, isNotNull, reason: 'Regular cloud should not be null');

  expect(efficient!.domain, equals(regular!.domain),
      reason: 'Cloud domain should match');
  expect(efficient.port, equals(regular.port),
      reason: 'Cloud port should match');
  expect(efficient.path, equals(regular.path),
      reason: 'Cloud path should match');
  expect(efficient.registerProcedure, equals(regular.registerProcedure),
      reason: 'Cloud registerProcedure should match');
  expect(efficient.protocol, equals(regular.protocol),
      reason: 'Cloud protocol should match');
}

void _compareRssImage(RssImage? regular, RssImage? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull, reason: 'Efficient image should not be null');
  expect(regular, isNotNull, reason: 'Regular image should not be null');

  expect(efficient!.url, equals(regular!.url),
      reason: 'Image url should match');
  expect(efficient.title, equals(regular.title),
      reason: 'Image title should match');
  expect(efficient.link, equals(regular.link),
      reason: 'Image link should match');
  expect(efficient.width, equals(regular.width),
      reason: 'Image width should match');
  expect(efficient.height, equals(regular.height),
      reason: 'Image height should match');
}

void _compareRssItems(RssItem regular, RssItem efficient, int index) {
  expect(efficient.title, equals(regular.title),
      reason: 'Item $index title should match');
  expect(efficient.description, equals(regular.description),
      reason: 'Item $index description should match');
  expect(efficient.link, equals(regular.link),
      reason: 'Item $index link should match');
  expect(efficient.author, equals(regular.author),
      reason: 'Item $index author should match');
  _compareRssCategories(regular.categories, efficient.categories,
      itemIndex: index);
  expect(efficient.comments, equals(regular.comments),
      reason: 'Item $index comments should match');
  expect(efficient.guid, equals(regular.guid),
      reason: 'Item $index guid should match');
  expect(efficient.pubDate, equals(regular.pubDate),
      reason: 'Item $index pubDate should match');
  _compareRssEnclosure(regular.enclosure, efficient.enclosure);
  _compareRssSource(regular.source, efficient.source);
  _compareRssContent(regular.content, efficient.content);
}

void _compareRssCategories(
    List<RssCategory>? regular, List<RssCategory>? efficient,
    {int? itemIndex}) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull,
      reason: 'Efficient categories should not be null');
  expect(regular, isNotNull, reason: 'Regular categories should not be null');
  expect(efficient!.length, equals(regular!.length),
      reason: 'Number of categories should match' +
          (itemIndex != null ? ' for item $itemIndex' : ''));
  for (var i = 0; i < regular.length; i++) {
    final r = regular[i];
    final e = efficient[i];
    expect(e.domain, equals(r.domain),
        reason: 'Category $i domain should match' +
            (itemIndex != null ? ' for item $itemIndex' : ''));
    expect(e.value, equals(r.value),
        reason: 'Category $i value should match' +
            (itemIndex != null ? ' for item $itemIndex' : ''));
  }
}

void _compareRssEnclosure(RssEnclosure? regular, RssEnclosure? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull,
      reason: 'Efficient enclosure should not be null');
  expect(regular, isNotNull, reason: 'Regular enclosure should not be null');

  expect(efficient!.url, equals(regular!.url),
      reason: 'Enclosure url should match');
  expect(efficient.length, equals(regular.length),
      reason: 'Enclosure length should match');
  expect(efficient.type, equals(regular.type),
      reason: 'Enclosure type should match');
}

void _compareRssSource(RssSource? regular, RssSource? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull, reason: 'Efficient source should not be null');
  expect(regular, isNotNull, reason: 'Regular source should not be null');

  expect(efficient!.url, equals(regular!.url),
      reason: 'Source url should match');
  expect(efficient.value, equals(regular.value),
      reason: 'Source value should match');
}

void _compareRssContent(RssContent? regular, RssContent? efficient) {
  if (regular == null && efficient == null) return;
  expect(efficient, isNotNull, reason: 'Efficient content should not be null');
  expect(regular, isNotNull, reason: 'Regular content should not be null');
  // RssContent only has value, images, videos, iframes, plainText
  expect(efficient!.value, equals(regular!.value),
      reason: 'Content value should match');
  expect(efficient.images, equals(regular.images),
      reason: 'Content images should match');
  expect(efficient.videos, equals(regular.videos),
      reason: 'Content videos should match');
  expect(efficient.iframes, equals(regular.iframes),
      reason: 'Content iframes should match');
  expect(efficient.plainText, equals(regular.plainText),
      reason: 'Content plainText should match');
}
