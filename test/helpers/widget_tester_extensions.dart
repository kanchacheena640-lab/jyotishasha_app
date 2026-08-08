import 'package:flutter_test/flutter_test.dart';

extension WidgetTesterExtensions on WidgetTester {
  Future<void> pumpFrames(
    int count, {
    Duration duration = const Duration(milliseconds: 16),
  }) async {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'Must not be negative.');
    }

    for (var index = 0; index < count; index++) {
      await pump(duration);
    }
  }

  Future<void> pumpUntilFound(
    Finder finder, {
    int maxPumps = 20,
    Duration step = const Duration(milliseconds: 50),
  }) async {
    if (maxPumps < 1) {
      throw ArgumentError.value(maxPumps, 'maxPumps', 'Must be positive.');
    }

    for (var index = 0; index < maxPumps; index++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await pump(step);
    }

    fail('Finder did not match after $maxPumps pumps: $finder');
  }
}
