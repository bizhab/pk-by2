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

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Selamat Datang 👋',
                style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.circle, color: AppColors.secondary, size: 8),
                const SizedBox(width: 6),
                Text('Semester aktif: $semLabel',
                  style: const TextStyle(color: AppColors.textMid, fontSize: 13)),
              ]),
            ]),
            const DateBadge(),
          ]),
          const SizedBox(height: 28),

          // Stat Cards
          AdminStatCards(stats: stats),
          const SizedBox(height: 28),

          // Bottom Row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Recent SP
            Expanded(flex: 5, child: Column(children: [
              SectionHeader(title: 'SP Terbaru', actionLabel: 'Lihat Semua'),
              const SizedBox(height: 12),
              recentSP.isEmpty
                ? const EmptyState(icon: Icons.check_circle_outline,
                    message: 'Tidak ada SP aktif')
                : Column(children: recentSP
                    .map((sp) => SPCard(sp: sp)).toList()),
            ])),
            const SizedBox(width: 20),
            // Recent Sesi
            Expanded(flex: 5, child: Column(children: [
              SectionHeader(title: 'Sesi Absensi Terbaru'),
              const SizedBox(height: 12),
              recentSesi.isEmpty
                ? const EmptyState(icon: Icons.event_busy_outlined,
                    message: 'Belum ada sesi')
                : Column(children: recentSesi
                    .map((s) => SesiAkademikCard(sesi: s)).toList()),
            ])),
          ]),
          const SizedBox(height: 28),

          // Quick Actions
          SectionHeader(title: 'Aksi Cepat'),
          const SizedBox(height: 12),
          AdminQuickActions(onActions: quickActions),
        ]),
      ),
    );
  }
}
