import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/profile_api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hideCurrentPassword = true;
  bool _hidePassword = true;
  bool _hidePasswordConfirmation = true;

  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await ProfileApi.getProfile();
      final data = Map<String, dynamic>.from(response['data'] as Map);
      final user = Map<String, dynamic>.from(data['user'] as Map);

      if (!mounted) return;

      setState(() {
        _user = user;
        _nameController.text = (user['name'] ?? '').toString();
        _emailController.text = (user['email'] ?? '').toString();
      });
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');

      if (!mounted) return;

      _showSnack(message);

      if (message.toLowerCase().contains('sesi') ||
          message.toLowerCase().contains('login') ||
          message.toLowerCase().contains('token')) {
        await TokenStorage.clearToken();

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    try {
      final response = await ProfileApi.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        currentPassword: _currentPasswordController.text,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      );

      final data = Map<String, dynamic>.from(response['data'] as Map);
      final user = Map<String, dynamic>.from(data['user'] as Map);

      if (!mounted) return;

      setState(() {
        _user = user;
        _nameController.text = (user['name'] ?? '').toString();
        _emailController.text = (user['email'] ?? '').toString();
        _currentPasswordController.clear();
        _passwordController.clear();
        _passwordConfirmationController.clear();
      });

      _showSnack(
        response['message']?.toString() ?? 'Profile berhasil diperbarui.',
      );
    } catch (error) {
      if (!mounted) return;

      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String get _initial {
    final name = (_user?['name'] ?? _nameController.text).toString().trim();

    if (name.isEmpty) return 'T';

    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.dashboard,
                (_) => false,
              );
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: InkWell(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.landing,
            (_) => false,
          ),
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TourHub Bali',
                  style: TextStyle(
                    color: Color(0xFF020617),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Edit Profile User',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (_) => false,
            ),
            icon: const Icon(Icons.dashboard_rounded),
          ),
          IconButton(
            tooltip: 'Rekomendasi',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.recommendation),
            icon: const Icon(Icons.travel_explore_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _isLoading
            ? const _LoadingProfile()
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _ProfileHero(
                    initial: _initial,
                    name: _nameController.text,
                    email: _emailController.text,
                  ),
                  const SizedBox(height: 16),
                  _ProfileForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    currentPasswordController: _currentPasswordController,
                    passwordController: _passwordController,
                    passwordConfirmationController:
                        _passwordConfirmationController,
                    hideCurrentPassword: _hideCurrentPassword,
                    hidePassword: _hidePassword,
                    hidePasswordConfirmation: _hidePasswordConfirmation,
                    onToggleCurrentPassword: () => setState(
                      () => _hideCurrentPassword = !_hideCurrentPassword,
                    ),
                    onTogglePassword: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    onTogglePasswordConfirmation: () => setState(
                      () => _hidePasswordConfirmation =
                          !_hidePasswordConfirmation,
                    ),
                    isSaving: _isSaving,
                    onSubmit: _saveProfile,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initial,
    required this.name,
    required this.email,
  });

  final String initial;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF172554), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GlassBadge(text: 'Profile User'),
                const SizedBox(height: 10),
                Text(
                  name.isEmpty ? 'TourHub User' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email.isEmpty ? '-' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.currentPasswordController,
    required this.passwordController,
    required this.passwordConfirmationController,
    required this.hideCurrentPassword,
    required this.hidePassword,
    required this.hidePasswordConfirmation,
    required this.onToggleCurrentPassword,
    required this.onTogglePassword,
    required this.onTogglePasswordConfirmation,
    required this.isSaving,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController currentPasswordController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmationController;
  final bool hideCurrentPassword;
  final bool hidePassword;
  final bool hidePasswordConfirmation;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onTogglePasswordConfirmation;
  final bool isSaving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FORM PROFILE',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Perbarui Data Akun',
              style: TextStyle(
                color: Color(0xFF020617),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kosongkan password baru jika tidak ingin mengganti password.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Nama Lengkap',
                icon: Icons.person_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama lengkap wajib diisi.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Email',
                icon: Icons.email_rounded,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) return 'Email wajib diisi.';

                if (!email.contains('@') || !email.contains('.')) {
                  return 'Format email tidak valid.';
                }

                return null;
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_rounded, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ganti password bersifat opsional. Jika password baru diisi, password lama wajib benar.',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: currentPasswordController,
              obscureText: hideCurrentPassword,
              textInputAction: TextInputAction.next,
              decoration: _passwordDecoration(
                label: 'Password Lama',
                hidden: hideCurrentPassword,
                onToggle: onToggleCurrentPassword,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordController,
              obscureText: hidePassword,
              textInputAction: TextInputAction.next,
              decoration: _passwordDecoration(
                label: 'Password Baru',
                hidden: hidePassword,
                onToggle: onTogglePassword,
              ),
              validator: (value) {
                final password = value ?? '';

                if (password.isNotEmpty && password.length < 8) {
                  return 'Password baru minimal 8 karakter.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: passwordConfirmationController,
              obscureText: hidePasswordConfirmation,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => isSaving ? null : onSubmit(),
              decoration: _passwordDecoration(
                label: 'Konfirmasi Password Baru',
                hidden: hidePasswordConfirmation,
                onToggle: onTogglePasswordConfirmation,
              ),
              validator: (value) {
                final password = passwordController.text;

                if (password.isNotEmpty && value != password) {
                  return 'Konfirmasi password baru tidak sesuai.';
                }

                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF020617),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
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

  InputDecoration _passwordDecoration({
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return _inputDecoration(label: label, icon: Icons.lock_rounded).copyWith(
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFBFDBFE),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingProfile extends StatelessWidget {
  const _LoadingProfile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Memuat profile user...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
