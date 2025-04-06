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

  factory RssItem.parse(XmlElement element) {
    try {
      return RssItem(
        title: _getTextContent(element, 'title'),
        description: _getTextContent(element, 'description'),
        link: _getTextContent(element, 'link'),
        
        categories: findAllElementsWithNamespace(element, 'category')
            .map((e) => RssCategory.parse(e))
            .toList(),
            
        guid: _getTextContent(element, 'guid'),
        
        // Try multiple date fields with different names
        pubDate: _parsePublishedDate(element),
        
        // Try multiple author fields with different names
        author: _getTextContent(element, 'author') ?? 
                _getTextContent(element, 'creator') ??
                _getTextContent(element, 'dc:creator'),
                
        comments: _getTextContent(element, 'comments'),
        
        source: _parseSource(element),
        
        // Parse content with fallbacks for different formats
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
    final foundElement = findElementWithNamespace(element, tagName);
    return foundElement != null ? foundElement.value?.trim() : null;
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
    
    return contentElement != null ? RssContent.parse(contentElement) : null;
  }
  
  // Parse enclosure with better error handling
  static RssEnclosure? _parseEnclosure(XmlElement element) {
    try {
      final enclosureElement = findElementWithNamespace(element, 'enclosure');
      return enclosureElement != null ? RssEnclosure.parse(enclosureElement) : null;
    } catch (e) {
      return null;
    }
  }
}
