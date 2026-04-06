import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/widgets.dart';

// ── Stat Cards Grid ───────────────────────────────────────
class AdminStatCards extends StatelessWidget {
  final Map<String, dynamic> stats;

  const AdminStatCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Deteksi ukuran layar untuk responsivitas
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Jika di HP (kurang dari 600px), tampilkan 2 kolom. Jika Desktop/Tablet besar, 4 kolom.
    final int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 2 : 4);
    // Sesuaikan rasio kotak agar tidak terlalu gepeng di layar kecil
    final double aspectRatio = screenWidth < 600 ? 1.2 : 1.4;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          label: 'Total Santri',
          icon: Icons.school_rounded,
          value: '${stats['total_santri'] ?? 0}',
          gradient: AppColors.gradSantri,
          subtitle: 'Santri aktif',
        ),
        StatCard(
          label: 'Total Dosen',
          icon: Icons.person_pin_rounded,
          value: '${stats['total_dosen'] ?? 0}',
          gradient: AppColors.gradDosen,
        ),
        StatCard(
          label: 'Total Pembina',
          icon: Icons.supervisor_account_rounded,
          value: '${stats['total_pembina'] ?? 0}',
          gradient: AppColors.gradPembina,
        ),
        StatCard(
          label: 'SP Aktif',
          icon: Icons.warning_amber_rounded,
          value: '${stats['total_sp_aktif'] ?? 0}',
          gradient: AppColors.gradSP,
          subtitle: 'Perlu tindak lanjut',
        ),
      ],
    );
  }
}

// ── Recent SP Card ────────────────────────────────────────
class SPCard extends StatelessWidget {
  final Map<String, dynamic> sp;
  const SPCard({super.key, required this.sp});

  @override
  Widget build(BuildContext context) {
    final level      = sp['level'] ?? 'SP1';
    final santriName = sp['santri']?['profile']?['nama_lengkap'] ?? '-';
    final pembinaName= sp['pembina']?['profile']?['nama_lengkap'] ?? '-';
    final color = level == 'SP3' ? AppColors.error
        : level == 'SP2' ? Colors.orange
        : Colors.amber.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          StatusBadge(label: level, color: color),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(santriName, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
            Text('oleh $pembinaName', style: const TextStyle(
              fontSize: 11, color: AppColors.textLight)),
            if (sp['alasan'] != null)
              Text(sp['alasan'], maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
          ])),
        ]),
      ),
    );
  }
}

// ── Recent Sesi Card ──────────────────────────────────────
class SesiAkademikCard extends StatelessWidget {
  final Map<String, dynamic> sesi;
  const SesiAkademikCard({super.key, required this.sesi});

  @override
  Widget build(BuildContext context) {
    final kelas  = sesi['kelas'];
    final matkul = kelas?['mata_kuliah']?['nama'] ?? '-';
    final namaKelas = kelas?['nama_kelas'] ?? '';
    final isOpen = sesi['jam_tutup'] == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$matkul — Kelas $namaKelas', style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
            Text(sesi['tanggal'] ?? '-',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ])),
          StatusBadge(
            label: isOpen ? 'BUKA' : 'TUTUP',
            color: isOpen ? AppColors.primary : AppColors.textLight),
        ]),
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────
class AdminQuickActions extends StatelessWidget {
  final List<VoidCallback?> onActions;

  const AdminQuickActions({super.key, required this.onActions});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.person_add_rounded, 'Tambah Santri',     AppColors.primary),
      (Icons.campaign_rounded,   'Buat Pengumuman',   const Color(0xFF2E6B8A)),
      (Icons.location_on_rounded,'Atur Geofence',     const Color(0xFF8A5E2E)),
      (Icons.class_rounded,      'Buat Kelas',        const Color(0xFF5E2E8A)),
    ];
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Jika di HP, gunakan GridView 2x2 agar teks tidak bertumpuk
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(actions.length, (i) => _buildActionCard(actions[i], i)),
      );
    }

    // Jika Desktop, gunakan Row menyamping seperti semula
    return Row(
      children: List.generate(actions.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < actions.length - 1 ? 12 : 0),
            child: _buildActionCard(actions[i], i),
          ),
        );
      }),
    );
  }

  Widget _buildActionCard((IconData, String, Color) a, int index) {
    return GestureDetector(
      onTap: onActions.length > index ? onActions[index] : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: a.$3.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: a.$3.withOpacity(0.2)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: a.$3.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(a.$1, color: a.$3, size: 22),
          ),
          const SizedBox(height: 8),
          Text(a.$2, textAlign: TextAlign.center,
            style: TextStyle(color: a.$3,
              fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    );
  }
}

// ── Date Badge ────────────────────────────────────────────
class DateBadge extends StatelessWidget {
  const DateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days   = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}',
          style: const TextStyle(color: AppColors.textDark,
            fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}