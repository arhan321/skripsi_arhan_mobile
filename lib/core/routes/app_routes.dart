import 'package:flutter/material.dart';

import '../../features/auth/pages/auth_gate_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/recommendation/pages/history_detail_page.dart';
import '../../features/recommendation/pages/history_page.dart';
import '../../features/recommendation/pages/recommendation_page.dart';

final class AppRoutes {
  const AppRoutes._();

  static const String authGate = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String recommendation = '/recommendation';
  static const String history = '/history';
  static const String historyDetail = '/history/detail';

  static Map<String, WidgetBuilder> get routes => {
    authGate: (_) => const AuthGatePage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    recommendation: (_) => const RecommendationPage(),
    history: (_) => const HistoryPage(),
    historyDetail: (_) => const HistoryDetailPage(),
  };
}
