import 'package:flutter/foundation.dart';

import 'package:jyotishasha_app/core/utils/share_utils.dart';

/// A generic, reusable piece of shareable content. Any future module
/// (Reports, Kundali, Panchang, etc.) constructs one of these — nothing
/// about this class is specific to events or any other single feature.
///
/// All text fields are plain strings supplied by the caller. This class
/// never contains a language-specific literal itself: dynamic content
/// (e.g. an event's title/body) already arrives in the correct language
/// from wherever it was fetched, and the caller resolves [brandingTagline],
/// [downloadAppLabel], and [visitWebsiteLabel] via the app's existing
/// `AppLocalizations` before constructing this object — so the language
/// shown always matches the app's current locale automatically.
@immutable
class ShareableContent {
  const ShareableContent({
    required this.title,
    required this.brandingTagline,
    required this.downloadAppLabel,
    required this.visitWebsiteLabel,
    this.description,
    this.canonicalUrl,
  });

  /// The thing being shared (e.g. an event title). Required.
  final String title;

  /// Optional supporting copy (e.g. an event description/body).
  final String? description;

  /// Optional deep link to the specific content being shared (e.g. an
  /// event's `resource.url`). Distinct from [ShareService]'s own constant,
  /// app-wide website URL, which is always included separately.
  final String? canonicalUrl;

  /// Localized branding line (e.g. "Shared via Jyotishasha ✨").
  final String brandingTagline;

  /// Localized label preceding the Play Store link.
  final String downloadAppLabel;

  /// Localized label preceding the website link.
  final String visitWebsiteLabel;
}

/// The single, centralized entry point every feature routes through to
/// share content from this app.
///
/// Do not call `share_plus`/[ShareUtils] directly from a feature page, and
/// do not build a page-specific share formatter — construct a
/// [ShareableContent] and call [ShareService.share] so formatting, the
/// Jyotishasha branding line, and the Play Store/website links stay
/// identical everywhere sharing is added.
final class ShareService {
  const ShareService._();

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.jyotishasha.app';
  static const String websiteUrl = 'https://jyotishasha.com';

  static Future<void> share(ShareableContent content) {
    return ShareUtils.shareText(composeMessage(content));
  }

  /// Builds the plain-text share message for [content]. Exposed
  /// separately from [share] so the exact composed text can be asserted in
  /// tests without invoking the OS share sheet.
  static String composeMessage(ShareableContent content) {
    final lines = <String>[content.title];

    final description = content.description?.trim();
    if (description != null && description.isNotEmpty) {
      lines
        ..add('')
        ..add(description);
    }

    final canonicalUrl = content.canonicalUrl?.trim();
    if (canonicalUrl != null && canonicalUrl.isNotEmpty) {
      lines
        ..add('')
        ..add(canonicalUrl);
    }

    lines
      ..add('')
      ..add(content.brandingTagline)
      ..add('${content.downloadAppLabel} $playStoreUrl')
      ..add('${content.visitWebsiteLabel} $websiteUrl');

    return lines.join('\n');
  }
}
