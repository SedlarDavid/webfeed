import 'package:intl/intl.dart';

const rfc822DatePattern = 'EEE, dd MMM yyyy HH:mm:ss Z';

// Additional RFC822 date patterns to try
final List<String> _additionalRfc822Patterns = [
  'EEE, dd MMM yyyy HH:mm:ss',          // Missing timezone
  'dd MMM yyyy HH:mm:ss Z',             // Missing weekday
  'EEE, dd MMM yyyy HH:mm Z',           // Missing seconds
  'EEE, d MMM yyyy HH:mm:ss Z',         // Single-digit day
];

// Common timezone abbreviations mapping to UTC offsets
final Map<String, String> _timezoneAbbreviations = {
  'PDT': '-0700',
  'PST': '-0800',
  'EDT': '-0400',
  'EST': '-0500',
  'CDT': '-0500',
  'CST': '-0600',
  'MDT': '-0600',
  'MST': '-0700',
  'GMT': '+0000',
  'UTC': '+0000',
};

DateTime? parseDateTime(dateString) {
  if (dateString == null || dateString.toString().trim().isEmpty) return null;
  String normalizedDateString = _normalizeDateTime(dateString.toString());
  
  return _parseRfc822DateTime(normalizedDateString) ?? 
         _tryAdditionalRfc822Formats(normalizedDateString) ??
         _parseIso8601DateTime(normalizedDateString);
}

String _normalizeDateTime(String dateString) {
  String normalized = dateString.trim();
  
  // Handle timezone abbreviations by replacing them with UTC offsets
  for (var entry in _timezoneAbbreviations.entries) {
    if (normalized.endsWith(' ${entry.key}')) {
      return normalized.substring(0, normalized.length - entry.key.length - 1) + ' ' + entry.value;
    }
  }
  
  return normalized;
}

DateTime? _parseRfc822DateTime(String dateString) {
  try {
    final length = dateString.length.clamp(0, rfc822DatePattern.length);
    final trimmedPattern = rfc822DatePattern.substring(0, length);
    final format = DateFormat(trimmedPattern, 'en_US');
    return format.parse(dateString);
  } on FormatException {
    return null;
  } catch (e) {
    return null;
  }
}

DateTime? _tryAdditionalRfc822Formats(String dateString) {
  for (var pattern in _additionalRfc822Patterns) {
    try {
      final format = DateFormat(pattern, 'en_US');
      return format.parse(dateString);
    } catch (e) {
      // Try next pattern
    }
  }
  return null;
}

DateTime? _parseIso8601DateTime(dateString) {
  try {
    return DateTime.parse(dateString);
  } on FormatException {
    // Try to fix common ISO-8601 issues
    String fixedString = dateString;
    
    // Try removing fractional seconds if they're causing issues
    if (fixedString.contains('.') && !fixedString.contains('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(fixedString)) {
      final parts = fixedString.split('.');
      fixedString = parts[0] + 'Z'; // Assume UTC if no timezone specified
      try {
        return DateTime.parse(fixedString);
      } catch (e) {
        // Continue with other fixes
      }
    }
    
    return null;
  }
}
