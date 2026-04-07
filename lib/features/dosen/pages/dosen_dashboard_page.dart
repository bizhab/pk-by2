import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';
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
      print('[DosenDashboard] Error: $e');
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

    final isMobile = MediaQuery.of(context).size.width < 800;
    print('[DosenDashboard] build: isMobile=$isMobile, selectedIndex=$_selectedIndex, dosenData=${_dosenData?['nama_lengkap']}');

    return Scaffold(
      backgroundColor: AppColors.background,
      // RESPONSIVE APPBAR: Hanya muncul di mobile
      appBar: isMobile 
          ? AppBar(
              backgroundColor: const Color(0xFF2E6B8A),
              foregroundColor: Colors.white,
              title: const Text('Panel Dosen', style: TextStyle(fontSize: 16)),
            ) 
          : null,
      // RESPONSIVE DRAWER: Pindahkan sidebar ke menu samping di HP
      drawer: isMobile 
          ? Drawer(
              child: DosenSidebar(
                selectedIndex: _selectedIndex,
                nama: _dosenData?['nama_lengkap'] ?? 'Dosen',
                onSelect: (i) {
                  print('[DosenDashboard] Sidebar selected: $i');
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: isMobile
          ? _buildContent()
          : Row(children: [
              DosenSidebar(
                selectedIndex: _selectedIndex,
                nama: _dosenData?['nama_lengkap'] ?? 'Dosen',
                onSelect: (i) {
                  print('[DosenDashboard] Desktop sidebar selected: $i');
                  setState(() => _selectedIndex = i);
                },
              ),
              Expanded(child: _buildContent()),
            ]),
    );
  }

  Widget _buildContent() {
    print('[DosenDashboard] _buildContent: selectedIndex=$_selectedIndex');
    final dosenId = _dosenData?['dosen_id']?.toString() ?? '';
    final semId   = _activeSemester?['id']?.toString() ?? '';
    
    switch (_selectedIndex) {
      case 0: 
        print('[DosenDashboard] Building DosenHomePage');
        return _DosenHomePage(dosenData: _dosenData, activeSemester: _activeSemester);
      case 1: 
        print('[DosenDashboard] Building DosenKelasPage with dosenId=$dosenId, semId=$semId');
        return DosenKelasPage(dosenId: dosenId, semesterId: semId);
      case 2: 
        print('[DosenDashboard] Building DosenAbsensiPage with dosenId=$dosenId');
        return DosenAbsensiPage(dosenId: dosenId);
      case 3: 
        print('[DosenDashboard] Building DosenMateriPage with dosenId=$dosenId, semId=$semId');
        return DosenMateriPage(dosenId: dosenId, semesterId: semId);
      case 4: 
        print('[DosenDashboard] Building DosenTugasPage with dosenId=$dosenId, semId=$semId');
        return DosenTugasPage(dosenId: dosenId, semesterId: semId);
      default: 
        print('[DosenDashboard] Unknown index: $_selectedIndex');
        return const SizedBox.shrink();
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
        
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Selamat Datang, ${dosenData?['nama_lengkap'] ?? 'Dosen'} 👋',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: isMobile ? 22 : 28
          )),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.circle, color: AppColors.secondary, size: 8),
          const SizedBox(width: 6),
          Expanded(child: Text('Semester: $semLabel',
            style: const TextStyle(color: AppColors.textMid, fontSize: 13))),
        ]),
        const SizedBox(height: 28),
        
        // RESPONSIVE CARDS: Susun ke bawah di HP
        if (isMobile) ...[
          StatCard(
            label: 'NIP', value: dosenData?['nip'] ?? '-', icon: Icons.badge_rounded,
            gradient: const [Color(0xFF2E6B8A), Color(0xFF4A9BBF)]),
          const SizedBox(height: 12),
          StatCard(
            label: 'Semester Aktif', value: activeSemester?['nama'] ?? '-',
            icon: Icons.calendar_today_rounded, gradient: AppColors.gradSantri),
        ] else 
          Row(children: [
            Expanded(child: StatCard(
              label: 'NIP', value: dosenData?['nip'] ?? '-', icon: Icons.badge_rounded,
              gradient: const [Color(0xFF2E6B8A), Color(0xFF4A9BBF)])),
            const SizedBox(width: 16),
            Expanded(child: StatCard(
              label: 'Semester Aktif', value: activeSemester?['nama'] ?? '-',
              icon: Icons.calendar_today_rounded, gradient: AppColors.gradSantri)),
          ]),
        
        const SizedBox(height: 28),
        SectionHeader(title: 'Menu Utama'),
        const SizedBox(height: 12),
        
        // RESPONSIVE GRID MENU
        GridView.count(
          crossAxisCount: isMobile ? 2 : (screenWidth < 900 ? 3 : 4),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12, childAspectRatio: isMobile ? 1.5 : 1.3,
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
          color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}