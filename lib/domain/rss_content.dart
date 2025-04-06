import 'package:xml/xml.dart';

/// For RSS Content Module:
///
/// - `xmlns:content="http://purl.org/rss/1.0/modules/content/"`
///
class RssContent {
  final String value;
  final List<String> images;
  final List<String> videos;
  final List<String> iframes;
  final String? plainText;

  RssContent(this.value, this.images, this.videos, this.iframes, this.plainText);

  factory RssContent.parse(XmlElement element) {
    final content = element.value ?? '';
    
    // Extract images
    final images = <String>[];
    final imageRegExp = RegExp(
      '<img[^>]*src=[\'"]([^\'"]+)[\'"]',
      caseSensitive: false,
      multiLine: true,
    );
    
    imageRegExp.allMatches(content).forEach((match) {
      final imageUrl = match.group(1);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images.add(imageUrl);
      }
    });
    
    // Extract background images
    final cssImageRegExp = RegExp(
      'background-image:\\s*url\\([\'"]([^\'"]+)[\'"]',
      caseSensitive: false,
      multiLine: true,
    );
    
    cssImageRegExp.allMatches(content).forEach((match) {
      final imageUrl = match.group(1);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images.add(imageUrl);
      }
    });
    
    // Extract videos
    final videos = <String>[];
    final videoRegExp = RegExp(
      '<source[^>]*src=[\'"]([^\'"]+)[\'"]',
      caseSensitive: false,
      multiLine: true,
    );
    
    videoRegExp.allMatches(content).forEach((match) {
      final videoUrl = match.group(1);
      if (videoUrl != null && videoUrl.isNotEmpty) {
        videos.add(videoUrl);
      }
    });
    
    // Extract iframes
    final iframes = <String>[];
    final iframeRegExp = RegExp(
      '<iframe[^>]*src=[\'"]([^\'"]+)[\'"]',
      caseSensitive: false,
      multiLine: true,
    );
    
    iframeRegExp.allMatches(content).forEach((match) {
      final iframeUrl = match.group(1);
      if (iframeUrl != null && iframeUrl.isNotEmpty) {
        iframes.add(iframeUrl);
      }
    });
    
    // Generate plain text version
    final plainText = _convertHtmlToPlainText(content);
    
    return RssContent(content, images, videos, iframes, plainText);
  }
  
  /// Simple method to convert HTML to plain text by removing tags
  static String? _convertHtmlToPlainText(String? html) {
    if (html == null || html.isEmpty) return null;
    
    // Replace common HTML entities
    var text = html
        .replaceAll(RegExp('<br\\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp('<p[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp('<div[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp('<li[^>]*>', caseSensitive: false), '\n- ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    
    // Remove all other HTML tags
    text = text.replaceAll(RegExp('<[^>]*>', multiLine: true), '');
    
    // Normalize whitespace
    text = text.replaceAll(RegExp('\n{3,}'), '\n\n');
    
    return text.trim();
  }
}