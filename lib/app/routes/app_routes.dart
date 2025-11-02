import 'package:flutter/material.dart';
import 'package:jyotishasha_app/app/features/splash/splash_page.dart';
import 'package:jyotishasha_app/app/features/auth/login_page.dart';
import 'package:jyotishasha_app/app/features/birth/birth_detail_page.dart';
import 'package:jyotishasha_app/app/features/dashboard/pages/dashboard_page.dart';
import 'package:jyotishasha_app/app/features/tools/pages/tools_page.dart';
import 'package:jyotishasha_app/app/features/reports/pages/reports_page.dart';
import 'package:jyotishasha_app/app/features/reports/pages/my_reports_page.dart';
import 'package:jyotishasha_app/app/features/reports/pages/report_viewer_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const birthDetail = '/birth-detail';
  static const dashboard = '/dashboard';
  static const tools = '/tools';
  static const reports = '/reports';
  static const myReports = '/my-reports';
  static const reportViewer = '/report-viewer';
}

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.splash: (context) => const SplashPage(),
  AppRoutes.login: (context) => const LoginPage(),
  AppRoutes.birthDetail: (context) => const BirthDetailPage(),
  AppRoutes.dashboard: (context) => const DashboardPage(),
  AppRoutes.tools: (context) => const ToolsPage(),
  AppRoutes.reports: (context) => const ReportsPage(),
  AppRoutes.myReports: (context) => const MyReportsPage(),
  AppRoutes.reportViewer: (context) {
    final pdfUrl = ModalRoute.of(context)!.settings.arguments as String;
    return ReportViewerPage(pdfUrl: pdfUrl);
  },
};
