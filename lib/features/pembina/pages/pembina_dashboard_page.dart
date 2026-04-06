import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';
import '../widgets/pembina_sidebar.dart';
import 'pembina_home_page.dart';
import 'absensi_ibadah_page.dart';
import 'monitoring_sp_page.dart';

class PembinaDashboardPage extends StatefulWidget {
  const PembinaDashboardPage({super.key});
  @override
  State<PembinaDashboardPage> createState() => _PembinaDashboardPageState();
}

class _PembinaDashboardPageState extends State<PembinaDashboardPage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _pembinaData;
  Map<String, dynamic>? _kelompok;
  bool _loading = true;
  String _pembinaName = 'Pembina';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final profile = await SupabaseService.getMyProfile();
      if (mounted) setState(() => _pembinaName = profile?['nama_lengkap'] ?? 'Pembina');

      final pembina = await SupabaseService.client
          .from('pembina').select('id, kode_pembina')
          .eq('profile_id', SupabaseService.currentUser!.id).single();

      final sem = await SupabaseService.getActiveSemester();
      if (sem != null) {
        final kelompok = await SupabaseService.client
            .from('kelompok_pembina').select('''
              id, nama_kelompok,
              kelompok_santri(id,
                santri:santri_id(id, nim, profile:profile_id(nama_lengkap)))
            ''')
            .eq('pembina_id', pembina['id'])
            .eq('semester_id', sem['id'])
            .maybeSingle();
        if (mounted) setState(() { _pembinaData = pembina; _kelompok = kelompok; });
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  List<Map<String, dynamic>> get _santriList =>
      (_kelompok?['kelompok_santri'] as List?)
          ?.cast<Map<String, dynamic>>() ?? [];

  @override
  Widget build(BuildContext context) {
    // Deteksi Layar Responsif
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar & Drawer hanya muncul di HP
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF8A5E2E),
              foregroundColor: Colors.white,
              title: const Text('Portal Pembina', style: TextStyle(fontSize: 16)),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: PembinaSidebar(
                selectedIndex: _selectedIndex,
                pembinaName: _pembinaName,
                onSelect: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context); // Tutup drawer setelah klik
                },
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : isMobile 
              ? _buildContent() // Jika mobile, sidebar disembunyikan
              : Row(children: [ // Jika desktop, sidebar disamping
                  PembinaSidebar(
                    selectedIndex: _selectedIndex,
                    pembinaName: _pembinaName,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                  ),
                  Expanded(child: _buildContent()),
                ]),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return PembinaHomePage(kelompok: _kelompok, onRefresh: _loadData);
      case 1: return AbsensiIbadahPage(kelompokId: _kelompok?['id'], santriList: _santriList);
      case 2: return MonitoringPage(kelompokId: _kelompok?['id'], santriList: _santriList);
      case 3: return SPPage(pembinaId: _pembinaData?['id'], santriList: _santriList);
      case 4: return _LaporanPage(kelompokId: _kelompok?['id']);
      default: return const SizedBox.shrink();
    }
  }
}

// ── Laporan Page (ringan) ─────────────────────────────────
class _LaporanPage extends StatefulWidget {
  final String? kelompokId;
  const _LaporanPage({required this.kelompokId});
  @override State<_LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<_LaporanPage> {
  DateTime? _dari, _sampai;
  String _kategori  = 'semua';
  bool _generating  = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView( // Hindari overflow
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Laporan Ibadah', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: isMobile ? 22 : 26
          )),
          const SizedBox(height: 4),
          const Text('Cetak rekap absensi sholat dalam format PDF.',
            style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 24),
          
          // ConstrainedBox agar form form tidak terlalu lebar di PC, tapi pas di HP
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), 
            child: Column(children: [
              _DateBtn(label: _dari == null ? 'Pilih Tanggal Mulai'
                : '${_dari!.day}/${_dari!.month}/${_dari!.year}',
                icon: Icons.calendar_today_rounded,
                onTap: () async {
                  final d = await showDatePicker(context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setState(() => _dari = d);
                }),
              const SizedBox(height: 12),
              _DateBtn(label: _sampai == null ? 'Pilih Tanggal Akhir'
                : '${_sampai!.day}/${_sampai!.month}/${_sampai!.year}',
                icon: Icons.calendar_month_rounded,
                onTap: () async {
                  final d = await showDatePicker(context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) setState(() => _sampai = d);
                }),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: const [
                  DropdownMenuItem(value: 'semua',  child: Text('Semua')),
                  DropdownMenuItem(value: 'wajib',  child: Text('Wajib')),
                  DropdownMenuItem(value: 'sunnah', child: Text('Sunnah')),
                ],
                onChanged: (v) => setState(() => _kategori = v!),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: _generating ? null : () async {
                  if (_dari == null || _sampai == null) {
                    showError(context, 'Pilih rentang tanggal');
                    return;
                  }
                  setState(() => _generating = true);
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() => _generating = false);
                  if (mounted) {
                    showSuccess(context, 'Tambahkan package "pdf" & "printing" untuk cetak PDF.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A5E2E),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
                icon: _generating
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(_generating ? 'Menyiapkan...' : 'Cetak PDF'))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DateBtn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
      ]),
    ),
  );
}