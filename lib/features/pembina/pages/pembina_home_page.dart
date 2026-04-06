import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class PembinaHomePage extends StatelessWidget {
  final Map<String, dynamic>? kelompok;
  final VoidCallback onRefresh;

  const PembinaHomePage({
    super.key,
    required this.kelompok,
    required this.onRefresh,
  });

  List<Map<String, dynamic>> get _santriList =>
      (kelompok?['kelompok_santri'] as List?)
          ?.cast<Map<String, dynamic>>() ?? [];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF8A5E2E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(context, isMobile),
          const SizedBox(height: 24),
          _buildStatCards(context, isMobile),
          const SizedBox(height: 28),
          _buildSantriSection(context, isMobile),
          const SizedBox(height: 28),
          SectionHeader(title: 'Jadwal Sholat Hari Ini'),
          const SizedBox(height: 12),
          _JadwalWidget(),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final now    = DateTime.now();
    final days   = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    
    // RESPONSIVE HEADER: Gunakan Wrap agar tidak bertabrakan
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16, runSpacing: 16,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Assalamu'alaikum 🌙",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: isMobile ? 22 : 28
              )),
          const SizedBox(height: 4),
          Text(kelompok != null
            ? 'Kelompok: ${kelompok!['nama_kelompok'] ?? '-'}'
            : 'Belum ada kelompok aktif',
            style: const TextStyle(color: AppColors.textMid, fontSize: 13)),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_rounded,
                color: Color(0xFF8A5E2E), size: 15),
            const SizedBox(width: 8),
            Text(
              '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}',
              style: const TextStyle(color: AppColors.textDark,
                  fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ),
      ]
    );
  }

  Widget _buildStatCards(BuildContext context, bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 1 : 3, // RESPONSIVE GRID COLUMNS
      crossAxisSpacing: 16, mainAxisSpacing: 16,
      childAspectRatio: isMobile ? 2.8 : 1.6, // RESPONSIVE ASPECT RATIO
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Santri Binaan', value: '${_santriList.length}/10',
          icon: Icons.group_rounded,
          gradient: const [Color(0xFF8A5E2E), Color(0xFFBF924A)]),
        StatCard(label: 'Sholat Wajib', value: '5',
          icon: Icons.mosque_rounded,
          gradient: const [AppColors.primary, AppColors.secondary],
          subtitle: 'Per hari'),
        StatCard(label: 'Sholat Sunnah', value: '3',
          icon: Icons.stars_rounded,
          gradient: const [Color(0xFF2E6B8A), Color(0xFF4A9BBF)]),
      ],
    );
  }

  Widget _buildSantriSection(BuildContext context, bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Tentukan jumlah kolom foto profil santri
    final int crossAxisCount = isMobile ? 3 : (screenWidth < 900 ? 4 : 6);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Santri Binaan Saya'),
      const SizedBox(height: 12),
      if (kelompok == null)
        const EmptyState(icon: Icons.group_outlined,
          message: 'Belum ada kelompok. Hubungi Admin.')
      else
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount, // RESPONSIVE SANTRI GRID
            crossAxisSpacing: 12,
            mainAxisSpacing: 12, 
            childAspectRatio: isMobile ? 0.75 : 0.85
          ),
          itemCount: _santriList.length,
          itemBuilder: (_, i) {
            final s   = _santriList[i]['santri'] as Map? ?? {};
            final p   = s['profile'] as Map? ?? {};
            final nama= p['nama_lengkap'] ?? '-';
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircleAvatar(
                  radius: isMobile ? 20 : 24,
                  backgroundColor: const Color(0xFF8A5E2E).withOpacity(0.12),
                  child: Text(
                    nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                    style: TextStyle(color: const Color(0xFF8A5E2E),
                        fontWeight: FontWeight.w800, fontSize: isMobile ? 16 : 18)),
                ),
                const SizedBox(height: 8),
                Text(nama.split(' ').first,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 12, color: AppColors.textDark),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(s['nim'] ?? '-',
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
              ]),
            );
          },
        ),
    ]);
  }
}

// ── Jadwal widget ───────────────────────────────────
class _JadwalWidget extends StatefulWidget {
  @override
  State<_JadwalWidget> createState() => _JadwalWidgetState();
}

class _JadwalWidgetState extends State<_JadwalWidget> {
  List<Map<String, dynamic>> _jadwal = [];

  @override
  void initState() {
    super.initState();
    SupabaseService.getJadwalSholat()
        .then((d) => mounted ? setState(() => _jadwal = d) : null);
  }

  @override
  Widget build(BuildContext context) {
    if (_jadwal.isEmpty) {
      return const SizedBox(height: 60,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    final wajib  = _jadwal.where((j) => j['kategori'] == 'wajib').toList();
    final sunnah = _jadwal.where((j) => j['kategori'] == 'sunnah').toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    // RESPONSIVE JADWAL LAYOUT: Susun bawah di HP, Samping di Desktop
    if (isMobile) {
      return Column(children: [
        _JadwalKolom(list: wajib, color: AppColors.primary, label: 'WAJIB'),
        const SizedBox(height: 16),
        _JadwalKolom(list: sunnah, color: const Color(0xFF2E6B8A), label: 'SUNNAH'),
      ]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _JadwalKolom(list: wajib, color: AppColors.primary, label: 'WAJIB')),
      const SizedBox(width: 16),
      Expanded(child: _JadwalKolom(list: sunnah, color: const Color(0xFF2E6B8A), label: 'SUNNAH')),
    ]);
  }
}

class _JadwalKolom extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final Color color;
  final String label;
  const _JadwalKolom({required this.list, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StatusBadge(label: label, color: color),
      const SizedBox(height: 8),
      ...list.map((j) {
        final mulai  = j['jam_mulai']?.toString().substring(0, 5) ?? '-';
        final selesai= j['jam_selesai']?.toString().substring(0, 5) ?? '-';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.15))),
          child: Row(children: [
            Icon(Icons.mosque_rounded, color: color, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text(j['nama_sholat'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 12, color: AppColors.textDark))),
            Text('$mulai—$selesai',
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ]),
        );
      }),
    ]);
  }
}