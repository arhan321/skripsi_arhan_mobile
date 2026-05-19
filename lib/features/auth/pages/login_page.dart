import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final result = await AuthApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final token = result.token.trim();
      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan dari response login Laravel.');
      }

      await TokenStorage.saveToken(token);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.recommendation,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            const _BrandHeader(),
            const SizedBox(height: 24),
            const _HeroLoginCard(),
            const SizedBox(height: 18),
            _LoginFormCard(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              isLoading: _isLoading,
              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: _login,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun?',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text(
                    'Daftar sekarang',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: const LinearGradient(
              colors: [Color(0xFF020617), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text('T', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TourHub Bali', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Color(0xFF020617))),
              Text('Rekomendasi Wisata CBF + CARS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroLoginCard extends StatelessWidget {
  const _HeroLoginCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020617), Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassBadge(text: 'Machine Learning Recommendation System'),
          SizedBox(height: 16),
          Text(
            'Masuk dulu untuk mulai rekomendasi wisata.',
            style: TextStyle(color: Colors.white, fontSize: 28, height: 1.15, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 12),
          Text(
            'Setiap hasil rekomendasi akan disimpan sebagai riwayat user di Laravel.',
            style: TextStyle(color: Color(0xFFE2E8F0), height: 1.5, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Login User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF020617))),
            const SizedBox(height: 6),
            const Text('Gunakan akun yang sama dengan web TourHub.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 18),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Email wajib diisi.';
                if (!value.contains('@')) return 'Format email tidak valid.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: _inputDecoration(label: 'Password', icon: Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Password wajib diisi.' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onSubmit,
                icon: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.login_rounded),
                label: Text(isLoading ? 'Memproses...' : 'Masuk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF020617),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}
