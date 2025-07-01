import 'package:webfeed/domain/dublin_core/dublin_core.dart';
import 'package:webfeed/domain/itunes/itunes.dart';
import 'package:webfeed/domain/media/media.dart';
import 'package:webfeed/domain/rss_category.dart';
import 'package:webfeed/domain/rss_content.dart';
import 'package:webfeed/domain/rss_enclosure.dart';
import 'package:webfeed/domain/rss_source.dart';
import 'package:webfeed/util/datetime.dart';
import 'package:webfeed/util/xml.dart';
import 'package:xml/xml.dart';

/// Represents an image from a feed or feed item
class FeedImage {
  /// URL of the image
  final String url;

  /// Optional width of the image (may be null if not available)
  final int? width;

  /// Optional height of the image (may be null if not available)
  final int? height;

  /// Optional image type/MIME type (may be null if not available)
  final String? type;

  /// Optional title of the image (may be null if not available)
  final String? title;

  /// Source where this image was found in the feed
  final String source;

  FeedImage({
    required this.url,
    this.width,
    this.height,
    this.type,
    this.title,
    required this.source,
  });
}

/// Represents a best image from a feed item (alias of FeedImage for backward compatibility)
typedef RssItemImage = FeedImage;

class RssItem {
  final String? title;
  final String? description;
  final String? link;

  final List<RssCategory>? categories;
  final String? guid;
  final DateTime? pubDate;
  final String? author;
  final String? comments;
  final RssSource? source;
  final RssContent? content;
  final Media? media;
  final RssEnclosure? enclosure;
  final DublinCore? dc;
  final Itunes? itunes;

  RssItem({
    this.title,
    this.description,
    this.link,
    this.categories,
    this.guid,
    this.pubDate,
    this.author,
    this.comments,
    this.source,
    this.content,
    this.media,
    this.enclosure,
    this.dc,
    this.itunes,
  });

  /// Gets the best available image from the RSS item
  ///
  /// This attempts to find the most suitable image from various possible sources:
  /// - media:content with medium="image" and largest available resolution
  /// - media:thumbnail with largest available resolution
  /// - itunes:image
  /// - enclosure with image type
  /// - image URL extracted from content
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
          var width = bestContent.width;
          var height = bestContent.height;
          if (width == null || height == null) {
            final dims = _extractDimensionsFromUrl(bestContent.url!);
            width ??= dims?.$1;
            height ??= dims?.$2;
          }
          return FeedImage(
            url: bestContent.url!,
            width: width,
            height: height,
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
          var width = bestContent.width;
          var height = bestContent.height;
          if (width == null || height == null) {
            final dims = _extractDimensionsFromUrl(bestContent.url!);
            width ??= dims?.$1;
            height ??= dims?.$2;
          }
          return FeedImage(
            url: bestContent.url!,
            width: width,
            height: height,
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
          var width = int.tryParse(bestThumbnail.width ?? '');
          var height = int.tryParse(bestThumbnail.height ?? '');
          if (width == null || height == null) {
            final dims = _extractDimensionsFromUrl(bestThumbnail.url!);
            width ??= dims?.$1;
            height ??= dims?.$2;
          }
          return FeedImage(
            url: bestThumbnail.url!,
            width: width,
            height: height,
            source: 'media:thumbnail',
          );
        }
      }
    }

    // Try iTunes image
    if (itunes != null &&
        itunes!.image != null &&
        itunes!.image!.href != null) {
      final (width, height) =
          _extractDimensionsFromUrl(itunes!.image!.href!) ?? (null, null);
      return FeedImage(
        url: itunes!.image!.href!,
        width: width,
        height: height,
        source: 'itunes:image',
      );
    }

    // Try enclosure (if it's an image type)
    if (enclosure != null && enclosure!.url != null) {
      final isImage = enclosure!.type != null &&
          (enclosure!.type!.startsWith('image/') || enclosure!.type == 'image');

      if (isImage) {
        final (width, height) =
            _extractDimensionsFromUrl(enclosure!.url!) ?? (null, null);
        return FeedImage(
          url: enclosure!.url!,
          width: width,
          height: height,
          type: enclosure!.type,
          source: 'enclosure',
        );
      }
    }

    // Try to extract from content
    if (content != null && content!.images.isNotEmpty) {
      final (width, height) =
          _extractDimensionsFromUrl(content!.images.first) ?? (null, null);
      return FeedImage(
        url: content!.images.first,
        width: width,
        height: height,
        source: 'content:encoded',
      );
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
      // Decode HTML entities in the URL (e.g., &amp;)
      final decodedUrl = decodeHtmlEntities(url);
      // Pattern 1: filename_WIDTHxHEIGHT.ext (e.g., image_300x200.jpg)
      final dimensionPattern1 = RegExp(r'_(\d+)x(\d+)\.');
      final match1 = dimensionPattern1.firstMatch(decodedUrl);
      if (match1 != null) {
        final width = int.tryParse(match1.group(1)!);
        final height = int.tryParse(match1.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 2: filename-width-W-height-H.ext (e.g., image-width-300-height-200.jpg)
      final dimensionPattern2 = RegExp(r'-width-(\d+)-height-(\d+)\.');
      final match2 = dimensionPattern2.firstMatch(decodedUrl);
      if (match2 != null) {
        final width = int.tryParse(match2.group(1)!);
        final height = int.tryParse(match2.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 3: filename_wW_hH.ext (e.g., image_w300_h200.jpg)
      final dimensionPattern3 = RegExp(r'_w(\d+)_h(\d+)\.');
      final match3 = dimensionPattern3.firstMatch(decodedUrl);
      if (match3 != null) {
        final width = int.tryParse(match3.group(1)!);
        final height = int.tryParse(match3.group(2)!);
        if (width != null && height != null) {
          return (width, height);
        }
      }

      // Pattern 4: query parameters (e.g., image.jpg?w=300&h=200 or image.jpg?width=300&height=200)
      final uri = Uri.tryParse(decodedUrl);
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

  factory RssItem.parse(XmlElement element) {
    try {
      return RssItem(
        title: _normalizeField(_getTextContent(element, 'title')),
        description: _normalizeField(_getTextContent(element, 'description')),
        link: _normalizeField(_getTextContent(element, 'link')),
        categories: findAllElementsWithNamespace(element, 'category')
            .map((e) => RssCategory.parse(e))
            .toList(),
        guid: _normalizeField(_getTextContent(element, 'guid')),
        pubDate: _parsePublishedDate(element),
        author: _normalizeField(_getTextContent(element, 'author') ??
            _getTextContent(element, 'creator') ??
            _getTextContent(element, 'dc:creator')),
        comments: _normalizeField(_getTextContent(element, 'comments')),
        source: _parseSource(element),
        content: _parseContent(element),
        media: Media.parse(element),
        enclosure: _parseEnclosure(element),
        dc: DublinCore.parse(element),
        itunes: Itunes.parse(element),
      );
    } catch (e) {
      // Provide a graceful fallback for malformed items
      return RssItem(
        title: 'Error parsing item',
        description: 'Failed to parse RSS item: ${e.toString()}',
      );
    }
  }

  // Helper method to get text content with namespace support
  static String? _getTextContent(XmlElement element, String tagName) {
    final foundElement = findDirectElementWithNamespace(element, tagName);
    return extractTextContent(foundElement);
  }

  // Helper method to normalize field values (decode HTML entities and handle empty strings)
  static String? _normalizeField(String? text) {
    if (text == null) return null;
    final decoded = decodeHtmlEntities(text);
    final trimmed = decoded.trim();
    return trimmed;
  }

  // Parse published date with fallbacks for different date field names
  static DateTime? _parsePublishedDate(XmlElement element) {
    // Try different field names in order of preference
    final dateFields = ['pubDate', 'published', 'pubdate', 'dc:date', 'date'];

    for (var field in dateFields) {
      final dateText = _getTextContent(element, field);
      if (dateText != null && dateText.isNotEmpty) {
        final parsedDate = parseDateTime(dateText);
        if (parsedDate != null) return parsedDate;
      }
    }

    return null;
  }

  // Parse source with better error handling
  static RssSource? _parseSource(XmlElement element) {
    try {
      final sourceElement = findElementWithNamespace(element, 'source');
      return sourceElement != null ? RssSource.parse(sourceElement) : null;
    } catch (e) {
      return null;
    }
  }

  // Parse content with support for different content formats
  static RssContent? _parseContent(XmlElement element) {
    // Try content:encoded first (standard RSS 2.0 content module)
    var contentElement = findElementWithNamespace(element, 'content:encoded');

    // Try content namespace as fallback
    if (contentElement == null) {
      contentElement = findElementWithNamespace(element, 'encoded');
    }

    // Try content tag as fallback
    if (contentElement == null) {
      contentElement = findElementWithNamespace(element, 'content');
    }

    // Fallback to extracting text directly from the element
    if (contentElement == null) {
      final rawContent = element.getElement('content')?.innerText;
      if (rawContent != null && rawContent.isNotEmpty) {
        return RssContent(rawContent, [], [], [], rawContent);
      }
    }

    return contentElement != null ? RssContent.parse(contentElement) : null;
  }

  // Parse enclosure with better error handling
  static RssEnclosure? _parseEnclosure(XmlElement element) {
    try {
      final enclosureElement = findElementWithNamespace(element, 'enclosure');
      return enclosureElement != null
          ? RssEnclosure.parse(enclosureElement)
          : null;
    } catch (e) {
      return null;
    }
  }
}
