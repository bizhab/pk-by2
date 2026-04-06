import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final String adminName;
  final ValueChanged<int> onSelect;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.adminName,
    required this.onSelect,
  });

  static const _items = [
    (icon: Icons.dashboard_rounded,           label: 'Dashboard'),
    (icon: Icons.school_rounded,              label: 'Santri'),
    (icon: Icons.person_pin_rounded,          label: 'Dosen'),
    (icon: Icons.supervisor_account_rounded,  label: 'Pembina'),
    (icon: Icons.group_work_rounded,          label: 'Kelompok'),
    (icon: Icons.class_rounded,              label: 'Kelas'),
    (icon: Icons.calendar_today_rounded,      label: 'Semester'),
    (icon: Icons.location_on_rounded,         label: 'Geofence'),
    (icon: Icons.campaign_rounded,            label: 'Pengumuman'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Container(
      // Lebar diatur fleksibel jika dipanggil di dalam Drawer (Mobile), 
      // Tetap 220-250 jika di layout Row Desktop
      width: isDesktop ? 250 : double.infinity,
      color: AppColors.primary,
      child: SafeArea(child: Column(children: [
        _buildHeader(),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),
        Expanded(child: _buildNavItems()),
        const Divider(color: Colors.white24, height: 1),
        _buildFooter(context),
      ])),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 10),
        const Text('SIMAMAH', style: TextStyle(
          fontFamily: 'Playfair Display',
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        Text('Panel Admin', style: TextStyle(
          color: Colors.white.withOpacity(0.65), fontSize: 11)),
      ]),
    );
  }

  Widget _buildNavItems() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final item = _items[i];
        final isSelected = selectedIndex == i;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent),
            ),
            child: Row(children: [
              Icon(item.icon,
                color: isSelected ? Colors.white : Colors.white60, size: 20),
              const SizedBox(width: 12),
              Text(item.label, style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              )),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(adminName, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            overflow: TextOverflow.ellipsis),
          const Text('Administrator',
            style: TextStyle(color: Colors.white54, fontSize: 10)),
        ])),
        IconButton(
          onPressed: () => _signOut(context),
          icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
          tooltip: 'Keluar',
        ),
      ]),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await showConfirmDialog(context,
      title: 'Keluar?', message: 'Apakah Anda yakin ingin keluar?',
      confirmLabel: 'Keluar', confirmColor: AppColors.error);
    if (ok) {
      await SupabaseService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}