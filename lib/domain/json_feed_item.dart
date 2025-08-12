import 'package:webfeed/domain/json_feed_author.dart';
import 'package:webfeed/domain/json_feed_attachment.dart';
import 'package:webfeed/util/datetime.dart';
import 'package:webfeed/domain/rss_item.dart';

/// Represents an item in a JSON Feed
class JsonFeedItem {
  /// Unique identifier for the item
  final String? id;

  /// The URL of the item
  final String? url;

  /// The URL of the item on an external site
  final String? externalUrl;

  /// The title of the item
  final String? title;

  /// The HTML content of the item
  final String? contentHtml;

  /// The text content of the item
  final String? contentText;

  /// A summary of the item
  final String? summary;

  /// The URL of the main image for the item
  final String? image;

  /// The URL of the banner image for the item
  final String? bannerImage;

  /// The date the item was published
  final DateTime? datePublished;

  /// The date the item was modified
  final DateTime? dateModified;

  /// The authors of the item
  final List<JsonFeedAuthor>? authors;

  /// The tags for the item
  final List<String>? tags;

  /// The language of the item
  final String? language;

  /// The attachments for the item
  final List<JsonFeedAttachment>? attachments;

  JsonFeedItem({
    this.id,
    this.url,
    this.externalUrl,
    this.title,
    this.contentHtml,
    this.contentText,
    this.summary,
    this.image,
    this.bannerImage,
    this.datePublished,
    this.dateModified,
    this.authors,
    this.tags,
    this.language,
    this.attachments,
  });

  /// Creates a JsonFeedItem from a Map
  factory JsonFeedItem.fromMap(Map<String, dynamic> json) {
    return JsonFeedItem(
      id: json['id'] as String?,
      url: json['url'] as String?,
      externalUrl: json['external_url'] as String?,
      title: json['title'] as String?,
      contentHtml: json['content_html'] as String?,
      contentText: json['content_text'] as String?,
      summary: json['summary'] as String?,
      image: json['image'] as String?,
      bannerImage: json['banner_image'] as String?,
      datePublished: _parseDateTime(json['date_published']),
      dateModified: _parseDateTime(json['date_modified']),
      authors: json['authors'] != null
          ? (json['authors'] as List)
              .map((author) => JsonFeedAuthor.fromMap(author))
              .toList()
          : null,
      tags: json['tags'] != null ? (json['tags'] as List).cast<String>() : null,
      language: json['language'] as String?,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((attachment) => JsonFeedAttachment.fromMap(attachment))
              .toList()
          : null,
    );
  }

  /// Converts the JsonFeedItem to a Map
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (id != null) json['id'] = id;
    if (url != null) json['url'] = url;
    if (externalUrl != null) json['external_url'] = externalUrl;
    if (title != null) json['title'] = title;
    if (contentHtml != null) json['content_html'] = contentHtml;
    if (contentText != null) json['content_text'] = contentText;
    if (summary != null) json['summary'] = summary;
    if (image != null) json['image'] = image;
    if (bannerImage != null) json['banner_image'] = bannerImage;
    if (datePublished != null) {
      json['date_published'] = datePublished!.toIso8601String();
    }
    if (dateModified != null) {
      json['date_modified'] = dateModified!.toIso8601String();
    }
    if (authors != null) {
      json['authors'] = authors!.map((author) => author.toJson()).toList();
    }
    if (tags != null) json['tags'] = tags;
    if (language != null) json['language'] = language;
    if (attachments != null) {
      json['attachments'] =
          attachments!.map((attachment) => attachment.toJson()).toList();
    }

    return json;
  }

  /// Gets the best available image from the JSON Feed item
  ///
  /// This attempts to find the most suitable image from these sources:
  /// - image (primary item image)
  /// - bannerImage (banner image)
  /// - image extracted from content_html
  /// - image extracted from content_text
  ///
  /// Returns null if no image is found.
  FeedImage? get bestImage {
    // Try primary image first
    if (image != null && image!.isNotEmpty) {
      final (width, height) = _extractDimensionsFromUrl(image!) ?? (null, null);
      return FeedImage(
        url: image!,
        width: width,
        height: height,
        source: 'json:image',
      );
    }

    // Try banner image
    if (bannerImage != null && bannerImage!.isNotEmpty) {
      final (width, height) =
          _extractDimensionsFromUrl(bannerImage!) ?? (null, null);
      return FeedImage(
        url: bannerImage!,
        width: width,
        height: height,
        source: 'json:banner_image',
      );
    }

    // Try to extract image from HTML content
    if (contentHtml != null && contentHtml!.isNotEmpty) {
      final extractedImage = _extractImageFromHtml(contentHtml!);
      if (extractedImage != null) {
        final (width, height) =
            _extractDimensionsFromUrl(extractedImage) ?? (null, null);
        return FeedImage(
          url: extractedImage,
          width: width,
          height: height,
          source: 'json:content_html',
        );
      }
    }

    // Try to extract image from text content (might contain URLs)
    if (contentText != null && contentText!.isNotEmpty) {
      final extractedImage = _extractImageFromText(contentText!);
      if (extractedImage != null) {
        final (width, height) =
            _extractDimensionsFromUrl(extractedImage) ?? (null, null);
        return FeedImage(
          url: extractedImage,
          width: width,
          height: height,
          source: 'json:content_text',
        );
      }
    }

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
        final width = int.parse(match1.group(1)!);
        final height = int.parse(match1.group(2)!);
        return (width, height);
      }

      // Pattern 2: filename-width-WIDTH-height-HEIGHT.ext
      final dimensionPattern2 = RegExp(r'-width-(\d+)-height-(\d+)\.');
      final match2 = dimensionPattern2.firstMatch(url);
      if (match2 != null) {
        final width = int.parse(match2.group(1)!);
        final height = int.parse(match2.group(2)!);
        return (width, height);
      }

      // Pattern 3: filename_wWIDTH_hHEIGHT.ext
      final dimensionPattern3 = RegExp(r'_w(\d+)_h(\d+)\.');
      final match3 = dimensionPattern3.firstMatch(url);
      if (match3 != null) {
        final width = int.parse(match3.group(1)!);
        final height = int.parse(match3.group(2)!);
        return (width, height);
      }

      // Pattern 4: query parameters w=WIDTH&h=HEIGHT
      final dimensionPattern4 = RegExp(r'[?&]w=(\d+).*[?&]h=(\d+)');
      final match4 = dimensionPattern4.firstMatch(url);
      if (match4 != null) {
        final width = int.parse(match4.group(1)!);
        final height = int.parse(match4.group(2)!);
        return (width, height);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extracts image URL from HTML content
  static String? _extractImageFromHtml(String html) {
    try {
      // Look for img tags with simple pattern
      final imgPattern =
          RegExp(r'<img[^>]+src="([^"]+)"[^>]*>', caseSensitive: false);
      final match = imgPattern.firstMatch(html);
      if (match != null) {
        final url = match.group(1);
        if (url != null && _isImageUrl(url)) {
          return url;
        }
      }

      // Look for img tags with single quotes
      final imgPattern2 =
          RegExp(r"<img[^>]+src='([^']+)'[^>]*>", caseSensitive: false);
      final match2 = imgPattern2.firstMatch(html);
      if (match2 != null) {
        final url = match2.group(1);
        if (url != null && _isImageUrl(url)) {
          return url;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extracts image URL from text content
  static String? _extractImageFromText(String text) {
    try {
      // Look for URLs that end with common image extensions
      final urlPattern = RegExp(
          r'https?://[^\\s]+\\.(jpg|jpeg|png|gif|webp|svg|bmp)',
          caseSensitive: false);
      final match = urlPattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Checks if a URL is likely an image
  static bool _isImageUrl(String url) {
    final imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.svg',
      '.bmp'
    ];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  /// Parses a datetime string
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return parseDateTime(value);
    }

    return null;
  }

  @override
  String toString() {
    return 'JsonFeedItem(id: $id, title: $title, url: $url)';
  }
}
