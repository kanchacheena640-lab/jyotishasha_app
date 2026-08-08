import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String readProjectSource(String relativePath) {
  return File(relativePath).readAsStringSync();
}

String normalizeWhitespace(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void expectMarkersInOrder(String source, List<String> markers) {
  var searchFrom = 0;

  for (final marker in markers) {
    final index = source.indexOf(marker, searchFrom);
    expect(
      index,
      greaterThanOrEqualTo(0),
      reason: 'Expected to find "$marker" after offset $searchFrom.',
    );
    searchFrom = index + marker.length;
  }
}
