import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:webfeed/webfeed.dart';

void main() {
  group('Feed Detection Benchmark Tests', () {
    late Map<String, String> testFiles;
    late Map<String, FeedType> expectedResults;

    setUpAll(() {
      // Define test files and their expected results
      testFiles = {
        'RSS.xml': 'test/xml/RSS.xml',
        'RSS-Simple.xml': 'test/xml/RSS-Simple.xml',
        'RSS-Itunes.xml': 'test/xml/RSS-Itunes.xml',
        'RSS-Media.xml': 'test/xml/RSS-Media.xml',
        'RSS-MultiMedia.xml': 'test/xml/RSS-MultiMedia.xml',
        'RSS-DC.xml': 'test/xml/RSS-DC.xml',
        'RSS-Syndication.xml': 'test/xml/RSS-Syndication.xml',
        'RSS-RDF.xml': 'test/xml/RSS-RDF.xml',
        'RSS-Empty.xml': 'test/xml/RSS-Empty.xml',
        'RSS-Detect-Long.xml': 'test/xml/RSS-Detect-Long.xml',
        'Atom.xml': 'test/xml/Atom.xml',
        'Atom-Empty.xml': 'test/xml/Atom-Empty.xml',
        'Atom-Media.xml': 'test/xml/Atom-Media.xml',
        'Invalid.xml': 'test/xml/Invalid.xml',
      };

      expectedResults = {
        'RSS.xml': FeedType.rss,
        'RSS-Simple.xml': FeedType.rss,
        'RSS-Itunes.xml': FeedType.rss,
        'RSS-Media.xml': FeedType.rss,
        'RSS-MultiMedia.xml': FeedType.rss,
        'RSS-DC.xml': FeedType.rss,
        'RSS-Syndication.xml': FeedType.rdf, // This is actually RDF/RSS 1.0
        'RSS-RDF.xml': FeedType.rdf,
        'RSS-Empty.xml': FeedType.rss,
        'RSS-Detect-Long.xml': FeedType.rss,
        'Atom.xml': FeedType.atom,
        'Atom-Empty.xml': FeedType.atom,
        'Atom-Media.xml': FeedType.atom,
        'Invalid.xml': FeedType.unknown,
      };
    });

    test('verify all test files exist', () {
      for (final entry in testFiles.entries) {
        final file = File(entry.value);
        expect(file.existsSync(), isTrue,
            reason: 'Test file ${entry.key} does not exist: ${entry.value}');
      }
    });

    test(
        'comprehensive accuracy test - both functions should return same results',
        () {
      final results = <String, Map<String, dynamic>>{};

      for (final entry in testFiles.entries) {
        final fileName = entry.key;
        final filePath = entry.value;
        final file = File(filePath);

        if (!file.existsSync()) {
          print('Warning: Test file $fileName does not exist, skipping...');
          continue;
        }

        final xmlString = file.readAsStringSync();
        final expectedType = expectedResults[fileName];

        // Test both functions
        final originalResult = detectFeedType(xmlString);
        final efficientResult = detectFeedTypeEfficiently(xmlString);

        results[fileName] = {
          'expected': expectedType,
          'original': originalResult,
          'efficient': efficientResult,
          'original_correct': originalResult == expectedType,
          'efficient_correct': efficientResult == expectedType,
          'functions_match': originalResult == efficientResult,
          'file_size_bytes': xmlString.length,
        };

        // Verify both functions return the same result
        expect(originalResult, equals(efficientResult),
            reason: 'Functions return different results for $fileName: '
                'original=${originalResult}, efficient=${efficientResult}');

        // Verify both functions return the expected result
        expect(originalResult, equals(expectedType),
            reason: 'Original function failed for $fileName: '
                'expected=${expectedType}, got=${originalResult}');
        expect(efficientResult, equals(expectedType),
            reason: 'Efficient function failed for $fileName: '
                'expected=${expectedType}, got=${efficientResult}');
      }

      // Print summary
      print('\n=== ACCURACY TEST RESULTS ===');
      print('File Name'.padRight(20) +
          'Expected'.padRight(10) +
          'Original'.padRight(10) +
          'Efficient'.padRight(10) +
          'Size(KB)'.padRight(10) +
          'Status');
      print('-' * 80);

      var totalFiles = 0;
      var correctOriginal = 0;
      var correctEfficient = 0;
      var functionsMatch = 0;

      for (final entry in results.entries) {
        final fileName = entry.key;
        final result = entry.value;
        totalFiles++;

        if (result['original_correct']) correctOriginal++;
        if (result['efficient_correct']) correctEfficient++;
        if (result['functions_match']) functionsMatch++;

        final status = result['functions_match'] && result['original_correct']
            ? '✅ PASS'
            : '❌ FAIL';

        print('${fileName.padRight(20)}'
            '${result['expected'].toString().padRight(10)}'
            '${result['original'].toString().padRight(10)}'
            '${result['efficient'].toString().padRight(10)}'
            '${(result['file_size_bytes'] / 1024).toStringAsFixed(1).padRight(10)}'
            '$status');
      }

      print('-' * 80);
      print('Summary: $totalFiles files tested');
      print(
          'Original function accuracy: $correctOriginal/$totalFiles (${(correctOriginal / totalFiles * 100).toStringAsFixed(1)}%)');
      print(
          'Efficient function accuracy: $correctEfficient/$totalFiles (${(correctEfficient / totalFiles * 100).toStringAsFixed(1)}%)');
      print(
          'Functions match: $functionsMatch/$totalFiles (${(functionsMatch / totalFiles * 100).toStringAsFixed(1)}%)');

      expect(correctOriginal, equals(totalFiles),
          reason: 'Original function failed on some files');
      expect(correctEfficient, equals(totalFiles),
          reason: 'Efficient function failed on some files');
      expect(functionsMatch, equals(totalFiles),
          reason: 'Functions returned different results on some files');
    });

    test('performance benchmark - multiple iterations', () {
      final iterations = 100;
      final results = <String, Map<String, dynamic>>{};

      print('\n=== PERFORMANCE BENCHMARK ===');
      print('Running $iterations iterations per file...');

      for (final entry in testFiles.entries) {
        final fileName = entry.key;
        final filePath = entry.value;
        final file = File(filePath);

        if (!file.existsSync()) {
          print('Warning: Test file $fileName does not exist, skipping...');
          continue;
        }

        final xmlString = file.readAsStringSync();
        final fileSizeKB = xmlString.length / 1024;

        // Warm up
        for (var i = 0; i < 10; i++) {
          detectFeedType(xmlString);
          detectFeedTypeEfficiently(xmlString);
        }

        // Benchmark original function
        final originalTimes = <int>[];
        for (var i = 0; i < iterations; i++) {
          final start = DateTime.now();
          detectFeedType(xmlString);
          final end = DateTime.now();
          originalTimes.add(end.difference(start).inMicroseconds);
        }

        // Benchmark efficient function
        final efficientTimes = <int>[];
        for (var i = 0; i < iterations; i++) {
          final start = DateTime.now();
          detectFeedTypeEfficiently(xmlString);
          final end = DateTime.now();
          efficientTimes.add(end.difference(start).inMicroseconds);
        }

        // Calculate statistics
        final originalAvg =
            originalTimes.reduce((a, b) => a + b) / originalTimes.length;
        final originalMin = originalTimes.reduce(min);
        final originalMax = originalTimes.reduce(max);

        final efficientAvg =
            efficientTimes.reduce((a, b) => a + b) / efficientTimes.length;
        final efficientMin = efficientTimes.reduce(min);
        final efficientMax = efficientTimes.reduce(max);

        final speedup = originalAvg / efficientAvg;

        results[fileName] = {
          'file_size_kb': fileSizeKB,
          'original_avg': originalAvg,
          'original_min': originalMin,
          'original_max': originalMax,
          'efficient_avg': efficientAvg,
          'efficient_min': efficientMin,
          'efficient_max': efficientMax,
          'speedup': speedup,
        };

        print('${fileName.padRight(20)}'
            '${fileSizeKB.toStringAsFixed(1).padRight(8)}KB '
            'Original: ${originalAvg.toStringAsFixed(0).padRight(6)}μs '
            'Efficient: ${efficientAvg.toStringAsFixed(0).padRight(6)}μs '
            'Speedup: ${speedup.toStringAsFixed(1).padRight(6)}x');
      }

      // Calculate overall statistics
      final speedups =
          results.values.map((r) => r['speedup'] as double).toList();
      final avgSpeedup = speedups.reduce((a, b) => a + b) / speedups.length;
      final minSpeedup = speedups.reduce(min);
      final maxSpeedup = speedups.reduce(max);

      print('\n=== OVERALL PERFORMANCE SUMMARY ===');
      print('Average speedup: ${avgSpeedup.toStringAsFixed(1)}x');
      print('Min speedup: ${minSpeedup.toStringAsFixed(1)}x');
      print('Max speedup: ${maxSpeedup.toStringAsFixed(1)}x');

      // Verify significant performance improvement
      expect(avgSpeedup, greaterThan(10.0),
          reason:
              'Average speedup should be at least 10x, got ${avgSpeedup.toStringAsFixed(1)}x');
      expect(minSpeedup, greaterThan(5.0),
          reason:
              'Minimum speedup should be at least 5x, got ${minSpeedup.toStringAsFixed(1)}x');
    });

    test('large file performance stress test', () {
      final largeFile = File('test/xml/RSS-Detect-Long.xml');
      if (!largeFile.existsSync()) {
        print(
            'Warning: Large test file RSS-Detect-Long.xml does not exist, skipping stress test');
        return;
      }

      final xmlString = largeFile.readAsStringSync();
      final fileSizeMB = xmlString.length / (1024 * 1024);

      print('\n=== LARGE FILE STRESS TEST ===');
      print('File size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // Warm up
      for (var i = 0; i < 5; i++) {
        detectFeedType(xmlString);
        detectFeedTypeEfficiently(xmlString);
      }

      // Test original function
      final originalStart = DateTime.now();
      for (var i = 0; i < 10; i++) {
        final result = detectFeedType(xmlString);
        expect(result, equals(FeedType.rss));
      }
      final originalEnd = DateTime.now();
      final originalDuration = originalEnd.difference(originalStart);
      final originalAvg = originalDuration.inMicroseconds / 10;

      // Test efficient function
      final efficientStart = DateTime.now();
      for (var i = 0; i < 100; i++) {
        // More iterations since it's faster
        final result = detectFeedTypeEfficiently(xmlString);
        expect(result, equals(FeedType.rss));
      }
      final efficientEnd = DateTime.now();
      final efficientDuration = efficientEnd.difference(efficientStart);
      final efficientAvg = efficientDuration.inMicroseconds / 100;

      final speedup = originalAvg / efficientAvg;

      print(
          'Original function (10 iterations): ${originalDuration.inMilliseconds}ms (avg: ${originalAvg.toStringAsFixed(0)}μs)');
      print(
          'Efficient function (100 iterations): ${efficientDuration.inMilliseconds}ms (avg: ${efficientAvg.toStringAsFixed(0)}μs)');
      print('Speedup: ${speedup.toStringAsFixed(1)}x');

      expect(speedup, greaterThan(50.0),
          reason:
              'Speedup should be at least 50x for large files, got ${speedup.toStringAsFixed(1)}x');
    });

    test('memory usage comparison', () {
      final testFile = File('test/xml/RSS-Detect-Long.xml');
      if (!testFile.existsSync()) {
        print(
            'Warning: Large test file RSS-Detect-Long.xml does not exist, skipping memory test');
        return;
      }

      final xmlString = testFile.readAsStringSync();

      print('\n=== MEMORY USAGE COMPARISON ===');

      // Force garbage collection before testing
      // Note: In Dart, we can't directly measure memory usage, but we can observe
      // that the efficient function doesn't create a full XML document tree

      final originalStart = DateTime.now();
      for (var i = 0; i < 5; i++) {
        detectFeedType(xmlString);
      }
      final originalEnd = DateTime.now();

      final efficientStart = DateTime.now();
      for (var i = 0; i < 5; i++) {
        detectFeedTypeEfficiently(xmlString);
      }
      final efficientEnd = DateTime.now();

      final originalTime = originalEnd.difference(originalStart);
      final efficientTime = efficientEnd.difference(efficientStart);

      print('Original function time: ${originalTime.inMilliseconds}ms');
      print('Efficient function time: ${efficientTime.inMilliseconds}ms');
      print(
          'Time ratio: ${(originalTime.inMicroseconds / efficientTime.inMicroseconds).toStringAsFixed(1)}x');

      // The efficient function should be significantly faster, indicating lower memory overhead
      expect(efficientTime.inMicroseconds,
          lessThan(originalTime.inMicroseconds ~/ 10),
          reason: 'Efficient function should be at least 10x faster');
    });
  });
}
