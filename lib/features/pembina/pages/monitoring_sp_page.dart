import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

// ════════════════════════════════════════════════════════════
//  MONITORING REALTIME
// ════════════════════════════════════════════════════════════
class MonitoringPage extends StatefulWidget {
  final String? kelompokId;
  final List<Map<String, dynamic>> santriList;

  const MonitoringPage({
    super.key,
    required this.kelompokId,
    required this.santriList,
  });

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  Map<String, String> _statusMap = {};
  List<Map<String, dynamic>> _sesiAktif = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (widget.kelompokId == null) { setState(() => _loading = false); return; }
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final sesi  = await SupabaseService.client
          .from('sesi_absensi_ibadah')
          .select('id, jadwal_sholat_id, jam_tutup, jadwal_sholat:jadwal_sholat_id(nama_sholat)')
          .eq('kelompok_pembina_id', widget.kelompokId!)
          .eq('tanggal', today);

      Map<String, String> sm = {};
      for (final s in sesi) {
        final ab = await SupabaseService.client
            .from('absensi_ibadah')
            .select('santri_id, status')
            .eq('sesi_id', s['id']);
        for (final a in ab) {
          sm['${a['santri_id']}_${s['jadwal_sholat_id']}'] = a['status'];
        }
      }
      setState(() { _sesiAktif = sesi; _statusMap = sm; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Monitoring Real-time',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Text('Pantau kehadiran sholat santri binaan Anda.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            ]),
            ElevatedButton.icon(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A5E2E)),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh')),
          ]),
          const SizedBox(height: 16),
          // Legenda
          Wrap(spacing: 16, children: const [
            _Legend(color: AppColors.primary, label: 'Hadir'),
            _Legend(color: AppColors.error,   label: 'Alpha'),
            _Legend(color: Colors.orange,     label: 'Izin'),
            _Legend(color: AppColors.divider, label: 'Belum Sesi'),
          ]),
          const SizedBox(height: 16),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _sesiAktif.isEmpty
                ? const EmptyState(icon: Icons.monitor_heart_outlined,
                    message: 'Belum ada sesi aktif hari ini.')
                : AppCard(
                    padding: EdgeInsets.zero,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                            AppColors.accent.withOpacity(0.2)),
                        columns: [
                          const DataColumn(label: Text('Santri',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                          ..._sesiAktif.map((s) {
                            final nama   = s['jadwal_sholat']?['nama_sholat'] ?? '-';
                            final isOpen = s['jam_tutup'] == null;
                            return DataColumn(label: Column(
                              mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(nama, style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                                StatusBadge(
                                  label: isOpen ? 'BUKA' : 'TUTUP',
                                  color: isOpen ? AppColors.primary : AppColors.textLight),
                              ]));
                          }),
                        ],
                        rows: widget.santriList.map((ks) {
                          final s = ks['santri'] as Map? ?? {};
                          final p = s['profile'] as Map? ?? {};
                          return DataRow(cells: [
                            DataCell(Text(p['nama_lengkap'] ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13))),
                            ..._sesiAktif.map((sesi) {
                              final key    = '${s['id']}_${sesi['jadwal_sholat_id']}';
                              final status = _statusMap[key];
                              Color c; IconData ic;
                              switch (status) {
                                case 'hadir': c = AppColors.primary; ic = Icons.check_circle_rounded; break;
                                case 'izin' : c = Colors.orange; ic = Icons.info_rounded; break;
                                case 'alpha': c = AppColors.error; ic = Icons.cancel_rounded; break;
                                default     : c = AppColors.divider; ic = Icons.remove_circle_outline;
                              }
                              return DataCell(Center(child: Icon(ic, color: c, size: 22)));
                            }),
                          ]);
                        }).toList(),
                      ),
                    ))),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    CircleAvatar(radius: 6, backgroundColor: color),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
  ]);
}


// ════════════════════════════════════════════════════════════
//  SURAT PERINGATAN PAGE
// ════════════════════════════════════════════════════════════
class SPPage extends StatefulWidget {
  final String? pembinaId;
  final List<Map<String, dynamic>> santriList;

  const SPPage({super.key, required this.pembinaId, required this.santriList});

  @override
  State<SPPage> createState() => _SPPageState();
}

class _SPPageState extends State<SPPage> {
  List<Map<String, dynamic>> _spList = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (widget.pembinaId == null) { setState(() => _loading = false); return; }
    try {
      final data = await SupabaseService.client.from('surat_peringatan').select('''
        id, level, alasan, hukuman, tanggal_sp, status,
        santri:santri_id(id, nim, profile:profile_id(nama_lengkap))
      ''')
      .eq('pembina_id', widget.pembinaId!)
      .order('created_at', ascending: false);
      setState(() { _spList = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Surat Peringatan', style: Theme.of(context).textTheme.headlineMedium),
            ElevatedButton.icon(
              onPressed: () => _showForm(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Beri SP')),
          ]),
          const SizedBox(height: 20),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _spList.isEmpty
                ? const EmptyState(icon: Icons.check_circle_outline,
                    message: 'Belum ada SP yang dikeluarkan.')
                : ListView.separated(
                    itemCount: _spList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SPCard(sp: _spList[i]))),
        ]),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(context: context,
      builder: (ctx) => _SPFormDialog(
        santriList: widget.santriList, pembinaId: widget.pembinaId,
        onSaved: () { Navigator.pop(ctx); _load(); }));
  }
}

class _SPCard extends StatelessWidget {
  final Map<String, dynamic> sp;
  const _SPCard({required this.sp});

  @override
  Widget build(BuildContext context) {
    final level = sp['level'] ?? 'SP1';
    final s = sp['santri'] as Map? ?? {};
    final p = s['profile'] as Map? ?? {};
    final color = level == 'SP3' ? AppColors.error
        : level == 'SP2' ? Colors.orange
        : Colors.amber.shade700;

    return AppCard(
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(level, style: TextStyle(
            color: color, fontWeight: FontWeight.w900, fontSize: 15))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['nama_lengkap'] ?? '-', style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
          Text('NIM: ${s['nim'] ?? '-'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text(sp['alasan'] ?? '-',
            style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
          if (sp['hukuman'] != null)
            Text('Hukuman: ${sp['hukuman']}',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusBadge(
            label: (sp['status'] ?? '-').toUpperCase(),
            color: sp['status'] == 'aktif' ? color : AppColors.textLight),
          const SizedBox(height: 4),
          Text(sp['tanggal_sp'] ?? '-',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        ]),
      ]),
    );
  }
}

class _SPFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> santriList;
  final String? pembinaId;
  final VoidCallback onSaved;
  const _SPFormDialog(
      {required this.santriList, required this.pembinaId, required this.onSaved});
  @override State<_SPFormDialog> createState() => _SPFormDialogState();
}

class _SPFormDialogState extends State<_SPFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _alasan  = TextEditingController();
  final _hukuman = TextEditingController();
  String? _santriId;
  String _level = 'SP1';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            const Text('Beri Surat Peringatan', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Form(key: _formKey, child: Column(children: [
            DropdownButtonFormField<String>(
              initialValue: _santriId,
              decoration: const InputDecoration(labelText: 'Pilih Santri'),
              items: widget.santriList.map((ks) {
                final s = ks['santri'] as Map? ?? {};
                final p = s['profile'] as Map? ?? {};
                return DropdownMenuItem(
                  value: s['id']?.toString(), child: Text(p['nama_lengkap'] ?? '-'));
              }).toList(),
              validator: (v) => v == null ? 'Pilih santri' : null,
              onChanged: (v) => setState(() => _santriId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level SP'),
              items: const [
                DropdownMenuItem(value: 'SP1', child: Text('SP 1 — Peringatan')),
                DropdownMenuItem(value: 'SP2', child: Text('SP 2 — Keras')),
                DropdownMenuItem(value: 'SP3', child: Text('SP 3 — Terakhir')),
              ],
              onChanged: (v) => setState(() => _level = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _alasan, maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan / Pelanggaran', alignLabelWithHint: true),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _hukuman,
              decoration: const InputDecoration(labelText: 'Hukuman (opsional)')),
          ])),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: AppColors.textMid))),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Keluarkan SP')),
          ]),
        ),
      ])),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final sem = await SupabaseService.getActiveSemester();
      await SupabaseService.client.from('surat_peringatan').insert({
        'santri_id'  : _santriId,
        'pembina_id' : widget.pembinaId,
        'semester_id': sem?['id'],
        'level'      : _level,
        'alasan'     : _alasan.text,
        'hukuman'    : _hukuman.text.isEmpty ? null : _hukuman.text,
        'tanggal_sp' : DateTime.now().toIso8601String().split('T').first,
      });
      if (mounted) showSuccess(context, 'SP berhasil dikeluarkan');
      widget.onSaved();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Error: $e');
    }
  }
}
