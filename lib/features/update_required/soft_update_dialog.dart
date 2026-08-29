import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/services/app_version_gate_service.dart';

/// Reusable App Update System -- the non-blocking "Update Available"
/// prompt for [AppUpdateStatus.soft]. Deliberately a plain [AlertDialog]
/// (this app's own existing two-button confirm/cancel convention --
/// same shape as e.g. the language-picker/logout dialogs in
/// account_page.dart), not a new full-screen page: unlike
/// [UpdateRequiredPage], this must never block the user from reaching
/// the app underneath it.
///
/// "Later" (or dismissing the dialog any other way -- tapping outside,
/// system back) marks the prompt dismissed for the rest of this app
/// process via [AppVersionGateService.dismissSoftUpdateForSession] and
/// simply lets the caller continue -- there is nothing to "cancel," the
/// app was never blocked in the first place.
Future<void> showSoftUpdatePrompt(
  BuildContext context, {
  required String? storeUrl,
  String? operatorMessage,
}) async {
  final isHindi = context.read<LanguageProvider>().isHindi;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(isHindi ? 'अपडेट उपलब्ध है' : 'Update Available'),
      content: Text(
        isHindi
            ? 'Jyotishasha का एक नया वर्शन नवीनतम सुधारों के साथ उपलब्ध है।'
                  '${operatorMessage != null && operatorMessage.trim().isNotEmpty ? '\n\n${operatorMessage.trim()}' : ''}'
            : 'A new version of Jyotishasha is available with the latest improvements.'
                  '${operatorMessage != null && operatorMessage.trim().isNotEmpty ? '\n\n${operatorMessage.trim()}' : ''}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(isHindi ? 'बाद में' : 'Later'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            await _openStore(storeUrl);
          },
          child: Text(isHindi ? 'अभी अपडेट करें' : 'Update Now'),
        ),
      ],
    ),
  );

  // Reached on every dismissal path (Later, Update Now, tap-outside,
  // system back) -- "Update Now" opens the Play Store but does not
  // itself resolve the update (the Play Store remains responsible for
  // that, per this system's own design), so the prompt is considered
  // "seen" for this session either way.
  AppVersionGateService.dismissSoftUpdateForSession();
}

Future<void> _openStore(String? storeUrl) async {
  const fallback =
      'https://play.google.com/store/apps/details?id=com.jyotishasha.app';
  final url = Uri.parse(
    (storeUrl != null && storeUrl.trim().isNotEmpty) ? storeUrl : fallback,
  );
  await launchUrl(url, mode: LaunchMode.externalApplication);
}
