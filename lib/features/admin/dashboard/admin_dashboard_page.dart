import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import 'admin_sidebar.dart';
import 'admin_dashboard_home.dart';
import '../santri/santri_list_page.dart';
import '../dosen/dosen_list_page.dart';
import '../pembina/pembina_list_page.dart';
import '../kelas/kelas_list_page.dart';
import '../all_admin_pages.dart';

/// Admin Dashboard coordinator — hanya routing & state loading.
/// Semua UI detail ada di file masing-masing.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats            = {};
  List<Map<String, dynamic>> _recentSP   = [];
  List<Map<String, dynamic>> _recentSesi = [];
  Map<String, dynamic>? _activeSemester;
  String _adminName = 'Admin';
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getDashboardStats(),
        SupabaseService.getRecentSP(),
        SupabaseService.getRecentAbsensiAkademik(),
        SupabaseService.getActiveSemester(),
        SupabaseService.getMyProfile(),
      ]);
      if (mounted) {
        setState(() {
        _stats          = results[0] as Map<String, dynamic>;
        _recentSP       = results[1] as List<Map<String, dynamic>>;
        _recentSesi     = results[2] as List<Map<String, dynamic>>;
        _activeSemester = results[3] as Map<String, dynamic>?;
        _adminName      = (results[4] as Map?)?['nama_lengkap'] ?? 'Admin';
        _loading        = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(children: [
        AdminSidebar(
          selectedIndex: _selectedIndex,
          adminName: _adminName,
          onSelect: (i) => setState(() => _selectedIndex = i),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildContent()),
      ]),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return AdminDashboardHome(
          stats: _stats, recentSP: _recentSP, recentSesi: _recentSesi,
          activeSemester: _activeSemester, onRefresh: _loadData,
          quickActions: [
            () => setState(() => _selectedIndex = 1),
            () => setState(() => _selectedIndex = 8),
            () => setState(() => _selectedIndex = 7),
            () => setState(() => _selectedIndex = 5),
          ]);
      case 1: return const SantriListPage();
      case 2: return const DosenListPage();
      case 3: return const PembinaListPage();
      case 4: return const KelompokPage();
      case 5: return const KelasListPage();
      case 6: return const SemesterPage();
      case 7: return const GeofencePage();
      case 8: return const PengumumanPage();
      default: return const SizedBox.shrink();
    }
  }
}
