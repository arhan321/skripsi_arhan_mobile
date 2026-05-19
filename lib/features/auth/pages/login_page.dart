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

    setState(() => _isLoading = true);

    try {
      final result = await AuthApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      /*
       * AuthApi.login() mengembalikan object AuthLoginResponse,
       * bukan Map<String, dynamic>.
       *
       * Jadi token dibaca dari property result.token,
       * bukan result['token'].
       */
      final token = result.token.trim();

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan dari response login Laravel.');
      }

      await TokenStorage.saveToken(token);

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.recommendation, (route) => false);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF020617), Color(0xFF2563EB)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'T',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TourHub Bali',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF020617),
                        ),
                      ),
                      Text(
                        'Rekomendasi Wisata CBF + CARS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF020617),
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Machine Learning Recommendation System',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Masuk dulu untuk mulai rekomendasi wisata.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Setiap hasil rekomendasi akan disimpan sebagai riwayat user di Laravel.',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        height: 1.5,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login User',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF020617),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Gunakan akun yang sama dengan web TourHub.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          label: 'Email',
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email wajib diisi.';
                          }

                          if (!value.contains('@')) {
                            return 'Format email tidak valid.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration:
                            _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password wajib diisi.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login_rounded),
                          label: Text(_isLoading ? 'Memproses...' : 'Masuk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF020617),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFCBD5E1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
