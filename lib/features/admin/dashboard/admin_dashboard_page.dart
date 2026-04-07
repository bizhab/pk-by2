import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import 'admin_sidebar.dart';
import 'admin_dashboard_home.dart';
import '../santri/santri_list_page.dart';
import '../dosen/dosen_list_page.dart';
import '../pembina/pembina_list_page.dart';
import '../kelas/kelas_list_page.dart' show KelasListPage;
import '../all_admin_pages.dart';

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
    // Tentukan threshold untuk layar desktop/tablet besar
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Tampilkan AppBar hanya di tampilan mobile/tablet kecil
      appBar: isDesktop 
          ? null 
          : AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: const Text('SIMAMAH Panel Admin', style: TextStyle(fontSize: 16)),
              elevation: 0,
            ),
      // Pindahkan Sidebar ke dalam Drawer untuk layar kecil
      drawer: isDesktop 
          ? null 
          : Drawer(
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                adminName: _adminName,
                onSelect: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context); // Tutup drawer setelah menu dipilih
                },
              ),
            ),
      body: isDesktop
          ? Row(children: [
              AdminSidebar(
                selectedIndex: _selectedIndex,
                adminName: _adminName,
                onSelect: (i) => setState(() => _selectedIndex = i),
              ),
              Expanded(child: _buildBodyContent()),
            ])
          : _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _buildContent();
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