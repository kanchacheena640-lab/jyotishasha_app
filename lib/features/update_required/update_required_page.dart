import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';

/// Ask Now Security + Force Update task, Part D -- the blocking "Update
/// Required" experience.
///
/// - No route/back-gesture can bypass it: [PopScope.canPop] is `false`
///   and the Android back button is a no-op, same mechanism
///   [SplashPage] itself already establishes for its own loading state.
/// - No account/session action of any kind lives here -- no logout, no
///   data mutation, nothing but "open Play Store" and (if the caller
///   passes one) a retry.
/// - Branded, bilingual (EN/HI) static copy owned by the client itself
///   -- the backend's own optional `message` (Part C's response
///   contract) is shown as an ADDITIONAL line under this, never as a
///   replacement for it, so a missing/null backend message never
///   leaves the screen blank or unbranded.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({
    super.key,
    required this.storeUrl,
    this.operatorMessage,
  });

  /// Where "Update Now" opens. Falls back to the app's own Play Store
  /// listing if the backend didn't supply one (defensive only -- the
  /// seeded/admin-configured policy always sets this).
  final String? storeUrl;

  /// Optional operator-supplied context from the backend
  /// (`AppVersionPolicy.message`).
  final String? operatorMessage;

  static const String _fallbackStoreUrl =
      'https://play.google.com/store/apps/details?id=com.jyotishasha.app';

  Future<void> _openStore() async {
    final url = Uri.parse(
      (storeUrl != null && storeUrl!.trim().isNotEmpty)
          ? storeUrl!
          : _fallbackStoreUrl,
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.watch<LanguageProvider>().isHindi;
    final theme = Theme.of(context);

    return PopScope(
      // Android back button (and any other pop gesture) is fully
      // disabled -- there is no "continue anyway" out of this screen.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.7),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Jyotishasha',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isHindi
                      ? 'STAARAE द्वारा संचालित'
                      : 'Powered by STAARAE',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  isHindi ? 'अपडेट आवश्यक है' : 'Update Required',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isHindi
                      ? 'Jyotishasha के इस वर्शन में अब सुरक्षा और सुविधा सुधार शामिल नहीं हैं। कृपया जारी रखने के लिए ऐप को अपडेट करें।'
                      : 'This version of Jyotishasha no longer includes the latest security and feature updates. Please update to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
                if (operatorMessage != null &&
                    operatorMessage!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    operatorMessage!.trim(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.75),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isHindi ? 'अभी अपडेट करें' : 'Update Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
