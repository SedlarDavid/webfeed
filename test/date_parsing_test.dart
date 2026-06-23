import 'package:test/test.dart';
import 'package:webfeed/util/datetime.dart';

void main() {
  group('DateTime parsing tests', () {
    test('Parse RFC 822 dates', () {
      // Standard RFC 822 format with GMT timezone
      final gmtDate = parseDateTime('Mon, 26 Mar 2018 14:00:00 GMT');
      expect(gmtDate, isNotNull);
      expect(gmtDate?.year, 2018);
      expect(gmtDate?.month, 3);
      expect(gmtDate?.day, 26);
      expect(gmtDate?.hour, 14);
      
      // With timezone offset
      final utcDate = parseDateTime('Mon, 26 Mar 2018 14:00:00 +0000');
      expect(utcDate, isNotNull);
      expect(utcDate?.year, 2018);
      expect(utcDate?.month, 3);
      expect(utcDate?.day, 26);
      expect(utcDate?.hour, 14);
      
      // With different timezone offset
      final dateWithOffset = parseDateTime('Mon, 26 Mar 2018 14:00:00 -0500');
      expect(dateWithOffset, isNotNull);
      expect(dateWithOffset?.year, 2018);
      expect(dateWithOffset?.month, 3);
      expect(dateWithOffset?.day, 26);
    });
    
    test('Parse dates with timezone abbreviations', () {
      // Test timezone abbreviation handling
      final pdtDate = parseDateTime('Mon, 26 Mar 2018 14:00:00 PDT');
      expect(pdtDate, isNotNull);
      expect(pdtDate?.year, 2018);
      expect(pdtDate?.month, 3);
      expect(pdtDate?.day, 26);
      
      // Test another timezone abbreviation
      final estDate = parseDateTime('Tue, 27 Mar 2018 09:00:00 EST');
      expect(estDate, isNotNull);
      expect(estDate?.year, 2018);
      expect(estDate?.month, 3);
      expect(estDate?.day, 27);
    });
    
    test('Parse ISO 8601 dates', () {
      // Standard ISO 8601 format
      final isoDate = parseDateTime('2018-03-26T14:00:00Z');
      expect(isoDate, isNotNull);
      expect(isoDate?.year, 2018);
      expect(isoDate?.month, 3);
      expect(isoDate?.day, 26);
      expect(isoDate?.hour, 14);
      
      // With milliseconds
      final isoDateWithMs = parseDateTime('2018-03-26T14:00:00.000Z');
      expect(isoDateWithMs, isNotNull);
      expect(isoDateWithMs?.year, 2018);
      expect(isoDateWithMs?.month, 3);
      expect(isoDateWithMs?.day, 26);
      expect(isoDateWithMs?.hour, 14);
      
      // With timezone offset
      final isoWithOffset = parseDateTime('2018-03-26T14:00:00+02:00');
      expect(isoWithOffset, isNotNull);
      expect(isoWithOffset?.year, 2018);
      expect(isoWithOffset?.month, 3);
      expect(isoWithOffset?.day, 26);
    });
    
    test('Parse dates with missing parts', () {
      // Missing timezone
      final missingTz = parseDateTime('Mon, 26 Mar 2018 14:00:00');
      expect(missingTz, isNotNull);
      expect(missingTz?.year, 2018);
      expect(missingTz?.month, 3);
      expect(missingTz?.day, 26);
      expect(missingTz?.hour, 14);
      
      // Missing seconds
      final missingSeconds = parseDateTime('Mon, 26 Mar 2018 14:00 +0000');
      expect(missingSeconds, isNotNull);
      expect(missingSeconds?.year, 2018);
      expect(missingSeconds?.month, 3);
      expect(missingSeconds?.day, 26);
      expect(missingSeconds?.hour, 14);
      
      // Missing day of week
      final missingDayOfWeek = parseDateTime('26 Mar 2018 14:00:00 GMT');
      expect(missingDayOfWeek, isNotNull);
      expect(missingDayOfWeek?.year, 2018);
      expect(missingDayOfWeek?.month, 3);
      expect(missingDayOfWeek?.day, 26);
      expect(missingDayOfWeek?.hour, 14);
    });
    
    test('Applies the timezone offset instead of the device timezone', () {
      // Regression: feeds with a +0000 offset (e.g. ABC News) were shifted by
      // the device's local timezone because the offset was parsed but ignored.
      // The parsed instant must be independent of where the test runs.
      final utc = parseDateTime('Mon, 03 Nov 2025 11:42:12 +0000');
      expect(utc?.toUtc(), DateTime.utc(2025, 11, 3, 11, 42, 12));

      // +1100 is 11 hours ahead of UTC -> 11:30 UTC.
      final ahead = parseDateTime('Mon, 03 Nov 2025 22:30:00 +1100');
      expect(ahead?.toUtc(), DateTime.utc(2025, 11, 3, 11, 30, 0));

      // -0500 is 5 hours behind UTC -> 19:00 UTC.
      final behind = parseDateTime('Mon, 26 Mar 2018 14:00:00 -0500');
      expect(behind?.toUtc(), DateTime.utc(2018, 3, 26, 19, 0, 0));

      // Half-hour offsets must also be honoured.
      final halfHour = parseDateTime('Mon, 03 Nov 2025 11:42:12 +0530');
      expect(halfHour?.toUtc(), DateTime.utc(2025, 11, 3, 6, 12, 12));

      // A timezone abbreviation maps to its offset.
      final gmt = parseDateTime('Mon, 03 Nov 2025 11:42:12 GMT');
      expect(gmt?.toUtc(), DateTime.utc(2025, 11, 3, 11, 42, 12));

      // A timezone-naive RFC822 value is assumed to be UTC.
      final naive = parseDateTime('Mon, 03 Nov 2025 11:42:12');
      expect(naive?.toUtc(), DateTime.utc(2025, 11, 3, 11, 42, 12));
    });

    test('ISO 8601 offsets resolve to the correct UTC instant', () {
      final iso = parseDateTime('2018-03-26T14:00:00+02:00');
      expect(iso?.toUtc(), DateTime.utc(2018, 3, 26, 12, 0, 0));

      // A timezone-naive ISO value is assumed to be UTC.
      final naiveIso = parseDateTime('2018-03-26T14:00:00');
      expect(naiveIso?.toUtc(), DateTime.utc(2018, 3, 26, 14, 0, 0));
    });

    test('Handle invalid dates gracefully', () {
      // Empty string
      expect(parseDateTime(''), isNull);
      
      // Null input
      expect(parseDateTime(null), isNull);
      
      // Nonsense date
      expect(parseDateTime('not a date'), isNull);
      
      // Partial date (too incomplete to parse)
      expect(parseDateTime('2018'), isNull);
    });
  });
}