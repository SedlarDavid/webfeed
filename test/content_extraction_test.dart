import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:webfeed/domain/rss_content.dart';

void main() {
  group('RssContent extraction tests', () {
    test('Extract images from HTML content', () {
      final xmlString = '''
        <content:encoded>
          <![CDATA[
            <p>This is a test paragraph with an image.</p>
            <img src="https://example.com/image1.jpg" alt="Test Image 1" />
            <div>
              <img src="https://example.com/image2.jpg" width="500" height="300" />
            </div>
            <p>Another paragraph with a differently formatted image:</p>
            <img class="test-class" src='https://example.com/image3.jpg' />
          ]]>
        </content:encoded>
      ''';
      
      final document = XmlDocument.parse(xmlString);
      final element = document.findElements('content:encoded').first;
      final content = RssContent.parse(element);
      
      expect(content.images.length, 3);
      expect(content.images, contains('https://example.com/image1.jpg'));
      expect(content.images, contains('https://example.com/image2.jpg'));
      expect(content.images, contains('https://example.com/image3.jpg'));
    });
    
    test('Extract CSS background images', () {
      final xmlString = '''
        <content:encoded>
          <![CDATA[
            <div style="background-image: url('https://example.com/bg1.jpg');">
              Background div
            </div>
            <span style="background-image:url(https://example.com/bg2.jpg)"></span>
          ]]>
        </content:encoded>
      ''';
      
      final document = XmlDocument.parse(xmlString);
      final element = document.findElements('content:encoded').first;
      final content = RssContent.parse(element);
      
      // We currently only match URL patterns with quotes, so only bg1 should match
      expect(content.images, contains('https://example.com/bg1.jpg'));
    });
    
    test('Extract videos from HTML content', () {
      final xmlString = '''
        <content:encoded>
          <![CDATA[
            <video controls>
              <source src="https://example.com/video1.mp4" type="video/mp4">
              Your browser does not support the video tag.
            </video>
            <p>Another video:</p>
            <video width="320" height="240" controls>
              <source src="https://example.com/video2.mp4" type="video/mp4">
            </video>
          ]]>
        </content:encoded>
      ''';
      
      final document = XmlDocument.parse(xmlString);
      final element = document.findElements('content:encoded').first;
      final content = RssContent.parse(element);
      
      expect(content.videos.length, 2);
      expect(content.videos, contains('https://example.com/video1.mp4'));
      expect(content.videos, contains('https://example.com/video2.mp4'));
    });
    
    test('Extract iframes from HTML content', () {
      final xmlString = '''
        <content:encoded>
          <![CDATA[
            <iframe src="https://www.youtube.com/embed/abc123" width="560" height="315" frameborder="0"></iframe>
            <p>Another iframe:</p>
            <iframe src='https://player.vimeo.com/video/123456'></iframe>
          ]]>
        </content:encoded>
      ''';
      
      final document = XmlDocument.parse(xmlString);
      final element = document.findElements('content:encoded').first;
      final content = RssContent.parse(element);
      
      expect(content.iframes.length, 2);
      expect(content.iframes, contains('https://www.youtube.com/embed/abc123'));
      expect(content.iframes, contains('https://player.vimeo.com/video/123456'));
    });
    
    test('Convert HTML to plain text', () {
      final xmlString = '''
        <content:encoded>
          <![CDATA[
            <h1>This is a heading</h1>
            <p>This is a paragraph with <strong>bold text</strong> and a <a href="https://example.com">link</a>.</p>
            <ul>
              <li>List item 1</li>
              <li>List item 2</li>
            </ul>
            <p>Some text with &quot;quotes&quot; and &amp; ampersand.</p>
          ]]>
        </content:encoded>
      ''';
      
      final document = XmlDocument.parse(xmlString);
      final element = document.findElements('content:encoded').first;
      final content = RssContent.parse(element);
      
      expect(content.plainText, isNotNull);
      expect(content.plainText, contains('This is a heading'));
      expect(content.plainText, contains('This is a paragraph with bold text and a link.'));
      expect(content.plainText, contains('- List item 1'));
      expect(content.plainText, contains('- List item 2'));
      expect(content.plainText, contains('Some text with "quotes" and & ampersand.'));
      
      // Should not contain HTML tags
      expect(content.plainText, isNot(contains('<')));
      expect(content.plainText, isNot(contains('>')));
    });
    
    test('Handle empty content', () {
      final xmlString = '''
        <content:encoded></content:encoded>
      ''';
      
      final document = XmlDocument.parse(xmlString);
      final element = document.findElements('content:encoded').first;
      final content = RssContent.parse(element);
      
      expect(content.value, '');
      expect(content.images, isEmpty);
      expect(content.videos, isEmpty);
      expect(content.iframes, isEmpty);
      expect(content.plainText, isNull);
    });
  });
}