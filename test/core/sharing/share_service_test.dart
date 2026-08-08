import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/sharing/share_service.dart';

void main() {
  group('ShareService.composeMessage', () {
    test('includes title, description, canonical URL, branding, Play Store, and website', () {
      const content = ShareableContent(
        title: 'Trisparsha Mahadwadashi, Yogini Ekadashi Tomorrow',
        description: 'A significant day for fasting and devotion.',
        canonicalUrl: 'https://jyotishasha.com/en/ekadashi/yogini',
        brandingTagline: 'Shared via Jyotishasha ✨',
        downloadAppLabel: 'Download the Jyotishasha app:',
        visitWebsiteLabel: 'Visit our website:',
      );

      final message = ShareService.composeMessage(content);

      expect(
        message,
        contains('Trisparsha Mahadwadashi, Yogini Ekadashi Tomorrow'),
      );
      expect(
        message,
        contains('A significant day for fasting and devotion.'),
      );
      expect(message, contains('https://jyotishasha.com/en/ekadashi/yogini'));
      expect(message, contains('Shared via Jyotishasha ✨'));
      expect(message, contains(ShareService.playStoreUrl));
      expect(message, contains(ShareService.websiteUrl));
      expect(message, contains('Download the Jyotishasha app:'));
      expect(message, contains('Visit our website:'));
    });

    test('follows Hindi labels when Hindi strings are supplied, not English', () {
      const content = ShareableContent(
        title: 'योगिनी एकादशी कल',
        brandingTagline: 'Jyotishasha के माध्यम से साझा किया गया ✨',
        downloadAppLabel: 'Jyotishasha ऐप डाउनलोड करें:',
        visitWebsiteLabel: 'हमारी वेबसाइट पर जाएँ:',
      );

      final message = ShareService.composeMessage(content);

      expect(message, contains('योगिनी एकादशी कल'));
      expect(message, contains('Jyotishasha के माध्यम से साझा किया गया ✨'));
      expect(message, contains('Jyotishasha ऐप डाउनलोड करें:'));
      expect(message, contains('हमारी वेबसाइट पर जाएँ:'));
      expect(message, isNot(contains('Download the')));
      expect(message, isNot(contains('Visit our website:')));
    });

    test('omits description and canonical URL sections when absent, never crashes', () {
      const content = ShareableContent(
        title: 'Title only',
        brandingTagline: 'Shared via Jyotishasha ✨',
        downloadAppLabel: 'Download the Jyotishasha app:',
        visitWebsiteLabel: 'Visit our website:',
      );

      final message = ShareService.composeMessage(content);

      expect(message, contains('Title only'));
      expect(message, contains(ShareService.playStoreUrl));
      expect(message, contains(ShareService.websiteUrl));
    });

    test('blank description and canonical URL are treated as absent', () {
      const content = ShareableContent(
        title: 'Title only',
        description: '   ',
        canonicalUrl: '',
        brandingTagline: 'Shared via Jyotishasha ✨',
        downloadAppLabel: 'Download the Jyotishasha app:',
        visitWebsiteLabel: 'Visit our website:',
      );

      final message = ShareService.composeMessage(content);
      final lines = message.split('\n');

      // Only title + blank + branding + download + website lines — no
      // stray blank-content lines from the empty description/URL.
      expect(lines.where((line) => line.trim().isEmpty).length, 1);
    });

    test('Play Store link targets the real Android package id', () {
      expect(
        ShareService.playStoreUrl,
        'https://play.google.com/store/apps/details?id=com.jyotishasha.app',
      );
    });
  });
}
