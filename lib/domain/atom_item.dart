import 'package:webfeed/domain/atom_category.dart';
import 'package:webfeed/domain/atom_link.dart';
import 'package:webfeed/domain/atom_person.dart';
import 'package:webfeed/domain/atom_source.dart';
import 'package:webfeed/domain/media/media.dart';
import 'package:webfeed/domain/rss_item.dart';
import 'package:webfeed/util/datetime.dart';
import 'package:webfeed/util/iterable.dart';
import 'package:xml/xml.dart';

class AtomItem {
  final String? id;
  final String? title;
  final DateTime? updated;

  final List<AtomPerson>? authors;
  final List<AtomLink>? links;
  final List<AtomCategory>? categories;
  final List<AtomPerson>? contributors;
  final AtomSource? source;
  final String? published;
  final String? content;
  final String? summary;
  final String? rights;
  final Media? media;

  AtomItem({
    this.id,
    this.title,
    this.updated,
    this.authors,
    this.links,
    this.categories,
    this.contributors,
    this.source,
    this.published,
    this.content,
    this.summary,
    this.rights,
    this.media,
  });

  /// Gets the best available image from the Atom item
  ///
  /// This attempts to find the most suitable image from various possible sources:
  /// - media:content with medium="image" and largest available resolution
  /// - media:thumbnail with largest available resolution
  /// - links with rel="enclosure" and image type
  /// - image from the source if available
  ///
  /// Returns null if no image is found.
  FeedImage? get image {
    // Try media:content items first (prefer those in media:group if available)
    if (media != null) {
      // First look for images in media:group
      if (media!.group != null && media!.group!.contents != null) {
        final mediaContents = media!.group!.contents!
            .where((content) =>
                content.medium == 'image' &&
                content.url != null &&
                content.url!.isNotEmpty)
            .toList();

        if (mediaContents.isNotEmpty) {
          // Sort by size (larger is better)
          mediaContents.sort((a, b) {
            final aSize = (a.width ?? 0) * (a.height ?? 0);
            final bSize = (b.width ?? 0) * (b.height ?? 0);
            return bSize.compareTo(aSize);
          });

          final bestContent = mediaContents.first;
          return FeedImage(
            url: bestContent.url!,
            width: bestContent.width,
            height: bestContent.height,
            type: bestContent.type,
            source: 'media:group/media:content',
          );
        }
      }

      // Then check standalone media:content
      if (media!.contents != null && media!.contents!.isNotEmpty) {
        final mediaContents = media!.contents!
            .where((content) =>
                content.medium == 'image' &&
                content.url != null &&
                content.url!.isNotEmpty)
            .toList();

        if (mediaContents.isNotEmpty) {
          // Sort by size (larger is better)
          mediaContents.sort((a, b) {
            final aSize = (a.width ?? 0) * (a.height ?? 0);
            final bSize = (b.width ?? 0) * (b.height ?? 0);
            return bSize.compareTo(aSize);
          });

          final bestContent = mediaContents.first;
          return FeedImage(
            url: bestContent.url!,
            width: bestContent.width,
            height: bestContent.height,
            type: bestContent.type,
            source: 'media:content',
          );
        }
      }

      // Check media:thumbnail
      if (media!.thumbnails != null && media!.thumbnails!.isNotEmpty) {
        final thumbnails = media!.thumbnails!
            .where((thumb) => thumb.url != null && thumb.url!.isNotEmpty)
            .toList();

        if (thumbnails.isNotEmpty) {
          // Sort by size (larger is better), but we need to parse string dimensions
          thumbnails.sort((a, b) {
            final aWidth = int.tryParse(a.width ?? '0') ?? 0;
            final aHeight = int.tryParse(a.height ?? '0') ?? 0;
            final bWidth = int.tryParse(b.width ?? '0') ?? 0;
            final bHeight = int.tryParse(b.height ?? '0') ?? 0;

            final aSize = aWidth * aHeight;
            final bSize = bWidth * bHeight;
            return bSize.compareTo(aSize);
          });

          final bestThumbnail = thumbnails.first;
          return FeedImage(
            url: bestThumbnail.url!,
            width: int.tryParse(bestThumbnail.width ?? ''),
            height: int.tryParse(bestThumbnail.height ?? ''),
            source: 'media:thumbnail',
          );
        }
      }
    }

    // Try enclosure links (links with rel="enclosure" and image type)
    if (links != null && links!.isNotEmpty) {
      final enclosureLinks = links!
          .where((link) =>
              link.rel == 'enclosure' &&
              link.href != null &&
              link.href!.isNotEmpty &&
              link.type != null &&
              (link.type!.startsWith('image/') || link.type == 'image'))
          .toList();

      if (enclosureLinks.isNotEmpty) {
        final (width, height) =
            _extractDimensionsFromUrl(enclosureLinks.first.href!) ??
                (null, null);
        return FeedImage(
          url: enclosureLinks.first.href!,
          width: width,
          height: height,
          type: enclosureLinks.first.type,
          source: 'atom:link[rel=enclosure]',
        );
      }
    }

    // Try image from source if available
    if (source != null && source!.image != null) {
      return source!.image;
    }

    // No image found
    return null;
  }

  /// Helper function to extract width and height from image URLs
  ///
  /// Looks for common patterns in URLs like:
  /// - /image_100x200.jpg
  /// - /image-width-100-height-200.jpg
  /// - /image_w100_h200.jpg
  /// - /image.jpg?w=100&h=200
  ///
  /// Returns a record with (width, height) if found, null otherwise
  static (int, int)? _extractDimensionsFromUrl(String url) {
    try {
      // Pattern 1: filename_WIDTHxHEIGHT.ext (e.g., image_300x200.jpg)
      final dimensionPattern1 = RegExp(r'_(\d+)x(\d+)\.');
      final match1 = dimensionPattern1.firstMatch(url);
      if (match1 != null) {
        final width = int.tryParse(match1.group(1)!);
        final height = int.tryParse(match1.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 2: filename-width-W-height-H.ext (e.g., image-width-300-height-200.jpg)
      final dimensionPattern2 = RegExp(r'-width-(\d+)-height-(\d+)\.');
      final match2 = dimensionPattern2.firstMatch(url);
      if (match2 != null) {
        final width = int.tryParse(match2.group(1)!);
        final height = int.tryParse(match2.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 3: filename_wW_hH.ext (e.g., image_w300_h200.jpg)
      final dimensionPattern3 = RegExp(r'_w(\d+)_h(\d+)\.');
      final match3 = dimensionPattern3.firstMatch(url);
      if (match3 != null) {
        final width = int.tryParse(match3.group(1)!);
        final height = int.tryParse(match3.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 4: query parameters (e.g., image.jpg?w=300&h=200 or image.jpg?width=300&height=200)
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final widthParam =
            uri.queryParameters['w'] ?? uri.queryParameters['width'];
        final heightParam =
            uri.queryParameters['h'] ?? uri.queryParameters['height'];

        if (widthParam != null && heightParam != null) {
          final width = int.tryParse(widthParam);
          final height = int.tryParse(heightParam);
          if (width != null && height != null) {
            return (width, height);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  factory AtomItem.parse(XmlElement element) {
    return AtomItem(
      id: element.findElements('id').firstOrNull?.text,
      title: element.findElements('title').firstOrNull?.text,
      updated: parseDateTime(element.findElements('updated').firstOrNull?.text),
      authors: element
          .findElements('author')
          .map((e) => AtomPerson.parse(e))
          .toList(),
      links:
          element.findElements('link').map((e) => AtomLink.parse(e)).toList(),
      categories: element
          .findElements('category')
          .map((e) => AtomCategory.parse(e))
          .toList(),
      contributors: element
          .findElements('contributor')
          .map((e) => AtomPerson.parse(e))
          .toList(),
      source: element
          .findElements('source')
          .map((e) => AtomSource.parse(e))
          .firstOrNull,
      published: element.findElements('published').firstOrNull?.text,
      content: element.findElements('content').firstOrNull?.text,
      summary: element.findElements('summary').firstOrNull?.text,
      rights: element.findElements('rights').firstOrNull?.text,
      media: Media.parse(element),
    );
  }
}
