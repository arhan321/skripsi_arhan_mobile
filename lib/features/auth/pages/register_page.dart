import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final result = await AuthApi.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final token = result.token.trim();
      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan dari response register Laravel.');
      }

      await TokenStorage.saveToken(token);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.recommendation,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Daftar Akun TourHub',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF020617)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF020617), Color(0xFF0F766E), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TinyBadge(text: 'Only User Mobile App'),
                  SizedBox(height: 16),
                  Text(
                    'Buat akun untuk menyimpan riwayat rekomendasi.',
                    style: TextStyle(color: Colors.white, fontSize: 27, height: 1.15, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Setelah registrasi berhasil, kamu langsung masuk ke halaman rekomendasi.',
                    style: TextStyle(color: Color(0xFFE2E8F0), height: 1.5, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
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
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF020617))),
                    const SizedBox(height: 6),
                    const Text('Akun ini dipakai untuk login dan melihat riwayat rekomendasi.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(label: 'Nama Lengkap', icon: Icons.person_outline_rounded),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi.' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(label: 'Email', icon: Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Email wajib diisi.';
                        if (!value.contains('@')) return 'Format email tidak valid.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(label: 'Password', icon: Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password wajib diisi.';
                        if (value.length < 8) return 'Password minimal 8 karakter.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _register,
                        icon: _isLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(_isLoading ? 'Mendaftarkan...' : 'Daftar & Masuk'),
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
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('Sudah punya akun? Masuk', style: TextStyle(fontWeight: FontWeight.w900)),
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

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.text});

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
      child: Text(text, style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}
