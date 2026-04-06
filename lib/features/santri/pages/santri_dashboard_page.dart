import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class SantriDashboardPage extends StatefulWidget {
  const SantriDashboardPage({super.key});
  @override
  State<SantriDashboardPage> createState() => _SantriDashboardPageState();
}

class _SantriDashboardPageState extends State<SantriDashboardPage> {
  int _idx = 0;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _santri;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SupabaseService.getMyProfile();
    if (p == null) return;
    final s = await SupabaseService.getSantriByProfileId(p['id']);
    if (mounted) setState(() { _profile = p; _santri = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    
    // RESPONSIVE LAYOUT DETECTION
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar dan Drawer hanya muncul di Mobile
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: const Text('Portal Santri', style: TextStyle(fontSize: 16)),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: _SantriSidebar(
                selectedIdx: _idx, profile: _profile, 
                onSelect: (i) {
                  setState(() => _idx = i);
                  Navigator.pop(context); // Tutup drawer setelah diklik
                }
              ))
          : null,
      body: isMobile
          ? _buildContent()
          : Row(children: [
              _SantriSidebar(selectedIdx: _idx, profile: _profile, onSelect: (i) => setState(() => _idx = i)),
              Expanded(child: _buildContent()),
            ]),
    );
  }

  Widget _buildContent() {
    final santriId = _santri?['id'] ?? '';
    switch (_idx) {
      case 0: return _SantriHome(profile: _profile!, santri: _santri!);
      case 1: return _AbsensiSantriPage(santriId: santriId);
      case 2: return _KelasSantriPage(santriId: santriId);
      case 3: return _TugasSantriPage(santriId: santriId);
      case 4: return _RaporSantriPage(santriId: santriId);
      case 5: return _ProfilSantriPage(profile: _profile!, santri: _santri!, onSaved: _load);
      default: return const SizedBox.shrink();
    }
  }
}

// ── Santri Home ───────────────────────────────────────────
class _SantriHome extends StatefulWidget {
  final Map<String, dynamic> profile, santri;
  const _SantriHome({required this.profile, required this.santri});
  @override State<_SantriHome> createState() => _SantriHomeState();
}

class _SantriHomeState extends State<_SantriHome> {
  List<Map<String, dynamic>> _sesiTerbuka = [];
  List<Map<String, dynamic>> _pengumuman = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      SupabaseService.getSesiTerbukaForSantri(widget.santri['id']),
      SupabaseService.getAllPengumuman(),
    ]);
    if (mounted) setState(() { _sesiTerbuka = results[0] as List<Map<String, dynamic>>; _pengumuman = (results[1] as List<Map<String, dynamic>>).take(5).toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.profile['nama_lengkap'] ?? '';
    final nim = widget.santri['nim'] ?? '';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 28), // RESPONSIVE PADDING
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
          // RESPONSIVE HEADER: Gunakan Wrap agar box waktu tidak bertumpuk di HP
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16, runSpacing: 16,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Assalamu\'alaikum 👋', style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: isMobile ? 22 : 28
                )),
                Text('$nama • NIM: $nim', style: const TextStyle(color: AppColors.textLight, fontSize: 14)),
              ]),
              Container(
                padding: const EdgeInsets.all(12), decoration: BoxDecoration(
                color: AppColors.cardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider)),
                child: Column(children: [
                  Text(_timeNow(), style: const TextStyle(fontWeight: FontWeight.w800,
                      fontSize: 18, color: AppColors.textDark)),
                  Text(_dateToday(), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ])),
            ]
          ),
          const SizedBox(height: 24),

          // Sesi terbuka
          if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_sesiTerbuka.isNotEmpty) ...[
            SectionHeader(title: '🔔 Absensi Sedang Terbuka'),
            const SizedBox(height: 12),
            ..._sesiTerbuka.map((s) {
              final kelas = s['kelas'] as Map? ?? {};
              final mk = kelas['mata_kuliah'] as Map? ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12, runSpacing: 12,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.radio_button_checked, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${mk['nama']} — Kelas ${kelas['nama_kelas']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('Kode: ${s['kode_absen']}',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      ]),
                    ]),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      onPressed: () => _showAbsenDialog(context, s),
                      child: const Text('Hadir', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
              );
            }),
          ],

          const SizedBox(height: 8),
          SectionHeader(title: 'Pengumuman Terbaru'),
          const SizedBox(height: 12),
          if (_pengumuman.isEmpty)
            const EmptyState(icon: Icons.campaign_outlined, message: 'Tidak ada pengumuman')
          else ..._pengumuman.map((p) => AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['judul'] ?? '-', style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                Text(p['isi'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
              ])),
              Text(p['created_at']?.toString().substring(0,10) ?? '',
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            ]),
          )),
        ]),
      ),
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
  }

  String _dateToday() {
    final now = DateTime.now();
    final days = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];
    return '${days[now.weekday % 7]}, ${now.day}/${now.month}/${now.year}';
  }

  void _showAbsenDialog(BuildContext context, Map<String, dynamic> sesi) {
    String? selectedStatus;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox( // CONSTRAINT UNTUK DIALOG
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Konfirmasi Kehadiran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark)),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: ['hadir','izin','sakit','terlambat'].map((s) =>
              GestureDetector(
                onTap: () => setSt(() => selectedStatus = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedStatus == s ? _statusColor(s) : _statusColor(s).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _statusColor(s).withOpacity(0.4)),
                  ),
                  child: Text(s.toUpperCase(), style: TextStyle(
                      color: selectedStatus == s ? Colors.white : _statusColor(s),
                      fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              )).toList()),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: selectedStatus == null ? null : () async {
                await SupabaseService.absenAkademik(
                  sesiId: sesi['id'], santriId: widget.santri['id'],
                  status: selectedStatus!, lat: null, lng: null,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showSuccess(context, 'Absensi berhasil dicatat');
                _load();
              },
              child: const Text('Konfirmasi'),
            ),
          ]),
        ])),
      ),
    )));
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'hadir': return AppColors.primary;
      case 'terlambat': return Colors.orange;
      case 'izin': return Colors.blue;
      case 'sakit': return Colors.purple;
      default: return AppColors.error;
    }
  }
}

// ── Absensi Santri ────────────────────────────────────────
class _AbsensiSantriPage extends StatefulWidget {
  final String santriId;
  const _AbsensiSantriPage({required this.santriId});
  @override State<_AbsensiSantriPage> createState() => _AbsensiSantriPageState();
}

class _AbsensiSantriPageState extends State<_AbsensiSantriPage> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getAbsensiAkademiSantri(widget.santriId);
    if (mounted) setState(() { _history = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(backgroundColor: AppColors.background, body: Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Riwayat Absensi', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: isMobile ? 22 : 26
        )),
        const Text('30 sesi terakhir', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        const SizedBox(height: 20),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _history.isEmpty
            ? const EmptyState(icon: Icons.how_to_reg_outlined, message: 'Belum ada riwayat absensi')
            : ListView.separated(
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final a = _history[i];
                  final sesi = a['sesi'] as Map? ?? {};
                  final kelas = sesi['kelas'] as Map? ?? {};
                  final mk = kelas['mata_kuliah'] as Map? ?? {};
                  final status = a['status'] ?? 'alpha';
                  Color statusColor;
                  switch (status) {
                    case 'hadir': statusColor = AppColors.primary; break;
                    case 'terlambat': statusColor = Colors.orange; break;
                    case 'izin': statusColor = Colors.blue; break;
                    case 'sakit': statusColor = Colors.purple; break;
                    default: statusColor = AppColors.error;
                  }
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: statusColor.withOpacity(0.12),
                      child: Icon(Icons.class_rounded, color: statusColor, size: 18)),
                    title: Text('${mk['nama']} — Kelas ${kelas['nama_kelas']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(sesi['tanggal']?.toString() ?? '-',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    trailing: StatusBadge(label: status.toUpperCase(), color: statusColor),
                  );
                })),
      ]),
    ));
  }
}

// ── Kelas Santri ──────────────────────────────────────────
class _KelasSantriPage extends StatefulWidget {
  final String santriId;
  const _KelasSantriPage({required this.santriId});
  @override State<_KelasSantriPage> createState() => _KelasSantriPageState();
}

class _KelasSantriPageState extends State<_KelasSantriPage> {
  List<Map<String, dynamic>> _kelas = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getKelasForSantri(widget.santriId);
    if (mounted) setState(() { _kelas = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(backgroundColor: AppColors.background, body: Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Kelas Saya', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: isMobile ? 22 : 26
        )),
        Text('${_kelas.length} kelas terdaftar', style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
        const SizedBox(height: 20),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _kelas.isEmpty
            ? const EmptyState(icon: Icons.class_outlined, message: 'Belum terdaftar di kelas manapun')
            : GridView.builder(
                // RESPONSIVE GRID
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : (screenWidth < 900 ? 2 : 3), 
                    crossAxisSpacing: 16, mainAxisSpacing: 16, 
                    childAspectRatio: isMobile ? 2.5 : 1.5),
                itemCount: _kelas.length,
                itemBuilder: (_, i) {
                  final ks = _kelas[i];
                  final k = ks['kelas'] as Map? ?? {};
                  final mk = k['mata_kuliah'] as Map? ?? {};
                  final dosen = k['dosen'] as Map? ?? {};
                  final dosenProfile = dosen['profile'] as Map? ?? {};
                  return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      StatusBadge(label: 'Kelas ${k['nama_kelas']}', color: AppColors.primary),
                      const Spacer(),
                      StatusBadge(label: k['hari'] ?? '', color: AppColors.textMid),
                    ]),
                    const SizedBox(height: 8),
                    Text(mk['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 14, color: AppColors.textDark), maxLines: 2),
                    Text('${mk['kode']} • ${mk['sks']} SKS',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    const Spacer(),
                    const Divider(color: AppColors.divider),
                    Row(children: [
                      const Icon(Icons.room, size: 13, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(k['ruangan'] ?? '-', style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
                      const Spacer(),
                      const Icon(Icons.person, size: 13, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Flexible(child: Text(dosenProfile['nama_lengkap'] ?? '-',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMid),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  ]));
                })),
      ]),
    ));
  }
}

// ── Tugas Santri ──────────────────────────────────────────
class _TugasSantriPage extends StatefulWidget {
  final String santriId;
  const _TugasSantriPage({required this.santriId});
  @override State<_TugasSantriPage> createState() => _TugasSantriPageState();
}

class _TugasSantriPageState extends State<_TugasSantriPage> {
  List<Map<String, dynamic>> _tugas = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getTugasForSantri(widget.santriId);
    if (mounted) setState(() { _tugas = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(backgroundColor: AppColors.background, body: Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Daftar Tugas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: isMobile ? 22 : 26
        )),
        const SizedBox(height: 20),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tugas.isEmpty
            ? const EmptyState(icon: Icons.assignment_outlined, message: 'Tidak ada tugas')
            : ListView.separated(
                itemCount: _tugas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final t = _tugas[i];
                  final kelas = t['kelas'] as Map? ?? {};
                  final mk = kelas['mata_kuliah'] as Map? ?? {};
                  final sudahKumpul = (t['pengumpulan_tugas'] as List?)?.isNotEmpty ?? false;
                  final deadline = DateTime.tryParse(t['deadline'] ?? '');
                  final isExpired = deadline != null && deadline.isBefore(DateTime.now());
                  return AppCard(child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12, runSpacing: 12,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: (sudahKumpul ? AppColors.primary : isExpired ? AppColors.error : Colors.orange).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(sudahKumpul ? Icons.check_circle_rounded : Icons.assignment_rounded,
                              color: sudahKumpul ? AppColors.primary : isExpired ? AppColors.error : Colors.orange, size: 22)),
                        const SizedBox(width: 14),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 14, color: AppColors.textDark)),
                          Text('${mk['nama']} — Kelas ${kelas['nama_kelas']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
                          Text('Deadline: ${t['deadline']?.toString().substring(0,10) ?? '-'}',
                              style: TextStyle(fontSize: 11,
                                  color: isExpired ? AppColors.error : AppColors.textLight)),
                        ]),
                      ]),
                      if (!sudahKumpul && !isExpired)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          onPressed: () => _showKumpulDialog(context, t),
                          child: const Text('Kumpulkan', style: TextStyle(fontSize: 12)),
                        )
                      else if (sudahKumpul)
                        const StatusBadge(label: 'TERKUMPUL', color: AppColors.primary),
                  ]));
                })),
      ]),
    ));
  }

  void _showKumpulDialog(BuildContext ctx, Map<String, dynamic> tugas) {
    final fileUrl = TextEditingController();
    final catatan = TextEditingController();
    showDialog(context: ctx, builder: (dCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox( // CONSTRAINT UNTUK DIALOG
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Kumpulkan: ${tugas['judul']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          TextField(controller: fileUrl, decoration: const InputDecoration(
              labelText: 'URL File Jawaban (Google Drive / etc.)',
              prefixIcon: Icon(Icons.link_rounded, color: AppColors.textLight, size: 18))),
          const SizedBox(height: 12),
          TextField(controller: catatan, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)', alignLabelWithHint: true)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Batal')),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                if (fileUrl.text.isEmpty) return;
                await SupabaseService.kumpulkanTugas(
                  tugasId: tugas['id'], santriId: widget.santriId,
                  fileUrl: fileUrl.text, catatan: catatan.text.isNotEmpty ? catatan.text : null,
                );
                if (dCtx.mounted) Navigator.pop(dCtx);
                if (mounted) showSuccess(ctx, 'Tugas berhasil dikumpulkan!');
                _load();
              },
              child: const Text('Kumpulkan'),
            ),
          ]),
        ])),
      ),
    ));
  }
}

// ── Rapor Santri ──────────────────────────────────────────
class _RaporSantriPage extends StatefulWidget {
  final String santriId;
  const _RaporSantriPage({required this.santriId});
  @override State<_RaporSantriPage> createState() => _RaporSantriPageState();
}

class _RaporSantriPageState extends State<_RaporSantriPage> {
  Map<String, dynamic>? _rapor;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (widget.santriId.isNotEmpty) {
      final data = await SupabaseService.getRaporSantri(widget.santriId);
      if (mounted) setState(() { _rapor = data; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final akademik = (_rapor?['absensi_akademik'] as List?) ?? [];
    final spList = (_rapor?['sp_aktif'] as List?) ?? [];
    final ibadah = (_rapor?['absensi_ibadah'] as List?) ?? [];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(backgroundColor: AppColors.background, body: _loading
      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      : SingleChildScrollView(padding: EdgeInsets.all(isMobile ? 16 : 28), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Rapor Saya', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: isMobile ? 22 : 26
        )),
        const SizedBox(height: 20),

        // Summary cards RESPONSIVE
        GridView.count(
          crossAxisCount: isMobile ? 1 : 3, // RESPONSIVE GRID
          crossAxisSpacing: 16, mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 3.0 : 2.0, 
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(label: 'Kelas Diikuti', icon: Icons.class_rounded,
                value: '${akademik.length}', gradient: AppColors.gradSantri),
            StatCard(label: 'SP Aktif', icon: Icons.warning_rounded,
                value: '${spList.length}', gradient: AppColors.gradSP,
                subtitle: spList.isEmpty ? 'Baik sekali!' : 'Perlu perhatian'),
            StatCard(label: 'Rekap Ibadah', icon: Icons.mosque_rounded,
                value: '${ibadah.length}', gradient: AppColors.gradDosen),
          ],
        ),
        const SizedBox(height: 24),

        // Akademik
        SectionHeader(title: 'Kehadiran Akademik'),
        const SizedBox(height: 12),
        if (akademik.isEmpty)
          const EmptyState(icon: Icons.class_outlined, message: 'Belum ada data kehadiran')
        else 
          AppCard(padding: EdgeInsets.zero, child: 
            // MENCEGAH OVERFLOW DI HP DENGAN HORIZONTAL SCROLL
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isMobile ? 600 : 0), // Paksa tabel minimum 600px lebar
                child: Column(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: const [
                      Expanded(flex: 3, child: Text('MATA KULIAH', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textLight, letterSpacing: 0.5))),
                      Expanded(child: Text('HADIR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textLight))),
                      Expanded(child: Text('ALPHA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textLight))),
                      Expanded(child: Text('IZIN/SAKIT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textLight))),
                      Expanded(child: Text('%', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textLight))),
                    ])),
                  const Divider(height: 1, color: AppColors.divider),
                  ...akademik.map((a) {
                    final pct = (a['persentase_hadir'] ?? 0.0) as num;
                    final color = pct >= 75 ? AppColors.primary : pct >= 50 ? Colors.orange : AppColors.error;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a['nama_matkul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Kelas ${a['nama_kelas']}', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ])),
                        Expanded(child: Text('${a['hadir'] ?? 0}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
                        Expanded(child: Text('${a['alpha'] ?? 0}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
                        Expanded(child: Text('${(a['izin'] ?? 0) + (a['sakit'] ?? 0)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700))),
                        Expanded(child: Row(children: [
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: pct / 100,
                                backgroundColor: color.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation(color), minHeight: 6))),
                          const SizedBox(width: 6),
                          Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                        ])),
                      ]),
                    );
                  }),
                ]),
              ),
            )
          ),
        const SizedBox(height: 24),

        // SP
        if (spList.isNotEmpty) ...[
          SectionHeader(title: 'Surat Peringatan Aktif'),
          const SizedBox(height: 12),
          ...spList.map((sp) => AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Text(sp['level'] ?? 'SP1', style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 12)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(sp['alasan'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${sp['tanggal_sp']} • ${sp['status']}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              ])),
            ]),
          )),
        ],
      ])),
    );
  }
}

// ── Profil Santri ─────────────────────────────────────────
class _ProfilSantriPage extends StatefulWidget {
  final Map<String, dynamic> profile, santri;
  final VoidCallback onSaved;
  const _ProfilSantriPage({required this.profile, required this.santri, required this.onSaved});
  @override State<_ProfilSantriPage> createState() => _ProfilSantriPageState();
}

class _ProfilSantriPageState extends State<_ProfilSantriPage> {
  late final _nama  = TextEditingController(text: widget.profile['nama_lengkap']);
  late final _email = TextEditingController(text: widget.profile['email']);
  late final _noHp  = TextEditingController(text: widget.profile['no_hp'] ?? '');
  late final _alamat = TextEditingController(text: widget.profile['alamat'] ?? '');
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Komponen Avatar Kiri
    final avatarCard = AppCard(child: Column(children: [
      CircleAvatar(radius: 48,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        child: Text((widget.profile['nama_lengkap'] ?? 'S')[0].toUpperCase(),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 36))),
      const SizedBox(height: 16),
      Text(widget.profile['nama_lengkap'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark)),
      const SizedBox(height: 4),
      Text('NIM: ${widget.santri['nim'] ?? '-'}',
          style: const TextStyle(fontSize: 14, color: AppColors.textMid)),
      const SizedBox(height: 8),
      StatusBadge(label: (widget.santri['status'] ?? 'aktif').toUpperCase(), color: AppColors.primary),
      const SizedBox(height: 12),
      Text('Angkatan ${widget.santri['angkatan'] ?? '-'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
    ]));

    // Komponen Form Edit Kanan
    final formCard = AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
      const SizedBox(height: 4),
      const Text('NIM tidak dapat diubah', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
      const SizedBox(height: 16),
      TextField(controller: _nama, decoration: const InputDecoration(
          labelText: 'Nama Lengkap',
          prefixIcon: Icon(Icons.person_rounded, color: AppColors.textLight, size: 18))),
      const SizedBox(height: 12),
      TextField(controller: _email, enabled: false,
          decoration: const InputDecoration(labelText: 'Email (tidak dapat diubah)',
              prefixIcon: Icon(Icons.email_rounded, color: AppColors.textLight, size: 18))),
      const SizedBox(height: 12),
      TextField(controller: _noHp, keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'No. HP',
              prefixIcon: Icon(Icons.phone_rounded, color: AppColors.textLight, size: 18))),
      const SizedBox(height: 12),
      TextField(controller: _alamat, maxLines: 2,
          decoration: const InputDecoration(labelText: 'Alamat', alignLabelWithHint: true,
              prefixIcon: Icon(Icons.home_rounded, color: AppColors.textLight, size: 18))),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _loading ? null : _save,
        child: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Simpan Perubahan'),
      )),
    ]));

    return Scaffold(backgroundColor: AppColors.background, body: SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Profil Saya', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: isMobile ? 22 : 26
        )),
        const SizedBox(height: 24),
        // RESPONSIVE LAYOUT PROFIL
        if (isMobile) ...[
          avatarCard,
          const SizedBox(height: 20),
          formCard,
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: avatarCard),
            const SizedBox(width: 20),
            Expanded(flex: 4, child: formCard),
          ]),
      ]),
    ));
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.client.from('profiles').update({
        'nama_lengkap': _nama.text, 'no_hp': _noHp.text, 'alamat': _alamat.text,
      }).eq('id', widget.profile['id']);
      if (mounted) showSuccess(context, 'Profil berhasil diperbarui');
      widget.onSaved();
    } catch (e) {
      if (mounted) showError(context, 'Error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }
}

// ── Santri Sidebar ────────────────────────────────────────
class _SantriSidebar extends StatelessWidget {
  final int selectedIdx;
  final Map<String, dynamic>? profile;
  final ValueChanged<int> onSelect;

  const _SantriSidebar({required this.selectedIdx, required this.profile, required this.onSelect});

  static const _items = [
    _SNI(icon: Icons.dashboard_rounded, label: 'Beranda'),
    _SNI(icon: Icons.how_to_reg_rounded, label: 'Absensi'),
    _SNI(icon: Icons.class_rounded, label: 'Kelas Saya'),
    _SNI(icon: Icons.assignment_rounded, label: 'Tugas'),
    _SNI(icon: Icons.bar_chart_rounded, label: 'Rapor Saya'),
    _SNI(icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final nama = profile?['nama_lengkap'] ?? '';
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: isMobile ? double.infinity : 220, // RESPONSIVE WIDTH
      color: AppColors.primary,
      child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 32)),
          const SizedBox(height: 8),
          const Text('SIMAMAH', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const Text('SANTRI', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
        ])),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 8),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          itemCount: _items.length,
          itemBuilder: (_, i) {
            final item = _items[i];
            final sel = selectedIdx == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? Colors.white.withOpacity(0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(item.icon, color: sel ? Colors.white : Colors.white60, size: 18),
                  const SizedBox(width: 10),
                  Text(item.label, style: TextStyle(
                      color: sel ? Colors.white : Colors.white70,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
                ]),
              ),
            );
          },
        )),
        const Divider(color: Colors.white24, height: 1),
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(child: Text(nama, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 11), overflow: TextOverflow.ellipsis)),
          IconButton(onPressed: () async {
            await SupabaseService.signOut();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
          }, icon: const Icon(Icons.logout_rounded, color: Colors.white60, size: 16)),
        ])),
      ])),
    );
  }
}

class _SNI {
  final IconData icon;
  final String label;
  const _SNI({required this.icon, required this.label});
}