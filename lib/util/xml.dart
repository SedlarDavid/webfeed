import 'dart:core';

import 'package:webfeed/util/iterable.dart';
import 'package:xml/xml.dart';

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

/// Gets the first element that matches the local name, regardless of namespace
XmlElement? findElementWithNamespace(XmlNode? node, String localName) {
  return findAllElementsWithNamespace(node, localName).firstOrNull;
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
  
  var v = foundElement.value?.toLowerCase().trim() ?? '';
  return ['yes', 'true'].contains(v);
}

/// More robust parsing of boolean values from XML
bool parseBoolWithFallback(XmlNode? node, String tagName) {
  // First try direct element
  final element = findElementWithNamespace(node, tagName);
  if (element != null) {
    final text = element.value?.toLowerCase().trim() ?? '';
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
      .firstOrNull?.value;
}
