import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_service_extended.dart';
import '../../../core/services/widgets.dart';

class DosenAbsensiPage extends StatefulWidget {
  final String dosenId;
  const DosenAbsensiPage({super.key, required this.dosenId});
  @override
  State<DosenAbsensiPage> createState() => _DosenAbsensiPageState();
}

class _DosenAbsensiPageState extends State<DosenAbsensiPage> {
  List<Map<String, dynamic>> _sesi = [];
  bool _loading = true;
  String? _selectedSesiId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DosenService.getSesiByDosen(widget.dosenId);
    setState(() { _sesi = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSesiId != null) {
      return _AbsensiDetailPage(
        sesiId: _selectedSesiId!,
        onBack: () { setState(() => _selectedSesiId = null); _load(); });
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // RESPONSIVE HEADER
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16, runSpacing: 12,
            children: [
              Text('Absensi Akademik', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: isMobile ? 22 : 26
              )),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6B8A)),
                onPressed: () => _showBukaSesi(context),
                icon: const Icon(Icons.play_circle_rounded, size: 18),
                label: const Text('Buka Sesi')),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E6B8A)))
            : _sesi.isEmpty
                ? EmptyState(icon: Icons.fact_check_outlined, message: 'Belum ada sesi',
                    actionLabel: 'Buka Sesi', onAction: () => _showBukaSesi(context))
                : ListView.separated(
                    itemCount: _sesi.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SesiCard(
                      sesi: _sesi[i],
                      onTap: () => setState(() => _selectedSesiId = _sesi[i]['id']),
                      onTutup: () async {
                        await DosenService.tutupSesiAbsensiAkademik(_sesi[i]['id']);
                        _load();
                      }))),
        ]),
      ),
    );
  }

  void _showBukaSesi(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dlg) => _BukaSesiDialog(
        dosenId: widget.dosenId,
        onBuka: (kelasId, durasi, kode, geofenceId) async {
          Navigator.pop(dlg);
          try {
            await DosenService.bukaSesiAbsensiAkademik(
              kelasId: kelasId, geofenceId: geofenceId,
              kodeAbsen: kode, durasiMenit: durasi);
            if (ctx.mounted) showSuccess(ctx, 'Sesi dibuka! Kode: $kode');
            _load();
          } catch (e) {
            if (ctx.mounted) showError(ctx, 'Error: $e');
          }
        }),
    );
  }
}

class _SesiCard extends StatelessWidget {
  final Map<String, dynamic> sesi;
  final VoidCallback onTap;
  final VoidCallback onTutup;
  const _SesiCard({required this.sesi, required this.onTap, required this.onTutup});

  @override
  Widget build(BuildContext context) {
    final kelas  = sesi['kelas'] as Map? ?? {};
    final mk     = kelas['mata_kuliah'] as Map? ?? {};
    final isOpen = sesi['jam_tutup'] == null;

    return AppCard(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (isOpen ? AppColors.primary : AppColors.textLight).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.fact_check_rounded,
            color: isOpen ? AppColors.primary : AppColors.textLight, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${mk['nama']} — Kelas ${kelas['nama_kelas']}', style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
          Text('${sesi['tanggal']} • ${sesi['jam_buka']?.toString().substring(11, 16)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        ])),
        if (sesi['kode_absen'] != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider)),
            child: Text(sesi['kode_absen'], style: const TextStyle(
              fontFamily: 'monospace', fontWeight: FontWeight.w700,
              color: AppColors.primary, fontSize: 12, letterSpacing: 1))),
          const SizedBox(width: 8),
        ],
        StatusBadge(
          label: isOpen ? 'BUKA' : 'TUTUP',
          color: isOpen ? AppColors.primary : AppColors.textLight),
        if (isOpen) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.stop_circle_rounded, color: AppColors.error, size: 20),
            tooltip: 'Tutup Sesi',
            onPressed: onTutup),
        ],
      ]),
    );
  }
}

class _BukaSesiDialog extends StatefulWidget {
  final String dosenId;
  final Function(String, int, String, String) onBuka;
  const _BukaSesiDialog({required this.dosenId, required this.onBuka});
  @override State<_BukaSesiDialog> createState() => _BukaSesiDialogState();
}

class _BukaSesiDialogState extends State<_BukaSesiDialog> {
  String? _kelasId, _geofenceId;
  int _durasi = 30;
  List<Map<String, dynamic>> _kelas = [], _geofences = [];

  @override
  void initState() {
    super.initState();
    SupabaseService.client
        .from('kelas')
        .select('id, nama_kelas, mata_kuliah:mata_kuliah_id(nama)')
        .eq('dosen_id', widget.dosenId)
        .then((d) => setState(() => _kelas = d));
    SupabaseService.client
        .from('geofence_setting').select().eq('is_aktif', true)
        .then((d) => setState(() {
          _geofences = d;
          _geofenceId = d.isNotEmpty ? d.first['id'] : null;
        }));
  }

  String _generateKode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (i) =>
      chars[(DateTime.now().microsecondsSinceEpoch + i * 7) % chars.length]).join();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420), // MENCEGAH OVERFLOW
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E6B8A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(children: [
                const Icon(Icons.play_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Buka Sesi Absensi', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: _kelasId,
                  decoration: const InputDecoration(labelText: 'Pilih Kelas'),
                  items: _kelas.map((k) {
                    final mk = k['mata_kuliah'] as Map? ?? {};
                    return DropdownMenuItem(
                      value: k['id'].toString(),
                      child: Text('${mk['nama']} — Kelas ${k['nama_kelas']}'));
                  }).toList(),
                  onChanged: (v) => setState(() => _kelasId = v)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _geofenceId,
                  decoration: const InputDecoration(labelText: 'Geofence Lokasi'),
                  items: _geofences.map((g) => DropdownMenuItem(
                    value: g['id'].toString(), child: Text(g['nama'] ?? '-'))).toList(),
                  onChanged: (v) => setState(() => _geofenceId = v)),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Durasi:', style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                  Expanded(
                    child: Slider(
                      value: _durasi.toDouble(), min: 5, max: 120, divisions: 23,
                      activeColor: const Color(0xFF2E6B8A),
                      label: '$_durasi menit',
                      onChanged: (v) => setState(() => _durasi = v.round()))),
                  Text('$_durasi mnt', style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.textDark)),
                ]),
              ]),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, isMobile ? 16 : 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textMid))),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6B8A)),
                  onPressed: _kelasId == null || _geofenceId == null ? null
                    : () => widget.onBuka(_kelasId!, _durasi, _generateKode(), _geofenceId!),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Buka Sekarang')),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Halaman Detail Absensi per Sesi ──────────────────────
class _AbsensiDetailPage extends StatefulWidget {
  final String sesiId;
  final VoidCallback onBack;
  const _AbsensiDetailPage({required this.sesiId, required this.onBack});
  @override State<_AbsensiDetailPage> createState() => _AbsensiDetailPageState();
}

class _AbsensiDetailPageState extends State<_AbsensiDetailPage> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DosenService.getAbsensiDetailBySesi(widget.sesiId);
    setState(() { _list = data; _loading = false; });
  }

  Map<String, int> get _summary {
    final m = {'hadir': 0, 'izin': 0, 'sakit': 0, 'terlambat': 0, 'alpha': 0};
    for (final a in _list) {
      m[a['status']] = (m[a['status']] ?? 0) + 1;
    }
    return m;
  }

  static const _statusColors = {
    'hadir'    : AppColors.primary,
    'izin'     : Colors.blue,
    'sakit'    : Colors.orange,
    'terlambat': Colors.amber,
    'alpha'    : AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final sum = _summary;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header responsif
        Row(children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary)),
          const SizedBox(width: 4),
          Expanded(child: Text('Detail Absensi',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: isMobile ? 18 : 24),
            overflow: TextOverflow.ellipsis)),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded,
              color: Color(0xFF2E6B8A), size: 22),
            tooltip: 'Refresh'),
        ]),
        const SizedBox(height: 14),
        // Summary chips
        Wrap(spacing: 8, runSpacing: 8,
          children: sum.entries.map((e) => _SummaryChip(
            label: e.key, count: e.value,
            color: _statusColors[e.key] ?? AppColors.textMid)).toList()),
        const SizedBox(height: 14),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E6B8A)))
            : AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  itemCount: _list.length,
                  separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final a = _list[i];
                    final s = a['santri'] as Map? ?? {};
                    final p = s['profile'] as Map? ?? {};
                    final status = a['status'] as String;
                    final c = _statusColors[status] ?? AppColors.textMid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      child: Row(children: [
                        AvatarBadge(
                          name: p['nama_lengkap'] ?? '-',
                          subtitle: s['nim'] ?? '-',
                          color: const Color(0xFF2E6B8A)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.withOpacity(0.3))),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              isDense: true,
                              style: TextStyle(color: c,
                                fontWeight: FontWeight.w700, fontSize: 12),
                              items: _statusColors.keys.map((o) =>
                                DropdownMenuItem(value: o,
                                  child: Text(o.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColors[o] ?? AppColors.textMid,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)))).toList(),
                              onChanged: (v) async {
                                await DosenService.editStatusAbsensiAkademik(
                                  a['id'], v!, null);
                                _load();
                              }))),
                      ]),
                    );
                  },
                )),
        ),
      ]),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Text('${label[0].toUpperCase()}${label.substring(1)}: $count',
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)));
}
