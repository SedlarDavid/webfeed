import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

/// A more comprehensive test runner for checking feed compatibility
/// This runner will test all feeds from feeds.md and create a detailed report
/// 
/// Usage: dart test/feed_compatibility_runner.dart
void main() async {
  print('WebFeed Compatibility Test Runner');
  print('================================\n');
  
  // Read feeds from feeds.md
  final feedsFile = File('feeds.md');
  if (!feedsFile.existsSync()) {
    print('Error: feeds.md file not found');
    exit(1);
  }
  
  final feedUrls = feedsFile.readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line.trim())
      .toList();
  
  print('Found ${feedUrls.length} feeds to test\n');
  
  // Create HTTP client
  final client = http.Client();
  
  // Results tracking
  final results = <String, dynamic>{
    'total': feedUrls.length,
    'successful': 0,
    'failed': 0,
    'skipped': 0,
    'rss': 0,
    'atom': 0,
    'details': <Map<String, dynamic>>[]
  };
  
  // Test each feed
  for (var i = 0; i < feedUrls.length; i++) {
    final url = feedUrls[i];
    final feedNum = i + 1;
    
    print('Testing feed #$feedNum: $url');
    
    final feedResult = <String, dynamic>{
      'url': url,
      'status': 'failed',
      'type': 'unknown',
      'title': null,
      'itemCount': 0,
      'error': null,
    };
    
    try {
      // Update URL to use HTTPS if it's using HTTP
      final actualUrl = url.startsWith('http:') 
          ? url.replaceFirst('http:', 'https:') 
          : url;
          
      // Fetch the feed
      final response = await client.get(Uri.parse(actualUrl))
          .timeout(Duration(seconds: 15));
          
      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
      
      final content = response.body;
      
      // Try to parse as RSS first
      try {
        final rssFeed = RssFeed.parse(content);
        
        // Update results
        results['successful'] = (results['successful'] as int) + 1;
        results['rss'] = (results['rss'] as int) + 1;
        
        // Update feed result
        feedResult['status'] = 'success';
        feedResult['type'] = 'RSS';
        feedResult['title'] = rssFeed.title;
        feedResult['itemCount'] = rssFeed.items?.length ?? 0;
        
        print('  ✓ Successfully parsed as RSS');
        print('  - Title: ${rssFeed.title}');
        print('  - Items: ${rssFeed.items?.length ?? 0}');
      } catch (e) {
        // If RSS parsing fails, try Atom
        try {
          final atomFeed = AtomFeed.parse(content);
          
          // Update results
          results['successful'] = (results['successful'] as int) + 1;
          results['atom'] = (results['atom'] as int) + 1;
          
          // Update feed result
          feedResult['status'] = 'success';
          feedResult['type'] = 'Atom';
          feedResult['title'] = atomFeed.title;
          feedResult['itemCount'] = atomFeed.items?.length ?? 0;
          
          print('  ✓ Successfully parsed as Atom');
          print('  - Title: ${atomFeed.title}');
          print('  - Items: ${atomFeed.items?.length ?? 0}');
        } catch (atomError) {
          // Both RSS and Atom parsing failed
          results['failed'] = (results['failed'] as int) + 1;
          feedResult['error'] = 'RSS Error: $e\nAtom Error: $atomError';
          
          print('  ✗ Failed to parse feed');
          print('  - RSS Error: $e');
          print('  - Atom Error: $atomError');
        }
      }
    } catch (e) {
      // Failed to fetch or other error
      results['skipped'] = (results['skipped'] as int) + 1;
      feedResult['status'] = 'skipped';
      feedResult['error'] = e.toString();
      
      print('  ✗ Failed to fetch feed: $e');
    }
    
    // Add feed result to details
    (results['details'] as List<Map<String, dynamic>>).add(feedResult);
    
    // Add a separator between feeds
    print('');
  }
  
  // Close the HTTP client
  client.close();
  
  // Generate summary
  print('\nTest Summary');
  print('===========');
  print('Total feeds tested: ${results['total']}');
  
  final successRate = (results['successful'] as int) * 100 / (results['total'] as int);
  print('Successfully parsed: ${results['successful']} (${successRate.toStringAsFixed(1)}%)');
  print('RSS feeds: ${results['rss']}');
  print('Atom feeds: ${results['atom']}');
  print('Failed to parse: ${results['failed']}');
  print('Skipped (network errors): ${results['skipped']}');
  
  // Save results to a JSON file
  final resultsFile = File('test_results.json');
  await resultsFile.writeAsString(JsonEncoder.withIndent('  ').convert(results));
  print('\nDetailed results saved to test_results.json');
  
  // Exit with success only if all feeds were parsed successfully
  exit(results['failed'] as int > 0 ? 1 : 0);
}