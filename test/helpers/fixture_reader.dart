import 'dart:convert';
import 'dart:io';

Future<String> readFixture(String relativePath) {
  return File('test/fixtures/$relativePath').readAsString();
}

Future<Map<String, dynamic>> readJsonObjectFixture(String relativePath) async {
  final value = jsonDecode(await readFixture(relativePath));
  if (value is! Map<String, dynamic>) {
    throw FormatException(
      'Expected a JSON object in test/fixtures/$relativePath.',
    );
  }
  return value;
}

Future<List<dynamic>> readJsonListFixture(String relativePath) async {
  final value = jsonDecode(await readFixture(relativePath));
  if (value is! List<dynamic>) {
    throw FormatException(
      'Expected a JSON list in test/fixtures/$relativePath.',
    );
  }
  return value;
}
