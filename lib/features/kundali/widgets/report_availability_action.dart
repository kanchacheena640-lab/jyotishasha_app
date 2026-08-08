// lib/features/kundali/widgets/report_availability_action.dart

import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/constants/app_colors.dart';
import 'package:jyotishasha_app/features/kundali/data/identity_report_availability.dart';

/// The single Bottom Action every Kundali overview card ends with
/// (Identity, Planets, ...): a tappable "View Full Free Report →" when
/// [status] is available, or plain, non-interactive grey "Coming Soon"
/// text otherwise. Centralized so report-status branching exists in only
/// one place in the UI, regardless of which card renders it.
class ReportAvailabilityAction extends StatelessWidget {
  const ReportAvailabilityAction({
    super.key,
    required this.status,
    required this.isHindi,
    this.onTap,
  });

  final ReportAvailabilityStatus status;
  final bool isHindi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (status == ReportAvailabilityStatus.available) {
      return InkWell(
        onTap: onTap ?? () {},
        child: Text(
          isHindi ? 'पूरी मुफ़्त रिपोर्ट देखें →' : 'View Full Free Report →',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );
    }
    // Coming soon — grey and genuinely non-interactive, not just visually disabled.
    return Text(
      isHindi ? 'जल्द आ रहा है' : 'Coming Soon',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9CA3AF),
      ),
    );
  }
}
