import 'package:flutter/material.dart';

import '../../features/auth/pages/auth_gate_page.dart';
import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/landing/pages/landing_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/recommendation/pages/history_detail_page.dart';
import '../../features/recommendation/pages/history_page.dart';
import '../../features/recommendation/pages/recommendation_page.dart';
import '../../features/user/pages/user_dashboard_page.dart';

final class AppRoutes {
  const AppRoutes._();

  static const String landing = '/';
  static const String authGate = '/auth-gate';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String recommendation = '/recommendation';
  static const String history = '/history';
  static const String historyDetail = '/history/detail';

  static Map<String, WidgetBuilder> get routes => {
    landing: (_) => const LandingPage(),
    authGate: (_) => const AuthGatePage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    forgotPassword: (_) => const ForgotPasswordPage(),
    dashboard: (_) => const UserDashboardPage(),
    profile: (_) => const ProfilePage(),
    recommendation: (_) => const RecommendationPage(),
    history: (_) => const HistoryPage(),
    historyDetail: (_) => const HistoryDetailPage(),
  };
}
