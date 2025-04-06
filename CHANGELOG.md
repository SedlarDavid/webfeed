# Changelog

## [0.8.0] - Unreleased
### Enhanced Feed Compatibility
- **Improved namespace handling** for better feed format compatibility
- **Enhanced date parsing** with support for multiple date formats and timezone abbreviations
- **Robust error recovery** with graceful handling of malformed feeds
- **Rich content extraction** from HTML including images, videos, and embeds
- **Plain text conversion** of HTML content
- **Added feed type detection** to automatically identify feed formats

### RSS Improvements
- Added support for various date formats in feed items
- Improved atom:link detection with namespace prefix awareness
- Enhanced error handling with fallback options for malformed feeds
- Better handling of RSS 1.0 (RDF) feeds
- Support for alternative element paths and naming conventions

### Feed Type Detection
- Added `detectFeedType()` function to automatically identify feed formats
- Support for RSS 2.0, RSS 1.0 (RDF), and Atom feed detection
- Enum `FeedType` to represent different feed types
- Updated example code to demonstrate feed type detection usage

### Content Processing
- Enhanced `RssContent` class with extraction of images, videos, and embeds
- Added plain text conversion of HTML content
- Improved image extraction with better regex patterns

### Other Changes
- Updated documentation with more examples and usage information
- Code refactoring for better maintainability
- Additional helper methods for XML parsing

## [0.7.0](https://pub.dartlang.org/packages/webfeed/versions/0.7.0)
- Null safety migration [#50](https://github.com/witochandra/webfeed/pull/50)
- Parse duration if not empty [#39](https://github.com/witochandra/webfeed/pull/39)

## [0.6.0](https://pub.dartlang.org/packages/webfeed/versions/0.6.0)
- Refactor util/xml.dart
- Support RDF feed
- Support Syndication namespace

## [0.5.2](https://pub.dartlang.org/packages/webfeed/versions/0.5.2)
- Lower the xml package version constraints

## [0.5.1](https://pub.dartlang.org/packages/webfeed/versions/0.5.1)
- Support iTunes namespace [#19](https://github.com/witochandra/webfeed/pull/19)
- Parse date strings into DateTime [#22](https://github.com/witochandra/webfeed/pull/22)
- Add created & modified into dublin core namespace [#27](https://github.com/witochandra/webfeed/pull/27)
- Upgrade xml package [#28](https://github.com/witochandra/webfeed/issues/28) 
- Fix linting warnings

## [0.4.2](https://pub.dartlang.org/packages/webfeed/versions/0.4.2)
### Fixed
- Bad import in `rss_content.dart` & `rss_source.dart`

## [0.4.1](https://pub.dartlang.org/packages/webfeed/versions/0.4.1)
### Added
- Support `author` in RssFeed

## [0.4.0](https://pub.dartlang.org/packages/webfeed/versions/0.4.0)
### Added
- Support for dublin core namespace
- Support enclosure in rss item
- Set minimum dart version into 2

## [0.3.0](https://pub.dartlang.org/packages/webfeed/versions/0.3.0)
### Added
- Support for image namespace
