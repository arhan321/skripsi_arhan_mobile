import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../features/auth/data/auth_api.dart';

enum TourHubSidebarMenu {
  dashboard,
  recommendation,
  history,
  wishlist,
  profile,
}

class TourHubSidebar extends StatelessWidget {
  const TourHubSidebar({super.key, required this.activeMenu});

  final TourHubSidebarMenu activeMenu;

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);

    await AuthApi.logout();

    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _goTo(BuildContext context, String routeName) {
    Navigator.of(context).pop();

    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == routeName) return;

    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 304,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _SidebarHeader(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                children: [
                  _SidebarItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Beranda',
                    subtitle: 'Ringkasan akun dan rekomendasi terakhir',
                    isActive: activeMenu == TourHubSidebarMenu.dashboard,
                    onTap: () => _goTo(context, AppRoutes.dashboard),
                  ),
                  _SidebarItem(
                    icon: Icons.travel_explore_rounded,
                    title: 'Cari Wisata',
                    subtitle: 'Temukan rekomendasi wisata Bali',
                    isActive: activeMenu == TourHubSidebarMenu.recommendation,
                    onTap: () => _goTo(context, AppRoutes.recommendation),
                  ),
                  _SidebarItem(
                    icon: Icons.history_rounded,
                    title: 'Riwayat',
                    subtitle: 'Lihat pencarian wisata sebelumnya',
                    isActive: activeMenu == TourHubSidebarMenu.history,
                    onTap: () => _goTo(context, AppRoutes.history),
                  ),
                  _SidebarItem(
                    icon: Icons.star_rounded,
                    title: 'Wishlist',
                    subtitle: 'Destinasi wisata yang kamu simpan',
                    isActive: activeMenu == TourHubSidebarMenu.wishlist,
                    onTap: () => _goTo(context, AppRoutes.wishlist),
                  ),
                  _SidebarItem(
                    icon: Icons.person_rounded,
                    title: 'Profil',
                    subtitle: 'Kelola informasi akun kamu',
                    isActive: activeMenu == TourHubSidebarMenu.profile,
                    onTap: () => _goTo(context, AppRoutes.profile),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'TourHub membantu kamu mencari dan menyimpan destinasi wisata Bali yang sesuai preferensi.',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              height: 1.35,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF172554), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -26,
            child: Container(
              height: 92,
              width: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TourHub Bali',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Menu navigasi wisata',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF334155);
    final subtitleColor = isActive
        ? const Color(0xFF2563EB)
        : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isActive ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          height: 1.25,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
