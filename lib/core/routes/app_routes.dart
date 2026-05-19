import 'package:flutter/material.dart';

import '../../features/auth/pages/auth_gate_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/recommendation/pages/recommendation_page.dart';

final class AppRoutes {
  const AppRoutes._();

  static const String authGate = '/';
  static const String login = '/login';
  static const String recommendation = '/recommendation';

  static Map<String, WidgetBuilder> get routes => {
        authGate: (_) => const AuthGatePage(),
        login: (_) => const LoginPage(),
        recommendation: (_) => const RecommendationPage(),
      };
}
