import 'dart:core';

import 'package:html_unescape/html_unescape.dart';
import 'package:webfeed/util/iterable.dart';
import 'package:xml/xml.dart';

// Singleton instance for HTML unescaping
final _htmlUnescape = HtmlUnescape();

Iterable<XmlElement>? findElements(
  XmlNode? node,
  String name, {
  bool recursive = false,
  String? namespace,
}) {
  try {
    if (recursive) {
      return node?.findAllElements(name, namespace: namespace);
    } else {
      return node?.findElements(name, namespace: namespace);
    }
  } on StateError {
    return null;
  }
}

/// Helper to find elements with a specific tag name, regardless of namespace prefix
Iterable<XmlElement> findAllElementsWithNamespace(
    XmlNode? node, String localName) {
  if (node == null) return const [];

  // First try the standard approach
  final standardResult = node.findAllElements(localName);
  if (standardResult.isNotEmpty) {
    return standardResult;
  }

  // Then look for elements with namespaces
  return node.findAllElements('*').where((element) {
    return element.name.local == localName ||
        element.name.qualified.endsWith(':$localName');
  });
}

/// Helper to find direct child elements with a specific tag name, regardless of namespace prefix
Iterable<XmlElement> findDirectElementsWithNamespace(
    XmlNode? node, String localName) {
  if (node == null) return const [];

  // First try the standard approach (direct children only)
  final standardResult = node.findElements(localName);
  if (standardResult.isNotEmpty) {
    return standardResult;
  }

  // Then look for direct child elements with namespaces
  return node.findElements('*').where((element) {
    return element.name.local == localName ||
        element.name.qualified.endsWith(':$localName');
  });
}

/// Gets the first element that matches the local name, regardless of namespace
XmlElement? findElementWithNamespace(XmlNode? node, String localName) {
  return findAllElementsWithNamespace(node, localName).firstOrNull;
}

/// Gets the first direct child element that matches the local name, regardless of namespace
XmlElement? findDirectElementWithNamespace(XmlNode? node, String localName) {
  return findDirectElementsWithNamespace(node, localName).firstOrNull;
}

/// Tries multiple possible element names and returns the first match
XmlElement? findElementWithAlternatives(
    XmlNode? node, List<String> possibleNames) {
  if (node == null) return null;

  for (var name in possibleNames) {
    final element = findElementWithNamespace(node, name);
    if (element != null) {
      return element;
    }
  }
  return null;
}

bool parseBoolLiteral(XmlElement element, String tagName) {
  var foundElement = element.findElements(tagName).firstOrNull;
  if (foundElement == null) return false;

  var v = foundElement.text.toLowerCase().trim();
  return ['yes', 'true', '1'].contains(v);
}

/// More robust parsing of boolean values from XML
bool parseBoolWithFallback(XmlNode? node, String tagName) {
  // First try direct element
  final element = findElementWithNamespace(node, tagName);
  if (element != null) {
    final text = element.text.toLowerCase().trim();
    return ['yes', 'true', '1'].contains(text);
  }

  // Try as attribute
  if (node is XmlElement) {
    final attrValue = node.getAttribute(tagName)?.toLowerCase().trim();
    if (attrValue != null) {
      return ['yes', 'true', '1'].contains(attrValue);
    }
  }

  return false;
}

/// Get an attribute value that might use a namespace prefix
String? getAttributeWithNamespace(XmlElement element, String attributeName) {
  // Try direct attribute first
  final directAttr = element.getAttribute(attributeName);
  if (directAttr != null) {
    return directAttr;
  }

  // Try with namespace prefix
  return element.attributes
      .where((attr) =>
          attr.name.local == attributeName ||
          attr.name.qualified.endsWith(':$attributeName'))
      .firstOrNull
      ?.value;
}

/// Strips CDATA wrapper if present, otherwise returns the string as is
/// Returns a tuple: (isCdata, value)
({bool isCdata, String value}) stripCdataWithFlag(String text) {
  final cdataPattern = RegExp(r'^\s*<!\[CDATA\[(.*)\]\]>\s*$', dotAll: true);
  final match = cdataPattern.firstMatch(text);
  if (match != null) {
    return (isCdata: true, value: match.group(1)?.trim() ?? '');
  }
  return (isCdata: false, value: text.trim());
}

/// Decodes HTML entities using comprehensive html_unescape package
String decodeHtmlEntities(String text) {
  final decoded = _htmlUnescape.convert(text);
  return decoded;
}

/// Comprehensive text extraction that properly handles CDATA sections and provides multiple fallbacks
/// This function tries multiple methods to extract text content from an XML element:
/// 1. Direct value (for simple text elements)
/// 2. Text content (handles CDATA automatically)
/// 3. Inner text (includes nested elements)
/// 4. Manual CDATA extraction as fallback
String? extractTextContent(XmlElement? element) {
  if (element == null) return null;

  // Explicitly check for XmlCDATA nodes and return their text directly
  for (final node in element.children) {
    if (node is XmlCDATA) {
      return decodeHtmlEntities(node.text).trim();
    }
  }

  // Method 1: Try direct value first (for simple text elements)
  final directValue = element.value?.trim();
  if (directValue != null && directValue.isNotEmpty) {
    final result = stripCdataWithFlag(directValue);
    return decodeHtmlEntities(result.value).trim();
  }

  // Method 2: Try text content (XML parser automatically handles CDATA)
  final textContent = element.text.trim();
  if (textContent.isNotEmpty) {
    final result = stripCdataWithFlag(textContent);
    return decodeHtmlEntities(result.value).trim();
  }

  // Method 3: Try inner text (includes nested elements)
  final innerText = element.innerText.trim();
  if (innerText.isNotEmpty) {
    final result = stripCdataWithFlag(innerText);
    return decodeHtmlEntities(result.value).trim();
  }

  // Method 4: Manual CDATA extraction as fallback
  final cdataContent = _extractCdataContent(element);
  if (cdataContent != null) {
    final result = stripCdataWithFlag(cdataContent);
    return decodeHtmlEntities(result.value).trim();
  }

  // If all else fails, return empty string for empty CDATA
  return '';
}

/// Manual CDATA extraction as a fallback method
/// This is used when the standard XML parsing methods don't work as expected
String? _extractCdataContent(XmlElement element) {
  try {
    // Get the raw XML string for this element
    final elementXml = element.toXmlString();

    // Look for CDATA sections in the element content
    final cdataPattern = RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true);
    final matches = cdataPattern.allMatches(elementXml);

    if (matches.isNotEmpty) {
      // If there are multiple CDATA sections, join them
      return matches.map((match) => match.group(1) ?? '').join('');
    }

    // If no CDATA found, try to extract content between opening and closing tags
    final tagName = element.name.local;
    final contentPattern = RegExp(
      '<$tagName[^>]*>(.*?)</$tagName>',
      dotAll: true,
    );
    final contentMatch = contentPattern.firstMatch(elementXml);

    if (contentMatch != null) {
      return contentMatch.group(1);
    }

    return null;
  } catch (e) {
    return null;
  }
}

/// Enhanced text extraction with namespace support
/// This function combines namespace-aware element finding with comprehensive text extraction
String? getTextContentWithNamespace(XmlNode? node, String tagName) {
  final element = findElementWithNamespace(node, tagName);
  return extractTextContent(element);
}
