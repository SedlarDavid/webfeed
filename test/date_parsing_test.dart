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