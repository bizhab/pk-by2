import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/adaptive_layouts.dart'; // Tambahkan ini
import '../../../core/utils/responsive.dart'; // Tambahkan ini
import '../widgets/dosen_sidebar.dart';
import 'dosen_kelas_page.dart';
import 'dosen_absensi_page.dart';
import 'dosen_materi_tugas_page.dart';

class DosenDashboardPage extends StatefulWidget {
  const DosenDashboardPage({super.key});
  @override
  State<DosenDashboardPage> createState() => _DosenDashboardPageState();
}

class _DosenDashboardPageState extends State<DosenDashboardPage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _dosenData;
  Map<String, dynamic>? _activeSemester;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    try {
      final profile  = await SupabaseService.getMyProfile();
      final uid      = SupabaseService.currentUser?.id;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final dosenRaw = await SupabaseService.client
          .from('dosen').select('id, nip, bidang_studi')
          .eq('profile_id', uid).single();
      final sem = await SupabaseService.getActiveSemester();
      if (mounted) {
        setState(() {
          _dosenData = {
            ...?profile,
            'dosen_id': dosenRaw['id'],
            'nip'     : dosenRaw['nip'],
          };
          _activeSemester = sem;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[DosenDashboard] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    // Gunakan AdaptiveDashboardLayout bawaan sistem Anda!
    return AdaptiveDashboardLayout(
      title: 'Panel Dosen',
      backgroundColor: AppColors.background,
      sidebarBuilder: (context) => DosenSidebar(
        selectedIndex: _selectedIndex,
        nama: _dosenData?['nama_lengkap'] ?? 'Dosen',
        onSelect: (i) {
          setState(() => _selectedIndex = i);
          // Jika di HP, tutup otomatis drawer setelah menu diklik
          if (context.isMobile) {
            Navigator.pop(context);
          }
        },
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final dosenId = _dosenData?['dosen_id']?.toString() ?? '';
    final semId   = _activeSemester?['id']?.toString() ?? '';
    
    switch (_selectedIndex) {
      case 0: return _DosenHomePage(dosenData: _dosenData, activeSemester: _activeSemester);
      case 1: return DosenKelasPage(dosenId: dosenId, semesterId: semId);
      case 2: return DosenAbsensiPage(dosenId: dosenId);
      case 3: return DosenMateriPage(dosenId: dosenId, semesterId: semId);
      case 4: return DosenTugasPage(dosenId: dosenId, semesterId: semId);
      default: return const SizedBox.shrink();
    }
  }
}

class _DosenHomePage extends StatelessWidget {
  final Map<String, dynamic>? dosenData;
  final Map<String, dynamic>? activeSemester;
  const _DosenHomePage({this.dosenData, this.activeSemester});

  @override
  Widget build(BuildContext context) {
    final semLabel = activeSemester != null
        ? '${activeSemester!['nama']} ${activeSemester!['tahun_akademik']?['nama'] ?? ''}'
        : 'Tidak ada semester aktif';

    return SingleChildScrollView(
      // Gunakan padding dari file responsive Anda
      padding: context.responsive.contentPadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Selamat Datang, ${dosenData?['nama_lengkap'] ?? 'Dosen'} 👋',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: context.responsive.getFont(mobile: 22, tablet: 28)
          )),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.circle, color: AppColors.secondary, size: 8),
          const SizedBox(width: 6),
          Expanded(child: Text('Semester: $semLabel',
            style: const TextStyle(color: AppColors.textMid, fontSize: 13))),
        ]),
        const SizedBox(height: 28),
        
        // RESPONSIVE CARDS MENGGUNAKAN GRID BAWAAN ANDA
        GridView.count(
          crossAxisCount: context.responsive.getGridCount(mobile: 1, tablet: 2, desktop: 2),
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
          childAspectRatio: context.isMobile ? 3.5 : 4.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCardDummy(
              label: 'NIP', value: dosenData?['nip'] ?? '-', 
              icon: Icons.badge_rounded, color: const Color(0xFF2E6B8A)),
            _StatCardDummy(
              label: 'Semester Aktif', value: activeSemester?['nama'] ?? '-',
              icon: Icons.calendar_today_rounded, color: AppColors.primary),
          ],
        ),
        
        const SizedBox(height: 28),
        const Text('Menu Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 12),
        
        GridView.count(
          crossAxisCount: context.responsive.getGridCount(mobile: 2, tablet: 3, desktop: 4),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12, 
          childAspectRatio: context.isMobile ? 1.2 : 1.3,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: const [
            _MenuCard(icon: Icons.class_rounded,       label: 'Kelas Saya',   color: Color(0xFF2E6B8A)),
            _MenuCard(icon: Icons.fact_check_rounded,  label: 'Absensi',      color: AppColors.primary),
            _MenuCard(icon: Icons.upload_file_rounded, label: 'Materi',       color: Color(0xFF5E2E8A)),
            _MenuCard(icon: Icons.assignment_rounded,  label: 'Tugas',        color: Color(0xFF8A5E2E)),
          ],
        ),
      ]),
    );
  }
}

// Dummy Widget untuk StatCard (karena file admin_dashboard_widgets.dart tidak disertakan)
class _StatCardDummy extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCardDummy({required this.label, required this.value, required this.icon, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Icon(icon, color: color, size: 32), const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ])
      ]),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}