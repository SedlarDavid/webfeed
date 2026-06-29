import 'package:intl/intl.dart';

// RFC822 patterns WITHOUT a trailing timezone token. The numeric offset is
// stripped and applied explicitly (see [_parseRfc822DateTime]) because
// `DateFormat` parses the `Z` field positionally but ignores its value,
// which would otherwise interpret the wall-clock in the device's local
// timezone and silently shift every timestamp.
const rfc822DatePattern = 'EEE, dd MMM yyyy HH:mm:ss Z';

final List<String> _rfc822PatternsWithoutZone = [
  'EEE, dd MMM yyyy HH:mm:ss', // Standard
  'dd MMM yyyy HH:mm:ss', // Missing weekday
  'EEE, dd MMM yyyy HH:mm', // Missing seconds
  'EEE, d MMM yyyy HH:mm:ss', // Single-digit day
  'EEE, d MMM yyyy HH:mm', // Single-digit day, missing seconds
  'd MMM yyyy HH:mm:ss', // Single-digit day, missing weekday
  'dd MMM yyyy HH:mm', // Missing weekday and seconds
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

// Matches a trailing numeric timezone offset, e.g. `+0000`, `-0500`, `+11:00`.
final RegExp _numericOffsetPattern = RegExp(r'([+-])(\d{2}):?(\d{2})$');

DateTime? parseDateTime(dateString) {
  if (dateString == null || dateString.toString().trim().isEmpty) return null;
  var normalizedDateString = _normalizeDateTime(dateString.toString());

  return _parseRfc822DateTime(normalizedDateString) ??
      _parseIso8601DateTime(normalizedDateString);
}

String _normalizeDateTime(String dateString) {
  var normalized = dateString.trim();

  // Handle timezone abbreviations by replacing them with UTC offsets
  for (var entry in _timezoneAbbreviations.entries) {
    if (normalized.endsWith(' ${entry.key}')) {
      return normalized.substring(0, normalized.length - entry.key.length - 1) +
          ' ' +
          entry.value;
    }
  }

  return normalized;
}

/// Splits a trailing numeric offset off [dateString].
///
/// Returns the [Duration] the wall-clock is ahead of UTC and the remaining
/// date string with the offset removed. When no explicit offset is present the
/// value is assumed to be UTC (`Duration.zero`), matching the RSS/Atom
/// convention of treating timezone-naive timestamps as UTC.
(Duration, String) _extractOffset(String dateString) {
  final trimmed = dateString.trim();
  final match = _numericOffsetPattern.firstMatch(trimmed);
  if (match == null) {
    return (Duration.zero, trimmed);
  }
  final sign = match.group(1) == '-' ? -1 : 1;
  final hours = int.parse(match.group(2)!);
  final minutes = int.parse(match.group(3)!);
  final offset = Duration(hours: hours, minutes: minutes) * sign;
  final stripped = trimmed.substring(0, match.start).trim();
  return (offset, stripped);
}

DateTime? _parseRfc822DateTime(String dateString) {
  final (offset, stripped) = _extractOffset(dateString);

  for (final pattern in _rfc822PatternsWithoutZone) {
    try {
      // Parse the wall-clock fields as UTC, then subtract the feed's offset to
      // get the true UTC instant. This keeps the result independent of the
      // device's local timezone.
      final wallClockAsUtc = DateFormat(pattern, 'en_US').parseUtc(stripped);
      return wallClockAsUtc.subtract(offset);
    } on FormatException {
      // Try the next pattern.
    } catch (e) {
      // Try the next pattern.
    }
  }
  return null;
}

DateTime? _parseIso8601DateTime(dateString) {
  try {
    // DateTime.parse honours an explicit offset / `Z` and returns a UTC
    // instant; a timezone-naive value is assumed to be UTC for consistency.
    final parsed = DateTime.parse(dateString);
    return parsed.isUtc ? parsed : DateTime.parse('${dateString}Z');
  } on FormatException {
    // Try to fix common ISO-8601 issues
    String fixedString = dateString;

    // Try removing fractional seconds if they're causing issues
    if (fixedString.contains('.') &&
        !fixedString.contains('Z') &&
        !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(fixedString)) {
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
