import 'dart:convert';

import 'package:webfeed/domain/json_feed.dart';

/// Utility class for parsing JSON Feeds with error handling and fallbacks
class JsonFeedParser {
  /// Parses a JSON Feed from a string with comprehensive error handling
  /// 
  /// This method attempts to parse the JSON feed and provides detailed error
  /// information if parsing fails. It also handles common edge cases and
  /// malformed JSON.
  /// 
  /// [jsonString] - The JSON string to parse
  /// [strict] - If true, enforces strict JSON Feed validation
  /// 
  /// Returns a [JsonFeed] object if successful
  /// 
  /// Throws [FormatException] if the JSON is malformed or invalid
  static JsonFeed parse(String jsonString, {bool strict = false}) {
    try {
      // Basic validation
      if (jsonString.trim().isEmpty) {
        throw FormatException('JSON string is empty');
      }

      // Try to parse as JSON first
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      // Validate JSON Feed structure
      if (strict) {
        _validateJsonFeedStructure(jsonMap);
      }

      return JsonFeed.fromMap(jsonMap);
    } on FormatException catch (e) {
      // Try to provide more helpful error messages
      if (e.message.contains('Unexpected character')) {
        throw FormatException('Invalid JSON format: ${e.message}');
      } else if (e.message.contains('Expected')) {
        throw FormatException('Malformed JSON: ${e.message}');
      }
      rethrow;
    } catch (e) {
      throw FormatException('Failed to parse JSON Feed: $e');
    }
  }

  /// Parses a JSON Feed from a string with lenient error handling
  /// 
  /// This method attempts to parse the JSON feed and returns null if parsing
  /// fails, making it suitable for scenarios where you want to gracefully
  /// handle parsing errors.
  /// 
  /// [jsonString] - The JSON string to parse
  /// 
  /// Returns a [JsonFeed] object if successful, null otherwise
  static JsonFeed? tryParse(String jsonString) {
    try {
      return parse(jsonString);
    } catch (e) {
      return null;
    }
  }

  /// Validates that a JSON object has the required JSON Feed structure
  /// 
  /// [jsonMap] - The JSON object to validate
  /// 
  /// Throws [FormatException] if validation fails
  static void _validateJsonFeedStructure(Map<String, dynamic> jsonMap) {
    // Check for required fields
    if (!jsonMap.containsKey('version')) {
      throw FormatException('JSON Feed must contain a "version" field');
    }

    if (!jsonMap.containsKey('items')) {
      throw FormatException('JSON Feed must contain an "items" field');
    }

    // Validate version format
    final version = jsonMap['version'];
    if (version is! String || !version.startsWith('https://jsonfeed.org/version/')) {
      throw FormatException('Invalid JSON Feed version format: $version');
    }

    // Validate items is an array
    final items = jsonMap['items'];
    if (items is! List) {
      throw FormatException('JSON Feed "items" field must be an array');
    }
  }

  /// Checks if a string is likely a JSON Feed
  /// 
  /// This is a lightweight check that doesn't require full parsing.
  /// Useful for quick content type detection.
  /// 
  /// [content] - The content string to check
  /// 
  /// Returns true if the content appears to be a JSON Feed
  static bool isLikelyJsonFeed(String content) {
    try {
      final trimmed = content.trim();
      
      // Must start and end with braces
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        return false;
      }

      // Must contain required JSON Feed fields
      final hasVersion = trimmed.contains('"version"') || trimmed.contains("'version'");
      final hasItems = trimmed.contains('"items"') || trimmed.contains("'items'");
      
      return hasVersion && hasItems;
    } catch (e) {
      return false;
    }
  }

  /// Extracts basic metadata from a JSON Feed without full parsing
  /// 
  /// This method provides a lightweight way to get basic information
  /// about a JSON Feed without parsing the entire structure.
  /// 
  /// [jsonString] - The JSON string to analyze
  /// 
  /// Returns a map with basic metadata, or null if extraction fails
  static Map<String, dynamic>? extractBasicMetadata(String jsonString) {
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      
      return {
        'version': jsonMap['version'],
        'title': jsonMap['title'],
        'description': jsonMap['description'],
        'homePageUrl': jsonMap['home_page_url'],
        'feedUrl': jsonMap['feed_url'],
        'language': jsonMap['language'],
        'itemCount': jsonMap['items'] is List ? (jsonMap['items'] as List).length : 0,
      };
    } catch (e) {
      return null;
    }
  }

  /// Sanitizes a JSON Feed string by removing problematic characters
  /// 
  /// This method attempts to clean up common issues that might prevent
  /// successful parsing, such as BOM characters or encoding issues.
  /// 
  /// [jsonString] - The JSON string to sanitize
  /// 
  /// Returns the sanitized JSON string
  static String sanitize(String jsonString) {
    var sanitized = jsonString;

    // Remove BOM characters
    if (sanitized.startsWith('\uFEFF')) {
      sanitized = sanitized.substring(1);
    }

    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');

    // Trim whitespace
    sanitized = sanitized.trim();

    return sanitized;
  }
}
