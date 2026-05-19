import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final hasToken = await TokenStorage.hasToken();

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      hasToken ? AppRoutes.recommendation : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
