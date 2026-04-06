import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class DosenSidebar extends StatelessWidget {
  final int selectedIndex;
  final String nama;
  final ValueChanged<int> onSelect;

  const DosenSidebar({
    super.key,
    required this.selectedIndex,
    required this.nama,
    required this.onSelect,
  });

  static const _color = Color(0xFF2E6B8A);

  static const _items = [
    (icon: Icons.dashboard_rounded,    label: 'Dashboard'),
    (icon: Icons.class_rounded,        label: 'Kelas Saya'),
    (icon: Icons.fact_check_rounded,   label: 'Absensi'),
    (icon: Icons.upload_file_rounded,  label: 'Materi'),
    (icon: Icons.assignment_rounded,   label: 'Tugas'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      width: isMobile ? double.infinity : 220, // RESPONSIVE WIDTH
      color: _color,
      child: SafeArea(child: Column(children: [
        _buildHeader(),
        const Divider(color: Colors.white24, height: 1),
        Expanded(child: _buildNav()),
        const Divider(color: Colors.white24, height: 1),
        _buildFooter(context),
      ])),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 40),
      ),
      const SizedBox(height: 8),
      Text('SIMAMAH', style: TextStyle(
        fontFamily: 'Playfair Display',
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      Text('Panel Dosen', style: TextStyle(
        color: Colors.white.withOpacity(0.65), fontSize: 11)),
    ]),
  );

  Widget _buildNav() => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    itemCount: _items.length,
    itemBuilder: (_, i) {
      final item = _items[i];
      final sel  = selectedIndex == i;
      return GestureDetector(
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: sel ? Colors.white.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? Colors.white30 : Colors.transparent)),
          child: Row(children: [
            Icon(item.icon,
              color: sel ? Colors.white : Colors.white60, size: 19),
            const SizedBox(width: 11),
            Text(item.label, style: TextStyle(
              color: sel ? Colors.white : Colors.white70,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13)),
          ]),
        ),
      );
    },
  );

  Widget _buildFooter(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Text(
          nama.isNotEmpty ? nama[0].toUpperCase() : 'D',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(nama,
        style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.w600, fontSize: 12),
        overflow: TextOverflow.ellipsis)),
      IconButton(
        onPressed: () async {
          await SupabaseService.signOut();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 17)),
    ]),
  );
}
