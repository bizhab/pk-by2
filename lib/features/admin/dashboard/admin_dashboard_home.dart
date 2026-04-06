import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/widgets.dart';
import 'admin_dashboard_widgets.dart';

class AdminDashboardHome extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> recentSP;
  final List<Map<String, dynamic>> recentSesi;
  final Map<String, dynamic>? activeSemester;
  final VoidCallback onRefresh;
  final List<VoidCallback?> quickActions;

  const AdminDashboardHome({
    super.key,
    required this.stats,
    required this.recentSP,
    required this.recentSesi,
    required this.activeSemester,
    required this.onRefresh,
    required this.quickActions,
  });

  @override
  Widget build(BuildContext context) {
    final semLabel = activeSemester != null
        ? '${activeSemester!['nama']} — ${activeSemester!['tahun_akademik']?['nama'] ?? ''}'
        : 'Belum ada semester aktif';
        
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Widget untuk bagian SP
    final widgetSP = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'SP Terbaru', actionLabel: 'Lihat Semua'),
      const SizedBox(height: 12),
      recentSP.isEmpty
        ? const EmptyState(icon: Icons.check_circle_outline, message: 'Tidak ada SP aktif')
        : Column(children: recentSP.map((sp) => SPCard(sp: sp)).toList()),
    ]);

    // Widget untuk bagian Sesi
    final widgetSesi = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: 'Sesi Absensi Terbaru'),
      const SizedBox(height: 12),
      recentSesi.isEmpty
        ? const EmptyState(icon: Icons.event_busy_outlined, message: 'Belum ada sesi')
        : Column(children: recentSesi.map((s) => SesiAkademikCard(sesi: s)).toList()),
    ]);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 28 : 16), // Padding menyesuaikan layar
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header (Gunakan Wrap agar responsif di layar kecil)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Selamat Datang 👋',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: isDesktop ? 28 : 22,
                  )),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.circle, color: AppColors.secondary, size: 8),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Semester aktif: $semLabel',
                      style: const TextStyle(color: AppColors.textMid, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ]),
              const DateBadge(),
            ],
          ),
          SizedBox(height: isDesktop ? 28 : 20),

          // Stat Cards (Pastikan layout di dalam AdminStatCards juga dibungkus Wrap/GridView di file widgetnya)
          AdminStatCards(stats: stats),
          SizedBox(height: isDesktop ? 28 : 20),

          // Bottom Row (Side-by-side di Desktop, Stack vertikal di Mobile)
          if (isDesktop)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: widgetSP),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: widgetSesi),
            ])
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              widgetSP,
              const SizedBox(height: 24),
              widgetSesi,
            ]),
            
          SizedBox(height: isDesktop ? 28 : 20),

          // Quick Actions
          SectionHeader(title: 'Aksi Cepat'),
          const SizedBox(height: 12),
          AdminQuickActions(onActions: quickActions),
        ]),
      ),
    );
  }
}