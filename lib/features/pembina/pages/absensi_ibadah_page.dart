import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class AbsensiIbadahPage extends StatefulWidget {
  final String? kelompokId;
  final List<Map<String, dynamic>> santriList;

  const AbsensiIbadahPage({
    super.key,
    required this.kelompokId,
    required this.santriList,
  });

  @override
  State<AbsensiIbadahPage> createState() => _AbsensiIbadahPageState();
}

class _AbsensiIbadahPageState extends State<AbsensiIbadahPage> {
  List<Map<String, dynamic>> _jadwal    = [];
  List<Map<String, dynamic>> _sesiHariIni = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jadwal = await SupabaseService.getJadwalSholat();
      List<Map<String, dynamic>> sesi = [];
      if (widget.kelompokId != null) {
        final today = DateTime.now().toIso8601String().split('T').first;
        sesi = await SupabaseService.client
            .from('sesi_absensi_ibadah')
            .select('id, jam_buka, jam_tutup, jadwal_sholat_id')
            .eq('kelompok_pembina_id', widget.kelompokId!)
            .eq('tanggal', today);
      }
      setState(() { _jadwal = jadwal; _sesiHariIni = sesi; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  bool _isSesiOpen(String jadwalId) =>
      _sesiHariIni.any((s) =>
          s['jadwal_sholat_id'] == jadwalId && s['jam_tutup'] == null);

  String? _getSesiId(String jadwalId) {
    try {
      return _sesiHariIni.firstWhere((s) =>
          s['jadwal_sholat_id'] == jadwalId && s['jam_tutup'] == null)['id'];
    } catch (_) { return null; }
  }

  Future<void> _bukaSesi(Map<String, dynamic> jadwal) async {
    if (widget.kelompokId == null) return;
    try {
      final geofence = await SupabaseService.getActiveGeofence();
      final today    = DateTime.now().toIso8601String().split('T').first;
      final res = await SupabaseService.client
          .from('sesi_absensi_ibadah').insert({
            'kelompok_pembina_id': widget.kelompokId,
            'jadwal_sholat_id'   : jadwal['id'],
            'tanggal'            : today,
            'geofence_id'        : geofence?['id'],
            'dibuka_oleh'        : SupabaseService.currentUser?.id,
          }).select().single();

      if (widget.santriList.isNotEmpty) {
        await SupabaseService.client.from('absensi_ibadah').upsert(
          widget.santriList.map((ks) {
            final s = ks['santri'] as Map? ?? {};
            return {'sesi_id': res['id'], 'santri_id': s['id'], 'status': 'alpha'};
          }).toList(),
          onConflict: 'sesi_id,santri_id',
        );
      }
      if (mounted) showSuccess(context, "Sesi ${jadwal['nama_sholat']} dibuka!");
      _load();
    } catch (e) {
      if (mounted) showError(context, 'Gagal: $e');
    }
  }

  Future<void> _tutupSesi(String sesiId, String nama) async {
    try {
      await SupabaseService.client.from('sesi_absensi_ibadah')
          .update({'jam_tutup': DateTime.now().toIso8601String()}).eq('id', sesiId);
      if (mounted) showSuccess(context, 'Sesi $nama ditutup.');
      _load();
    } catch (e) {
      if (mounted) showError(context, 'Gagal: $e');
    }
  }

  void _lihatAbsensi(String sesiId, String namaSholat) {
    showDialog(context: context,
      builder: (_) => _AbsensiDialog(
        sesiId: sesiId, namaSholat: namaSholat, santriList: widget.santriList));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kelompokId == null) {
      return const Center(child: EmptyState(
        icon: Icons.mosque_outlined,
        message: 'Belum ada kelompok aktif.\nHubungi admin.'));
    }
    final wajib  = _jadwal.where((j) => j['kategori'] == 'wajib').toList();
    final sunnah = _jadwal.where((j) => j['kategori'] == 'sunnah').toList();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        color: const Color(0xFF8A5E2E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 28), // RESPONSIVE PADDING
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Absensi Ibadah',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isMobile ? 22 : 26
                )),
            const SizedBox(height: 4),
            const Text('Buka sesi absensi untuk setiap waktu sholat.',
                style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            const SizedBox(height: 24),
            _SholatSection(
              title: 'Sholat Wajib', color: AppColors.primary,
              jadwalList: wajib, loading: _loading,
              isSesiOpen: _isSesiOpen, getSesiId: _getSesiId,
              onBuka: _bukaSesi, onTutup: _tutupSesi,
              onAbsensi: _lihatAbsensi),
            const SizedBox(height: 24),
            _SholatSection(
              title: 'Sholat Sunnah', color: const Color(0xFF2E6B8A),
              jadwalList: sunnah, loading: _loading,
              isSesiOpen: _isSesiOpen, getSesiId: _getSesiId,
              onBuka: _bukaSesi, onTutup: _tutupSesi,
              onAbsensi: _lihatAbsensi),
          ]),
        ),
      ),
    );
  }
}

// ── Sholat Section Widget ─────────────────────────────────
class _SholatSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> jadwalList;
  final bool loading;
  final bool Function(String) isSesiOpen;
  final String? Function(String) getSesiId;
  final Future<void> Function(Map<String, dynamic>) onBuka;
  final Future<void> Function(String, String) onTutup;
  final void Function(String, String) onAbsensi;

  const _SholatSection({
    required this.title, required this.color, required this.jadwalList,
    required this.loading, required this.isSesiOpen, required this.getSesiId,
    required this.onBuka, required this.onTutup, required this.onAbsensi,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color)),
      ]),
      const SizedBox(height: 12),
      if (loading)
        const Center(child: CircularProgressIndicator())
      else
        ...jadwalList.map((j) => _SholatRow(
          jadwal: j, color: color,
          isOpen: isSesiOpen(j['id']), sesiId: getSesiId(j['id']),
          onBuka: onBuka, onTutup: onTutup, onAbsensi: onAbsensi)),
    ]);
  }
}

class _SholatRow extends StatelessWidget {
  final Map<String, dynamic> jadwal;
  final Color color;
  final bool isOpen;
  final String? sesiId;
  final Future<void> Function(Map<String, dynamic>) onBuka;
  final Future<void> Function(String, String) onTutup;
  final void Function(String, String) onAbsensi;

  const _SholatRow({
    required this.jadwal, required this.color, required this.isOpen,
    required this.sesiId, required this.onBuka,
    required this.onTutup, required this.onAbsensi,
  });

  @override
  Widget build(BuildContext context) {
    final mulai  = jadwal['jam_mulai']?.toString().substring(0, 5) ?? '-';
    final selesai= jadwal['jam_selesai']?.toString().substring(0, 5) ?? '-';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Wrap( // Gunakan Wrap agar tombol tidak overflow di HP
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12, runSpacing: 12,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.mosque_rounded, color: color, size: 22)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(jadwal['nama_sholat'] ?? '-', style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                Text('$mulai — $selesai',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
              ]),
            ]),
            if (isOpen && sesiId != null) 
              Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton.icon(
                  onPressed: () => onAbsensi(sesiId!, jadwal['nama_sholat']),
                  icon: const Icon(Icons.list_alt_rounded, size: 16),
                  label: const Text('Absensi', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: color)),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () => onTutup(sesiId!, jadwal['nama_sholat']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  child: const Text('Tutup', style: TextStyle(fontSize: 12))),
              ])
            else
              ElevatedButton.icon(
                onPressed: () => onBuka(jadwal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Buka', style: TextStyle(fontSize: 12))),
          ]),
      ),
    );
  }
}

// ── Absensi Dialog ────────────────────────────────────────
class _AbsensiDialog extends StatefulWidget {
  final String sesiId, namaSholat;
  final List<Map<String, dynamic>> santriList;
  const _AbsensiDialog(
      {required this.sesiId, required this.namaSholat, required this.santriList});
  @override State<_AbsensiDialog> createState() => _AbsensiDialogState();
}

class _AbsensiDialogState extends State<_AbsensiDialog> {
  List<Map<String, dynamic>> _absensi = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.client
        .from('absensi_ibadah')
        .select('id, status, santri_id')
        .eq('sesi_id', widget.sesiId);
    if(mounted) setState(() { _absensi = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox( // CONSTRAINT UNTUK DIALOG
        constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              const Icon(Icons.mosque_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Absensi ${widget.namaSholat}',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white)),
            ]),
          ),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.santriList.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final ks   = widget.santriList[i];
                  final s    = ks['santri'] as Map? ?? {};
                  final p    = s['profile'] as Map? ?? {};
                  final nama = p['nama_lengkap'] ?? '-';
                  final ab   = _absensi.firstWhere(
                      (a) => a['santri_id'] == s['id'], orElse: () => {});
                  final status   = ab['status'] ?? 'alpha';
                  final absensiId= ab['id'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.w700))),
                    title: Text(nama,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(s['nim'] ?? '',
                      style: const TextStyle(fontSize: 11)),
                    trailing: DropdownButton<String>(
                      value: status,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'hadir', child: Text('✅ Hadir')),
                        DropdownMenuItem(value: 'alpha', child: Text('❌ Alpha')),
                        DropdownMenuItem(value: 'izin',  child: Text('📝 Izin')),
                      ],
                      onChanged: absensiId == null ? null : (v) async {
                        await SupabaseService.client.from('absensi_ibadah')
                            .update({'status': v}).eq('id', absensiId);
                        _load();
                      },
                    ),
                  );
                },
              )),
        ]),
      ),
    );
  }
}
