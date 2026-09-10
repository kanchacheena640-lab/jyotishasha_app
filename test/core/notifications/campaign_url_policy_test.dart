import 'package:flutter_test/flutter_test.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';

/// P3E -- client-side mirror of the backend's OWN Campaign C WEB_URL
/// allowlist (`notifications/campaign_service.py::WEBSITE_HOSTS`/
/// `YOUTUBE_URL`/`valid_url()`, read directly from the backend repo, not
/// guessed). These tests exist to prove [CampaignUrlPolicy] fails closed
/// on every category of unsafe/unapproved input the task explicitly
/// named -- especially lookalike hosts that a naive substring/`contains`
/// check would wrongly accept, which is exactly why this uses [Uri.host]
/// exact-[Set]-membership instead.
void main() {
  group('CampaignUrlPolicy.isApproved', () {
    test('approves the bare jyotishasha.com host over HTTPS', () {
      expect(
        CampaignUrlPolicy.isApproved('https://jyotishasha.com/some/article'),
        isTrue,
      );
    });

    test('approves the www.jyotishasha.com host over HTTPS', () {
      expect(
        CampaignUrlPolicy.isApproved(
          'https://www.jyotishasha.com/some/article',
        ),
        isTrue,
      );
    });

    test('approves the exact approved YouTube channel URL', () {
      expect(
        CampaignUrlPolicy.isApproved('https://www.youtube.com/@jyotishasha'),
        isTrue,
      );
    });

    test(
      'approves the YouTube URL with a tolerated trailing slash '
      '(mirrors backend own rstrip("/") comparison)',
      () {
        expect(
          CampaignUrlPolicy.isApproved('https://www.youtube.com/@jyotishasha/'),
          isTrue,
        );
      },
    );

    test(
      'rejects any OTHER YouTube URL -- this is an exact-URL match, not a '
      'youtube.com host allowlist',
      () {
        expect(
          CampaignUrlPolicy.isApproved('https://www.youtube.com/@someoneelse'),
          isFalse,
        );
        expect(
          CampaignUrlPolicy.isApproved('https://youtube.com/@jyotishasha'),
          isFalse,
        );
        expect(
          CampaignUrlPolicy.isApproved(
            'https://www.youtube.com/watch?v=abc123',
          ),
          isFalse,
        );
      },
    );

    test('rejects plain HTTP -- HTTPS only', () {
      expect(
        CampaignUrlPolicy.isApproved('http://jyotishasha.com/some/article'),
        isFalse,
      );
    });

    test(
      'rejects lookalike host jyotishasha.com.evil.example -- proper URI '
      'host parsing, never substring matching',
      () {
        expect(
          CampaignUrlPolicy.isApproved(
            'https://jyotishasha.com.evil.example/phish',
          ),
          isFalse,
        );
      },
    );

    test(
      'rejects lookalike host eviljyotishasha.com -- exact host equality, '
      'never endsWith/contains',
      () {
        expect(
          CampaignUrlPolicy.isApproved('https://eviljyotishasha.com/phish'),
          isFalse,
        );
      },
    );

    test(
      'rejects a jyotishasha.com PATH lookalike on an unrelated host -- '
      'the path is irrelevant, only the host is checked',
      () {
        expect(
          CampaignUrlPolicy.isApproved(
            'https://evil.example/jyotishasha.com/phish',
          ),
          isFalse,
        );
      },
    );

    test('rejects an unrelated subdomain not in the exact allowlist', () {
      expect(
        CampaignUrlPolicy.isApproved('https://blog.jyotishasha.com/post'),
        isFalse,
      );
    });

    test('rejects javascript: scheme', () {
      expect(
        CampaignUrlPolicy.isApproved('javascript:alert(document.cookie)'),
        isFalse,
      );
    });

    test('rejects data: scheme', () {
      expect(
        CampaignUrlPolicy.isApproved(
          'data:text/html,<script>alert(1)</script>',
        ),
        isFalse,
      );
    });

    test('rejects file: scheme', () {
      expect(CampaignUrlPolicy.isApproved('file:///etc/passwd'), isFalse);
    });

    test('rejects an unsafe/custom scheme', () {
      expect(
        CampaignUrlPolicy.isApproved('intent://jyotishasha.com/#Intent;end'),
        isFalse,
      );
      expect(
        CampaignUrlPolicy.isApproved('myapp://jyotishasha.com/deeplink'),
        isFalse,
      );
    });

    test('rejects a URL with embedded credentials', () {
      expect(
        CampaignUrlPolicy.isApproved(
          'https://user:pass@jyotishasha.com/article',
        ),
        isFalse,
      );
    });

    test('rejects a non-standard port', () {
      expect(
        CampaignUrlPolicy.isApproved('https://jyotishasha.com:8443/article'),
        isFalse,
      );
    });

    test('accepts an explicit default HTTPS port (443)', () {
      expect(
        CampaignUrlPolicy.isApproved('https://jyotishasha.com:443/article'),
        isTrue,
      );
    });

    test('rejects malformed URL syntax without throwing', () {
      const malformedUrl = 'not a valid url';
      expect(
        () => CampaignUrlPolicy.isApproved(malformedUrl),
        returnsNormally,
      );
      expect(CampaignUrlPolicy.isApproved(malformedUrl), isFalse);
      expect(CampaignUrlPolicy.isApproved('https://'), isFalse);
      expect(CampaignUrlPolicy.isApproved('   '), isFalse);
    });

    test('rejects null and empty input, never throws', () {
      expect(CampaignUrlPolicy.isApproved(null), isFalse);
      expect(CampaignUrlPolicy.isApproved(''), isFalse);
    });

    test('never throws across every case above -- parity check', () {
      for (final input in [
        null,
        '',
        '   ',
        'not-a-url',
        'https://',
        'https://jyotishasha.com.evil.example',
        'https://eviljyotishasha.com',
        'javascript:alert(1)',
        'data:text/html,x',
        'file:///etc/passwd',
        'intent://x',
        'https://user:pass@jyotishasha.com',
        'https://jyotishasha.com:8443',
        'https://www.youtube.com/@jyotishasha',
        'https://jyotishasha.com/ok',
      ]) {
        expect(() => CampaignUrlPolicy.isApproved(input), returnsNormally);
      }
    });
  });
}
