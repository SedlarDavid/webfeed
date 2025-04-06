import 'dart:io';

import 'package:http/io_client.dart';
import 'package:webfeed/webfeed.dart';

/// Basic example of parsing RSS and Atom feeds
/// 
/// For a more comprehensive example with multiple feeds and error handling,
/// see feed_processor.dart in the same directory.
void main() async {
  print('WebFeed Basic Example');
  print('===================\n');
  print('This is a basic example. For processing multiple feeds with');
  print('robust error handling, run: "dart example/feed_processor.dart"\n');
  
  final client = IOClient(HttpClient()
    ..badCertificateCallback =
        ((X509Certificate cert, String host, int port) => true));

  try {
    // Example 1: Parse RSS feed
    print('Fetching RSS feed...');
    var response = await client.get(
        Uri.parse('https://developer.apple.com/news/releases/rss/releases.rss'));
    
    if (response.statusCode == 200) {
      var channel = RssFeed.parse(response.body);
      
      print('Feed Title: ${channel.title}');
      print('Feed Description: ${channel.description}');
      print('Feed Link: ${channel.link}');
      
      if (channel.items != null && channel.items!.isNotEmpty) {
        print('\nLatest item:');
        final item = channel.items!.first;
        print('Title: ${item.title}');
        print('Published: ${item.pubDate}');
        print('Link: ${item.link}');
        
        if (item.content != null) {
          print('Content has ${item.content!.images.length} images');
          if (item.content!.plainText != null) {
            final previewText = item.content!.plainText!.length > 100
                ? '${item.content!.plainText!.substring(0, 100)}...'
                : item.content!.plainText;
            print('Content preview: $previewText');
          }
        }
      }
    }

    // Example 2: Parse Atom feed
    print('\nFetching Atom feed...');
    response = await client.get(Uri.parse('https://www.theverge.com/rss/index.xml'));
    
    if (response.statusCode == 200) {
      var feed = AtomFeed.parse(response.body);
      
      print('Feed Title: ${feed.title}');
      print('Feed ID: ${feed.id}');
      print('Feed Updated: ${feed.updated}');
      
      if (feed.items != null && feed.items!.isNotEmpty) {
        print('\nLatest entry:');
        final item = feed.items!.first;
        print('Title: ${item.title}');
        print('Published: ${item.published}');
        print('Updated: ${item.updated}');
        if (item.links != null && item.links!.isNotEmpty) {
          print('Link: ${item.links!.first.href}');
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
