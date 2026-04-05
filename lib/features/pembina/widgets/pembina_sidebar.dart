import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class PembinaSidebar extends StatelessWidget {
  final int selectedIndex;
  final String pembinaName;
  final ValueChanged<int> onSelect;

  const PembinaSidebar({
    super.key,
    required this.selectedIndex,
    required this.pembinaName,
    required this.onSelect,
  });

  static const _items = [
    (icon: Icons.dashboard_rounded,          label: 'Dashboard'),
    (icon: Icons.mosque_rounded,             label: 'Absensi Ibadah'),
    (icon: Icons.monitor_heart_rounded,      label: 'Monitoring'),
    (icon: Icons.warning_amber_rounded,      label: 'Surat Peringatan'),
    (icon: Icons.picture_as_pdf_rounded,     label: 'Laporan PDF'),
  ];

  static const _color = Color(0xFF8A5E2E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      color: _color,
      child: SafeArea(child: Column(children: [
        _buildHeader(),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),
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
        child: const Icon(Icons.supervisor_account_rounded,
            color: Colors.white, size: 40),
      ),
      const SizedBox(height: 10),
      Text('SIMAMAH', style: TextStyle(
          fontFamily: 'Playfair Display',
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      const Text('Portal Pembina',
          style: TextStyle(color: Colors.white60, fontSize: 11)),
    ]),
  );

  Widget _buildNav() => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    itemCount: _items.length,
    itemBuilder: (_, i) {
      final item = _items[i];
      final sel  = selectedIndex == i;
      return GestureDetector(
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? Colors.white.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: sel ? Colors.white.withOpacity(0.3) : Colors.transparent)),
          child: Row(children: [
            Icon(item.icon,
                color: sel ? Colors.white : Colors.white60, size: 18),
            const SizedBox(width: 10),
            Text(item.label, style: TextStyle(
              color: sel ? Colors.white : Colors.white70,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            )),
          ]),
        ),
      );
    },
  );

  Widget _buildFooter(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Text(
          pembinaName.isNotEmpty ? pembinaName[0].toUpperCase() : 'P',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(pembinaName,
        style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w600, fontSize: 11),
        overflow: TextOverflow.ellipsis)),
      IconButton(
        onPressed: () async {
          await SupabaseService.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          }
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 16)),
    ]),
  );
}
