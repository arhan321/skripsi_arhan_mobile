import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TourHubApp());
}

class TourHubApp extends StatelessWidget {
  const TourHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TourHub Bali',
      theme: AppTheme.light(),
      initialRoute: AppRoutes.authGate,
      routes: AppRoutes.routes,
    );
  }
}
