// ═══════════════════════════════════════════════════════════
// kelas_list_page.dart
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:pk_nanda/core/services/supabase_service.dart';
import 'package:pk_nanda/core/services/widgets.dart';
import 'package:pk_nanda/core/theme/app_theme.dart';

class KelasListPage extends StatefulWidget {
  const KelasListPage({super.key});
  @override
  State<KelasListPage> createState() => _KelasListPageState();
}

class _KelasListPageState extends State<KelasListPage> {
  List<Map<String, dynamic>> _semesters = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllSemester();
      if (mounted) setState(() { _semesters = data; _loading = false; });
    } catch (e) { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 28), // RESPONSIVE PADDING
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // RESPONSIVE HEADER: Gunakan Wrap
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16, runSpacing: 12,
            children: [
              Text('Tahun Akademik & Semester', 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isMobile ? 22 : 26,
                )),
              ElevatedButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Semester'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _semesters.isEmpty
              ? EmptyState(icon: Icons.calendar_today_outlined, message: 'Belum ada semester',
                  actionLabel: 'Buat Semester', onAction: () => _showForm(context))
              : ListView.separated(
                  itemCount: _semesters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = _semesters[i];
                    final ta = s['tahun_akademik'] as Map? ?? {};
                    final isActive = s['is_aktif'] == true;
                    return AppCard(
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (isActive ? AppColors.primary : AppColors.textLight).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.calendar_today_rounded,
                            color: isActive ? AppColors.primary : AppColors.textLight, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                            Text('${s['nama']} ${ta['nama']}', style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              const StatusBadge(label: 'AKTIF', color: AppColors.primary),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Text('${s['tanggal_mulai']} s/d ${s['tanggal_selesai']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ])),
                        if (!isActive)
                          ElevatedButton(
                            onPressed: () async {
                              final ok = await showConfirmDialog(context,
                                title: 'Aktifkan Semester',
                                message: 'Set "${s['nama']} ${ta['nama']}" sebagai semester aktif?',
                                confirmLabel: 'Aktifkan',
                                confirmColor: AppColors.primary,
                              );
                              if (ok) {
                                await SupabaseService.setActiveSemester(s['id']);
                                _load();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Aktifkan', style: TextStyle(fontSize: 12)),
                          ),
                      ]),
                    );
                  },
                )),
        ]),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _KelasListFormDialog(
      onSaved: () { Navigator.pop(ctx); _load(); },
    ));
  }
}

class _KelasListFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _KelasListFormDialog({required this.onSaved});
  @override State<_KelasListFormDialog> createState() => _KelasListFormDialogState();
}

class _KelasListFormDialogState extends State<_KelasListFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tahunAkademik = TextEditingController();
  String? _namaSemester;
  DateTime? _mulai, _selesai;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Buat Semester Baru', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(key: _formKey, child: Column(children: [
                TextFormField(
                  controller: _tahunAkademik,
                  decoration: const InputDecoration(labelText: 'Tahun Akademik (contoh: 2024/2025)'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _namaSemester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: const [
                    DropdownMenuItem(value: 'Ganjil', child: Text('Ganjil')),
                    DropdownMenuItem(value: 'Genap', child: Text('Genap')),
                  ],
                  validator: (v) => v == null ? 'Pilih semester' : null,
                  onChanged: (v) => setState(() => _namaSemester = v),
                ),
                const SizedBox(height: 12),
                // RESPONSIVE DATES INPUT
                if (isMobile) ...[
                  _DatePicker(label: 'Tanggal Mulai', value: _mulai, onPick: (d) => setState(() => _mulai = d)),
                  const SizedBox(height: 12),
                  _DatePicker(label: 'Tanggal Selesai', value: _selesai, onPick: (d) => setState(() => _selesai = d)),
                ] else
                  Row(children: [
                    Expanded(child: _DatePicker(label: 'Tanggal Mulai', value: _mulai, onPick: (d) => setState(() => _mulai = d))),
                    const SizedBox(width: 12),
                    Expanded(child: _DatePicker(label: 'Tanggal Selesai', value: _selesai, onPick: (d) => setState(() => _selesai = d))),
                  ]),
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
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    // ... Logika save tidak berubah ...
    if (!_formKey.currentState!.validate() || _mulai == null || _selesai == null) {
      showError(context, 'Lengkapi semua field');
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.createTahunAkademik(_tahunAkademik.text);
      final ta = await SupabaseService.client.from('tahun_akademik')
          .select('id').eq('nama', _tahunAkademik.text).single();
      await SupabaseService.createSemester(
        tahunAkademikId: ta['id'], nama: _namaSemester!,
        tanggalMulai: _mulai!.toIso8601String().split('T').first,
        tanggalSelesai: _selesai!.toIso8601String().split('T').first,
      );
      if (mounted) showSuccess(context, 'Semester berhasil dibuat');
      widget.onSaved();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Error: $e');
    }
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  const _DatePicker({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context, initialDate: DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime(2035),
        );
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(children: [
          const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.textLight),
          const SizedBox(width: 8),
          Expanded(child: Text(
            value == null ? label : '${value!.day}/${value!.month}/${value!.year}',
            style: TextStyle(color: value == null ? AppColors.textLight : AppColors.textDark, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// geofence_page.dart
// ═══════════════════════════════════════════════════════════
class GeofencePage extends StatefulWidget {
  const GeofencePage({super.key});
  @override State<GeofencePage> createState() => _GeofencePageState();
}

class _GeofencePageState extends State<GeofencePage> {
  Map<String, dynamic>? _geofence;
  bool _loading = true;
  bool _saving = false;
  final _lat    = TextEditingController();
  final _lng    = TextEditingController();
  final _radius = TextEditingController();
  final _nama   = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getActiveGeofence();
      if (data != null) {
        _lat.text    = data['latitude'].toString();
        _lng.text    = data['longitude'].toString();
        _radius.text = data['radius_meter'].toString();
        _nama.text   = data['nama'] ?? '';
      }
      if (mounted) setState(() { _geofence = data; _loading = false; });
    } catch (e) { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700; // Threshold untuk Geofence

    // Konten Info Panel
    final infoPanel = Column(children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Info Geofence Aktif', style: TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 16),
          if (_geofence == null)
            const Text('Belum ada geofence yang dikonfigurasi.',
              style: TextStyle(color: AppColors.textLight))
          else ...[
            _InfoRow(label: 'Nama', value: _geofence!['nama']),
            _InfoRow(label: 'Latitude', value: _geofence!['latitude'].toString()),
            _InfoRow(label: 'Longitude', value: _geofence!['longitude'].toString()),
            _InfoRow(label: 'Radius', value: '${_geofence!['radius_meter']} meter'),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cara Mendapatkan Koordinat', style: TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 12),
          const Text(
            '1. Buka Google Maps di browser\n'
            '2. Klik kanan pada lokasi pesantren\n'
            '3. Koordinat akan muncul di menu konteks\n'
            '4. Copy format: latitude, longitude',
            style: TextStyle(fontSize: 12, color: AppColors.textMid, height: 1.7),
          ),
        ]),
      ),
    ]);

    // Konten Form Panel
    final formPanel = AppCard(
      child: Form(key: _formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Konfigurasi Lokasi', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nama,
            decoration: const InputDecoration(labelText: 'Nama Lokasi'),
          ),
          const SizedBox(height: 12),
          // RESPONSIVE LAT / LNG INPUT
          if (isMobile) ...[
            TextFormField(
              controller: _lat, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Latitude', hintText: 'contoh: -5.147665'),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lng, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Longitude', hintText: 'contoh: 119.432732'),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
          ] else 
            Row(children: [
              Expanded(child: TextFormField(
                controller: _lat, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude', hintText: 'contoh: -5.147665'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(
                controller: _lng, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude', hintText: 'contoh: 119.432732'),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              )),
            ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _radius, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Radius (meter)', hintText: 'contoh: 100', suffixText: 'meter'),
            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_geofence == null ? 'Simpan Geofence' : 'Update Geofence'),
            ),
          ),
        ],
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pengaturan Geofence', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: isMobile ? 22 : 26,
            )),
            const SizedBox(height: 6),
            const Text('Atur titik koordinat dan radius absensi pesantren.',
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
            const SizedBox(height: 24),

            // RESPONSIVE LAYOUT FORM & INFO
            if (isMobile) ...[
              formPanel,
              const SizedBox(height: 24),
              infoPanel,
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: formPanel),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: infoPanel),
              ]),
          ]),
        ),
    );
  }

  Future<void> _save() async {
    // ... Logika save tidak berubah ...
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final lat = double.parse(_lat.text);
      final lng = double.parse(_lng.text);
      final radius = int.parse(_radius.text);
      if (_geofence != null) {
        await SupabaseService.updateGeofence(
          id: _geofence!['id'], lat: lat, lng: lng, radius: radius,
        );
      } else {
        await SupabaseService.createGeofence(
          nama: _nama.text.isEmpty ? 'Pesantren' : _nama.text,
          lat: lat, lng: lng, radius: radius,
        );
      }
      if (mounted) showSuccess(context, 'Geofence berhasil disimpan');
      _load();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, 'Error: $e');
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// pengumuman_page.dart
// ═══════════════════════════════════════════════════════════
class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});
  @override State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> {
  List<Map<String, dynamic>> _pengumuman = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllPengumuman();
      if (mounted) setState(() { _pengumuman = data; _loading = false; });
    } catch (e) { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  static const _targetColors = {
    'all': AppColors.primary,
    'role': Color(0xFF2E6B8A),
    'kelompok_pembina': Color(0xFF8A5E2E),
  };

  @override
  Widget build(BuildContext context) {
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
              Text('Pengumuman', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: isMobile ? 22 : 26,
              )),
              ElevatedButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.campaign_rounded, size: 18),
                label: const Text('Buat Pengumuman'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _pengumuman.isEmpty
              ? EmptyState(icon: Icons.campaign_outlined, message: 'Belum ada pengumuman',
                  actionLabel: 'Buat Pengumuman', onAction: () => _showForm(context))
              : ListView.separated(
                  itemCount: _pengumuman.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = _pengumuman[i];
                    final target = p['target'] ?? 'all';
                    final color = _targetColors[target] ?? AppColors.primary;
                    final dibuat = p['dibuat_oleh_profile'] as Map? ?? {};
                    return AppCard(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.campaign_rounded, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
                            Text(p['judul'] ?? '-', style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                            StatusBadge(
                              label: target == 'all' ? 'SEMUA' : target.toUpperCase(),
                              color: color,
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(p['isi'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: AppColors.textMid)),
                          const SizedBox(height: 6),
                          Text('oleh ${dibuat['nama_lengkap'] ?? '-'} • ${p['created_at'].toString().substring(0,10)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                        ])),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          color: AppColors.error,
                          onPressed: () async {
                            final ok = await showConfirmDialog(context,
                              title: 'Hapus Pengumuman', message: 'Hapus pengumuman ini?');
                            if (ok) {
                              await SupabaseService.deletePengumuman(p['id']);
                              _load();
                            }
                          },
                        ),
                      ]),
                    );
                  },
                )),
        ]),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _PengumumanFormDialog(
      onSaved: () { Navigator.pop(ctx); _load(); },
    ));
  }
}

class _PengumumanFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _PengumumanFormDialog({required this.onSaved});
  @override State<_PengumumanFormDialog> createState() => _PengumumanFormDialogState();
}

class _PengumumanFormDialogState extends State<_PengumumanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _judul = TextEditingController();
  final _isi   = TextEditingController();
  String _target = 'all';
  String? _targetRole;
  bool _isPush = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.campaign_rounded, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Buat Pengumuman', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(key: _formKey, child: Column(children: [
                TextFormField(
                  controller: _judul,
                  decoration: const InputDecoration(labelText: 'Judul Pengumuman'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _isi,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Isi Pengumuman', alignLabelWithHint: true),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                // RESPONSIVE ROLE TARGET DROPDOWNS
                if (isMobile) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _target,
                    decoration: const InputDecoration(labelText: 'Target Penerima'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Semua User')),
                      DropdownMenuItem(value: 'role', child: Text('Per Role')),
                    ],
                    onChanged: (v) => setState(() { _target = v!; _targetRole = null; }),
                  ),
                  if (_target == 'role') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _targetRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'santri', child: Text('Santri')),
                        DropdownMenuItem(value: 'dosen', child: Text('Dosen')),
                        DropdownMenuItem(value: 'pembina', child: Text('Pembina')),
                      ],
                      onChanged: (v) => setState(() => _targetRole = v),
                    ),
                  ],
                ] else
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      initialValue: _target,
                      decoration: const InputDecoration(labelText: 'Target Penerima'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Semua User')),
                        DropdownMenuItem(value: 'role', child: Text('Per Role')),
                      ],
                      onChanged: (v) => setState(() { _target = v!; _targetRole = null; }),
                    )),
                    if (_target == 'role') ...[
                      const SizedBox(width: 12),
                      Expanded(child: DropdownButtonFormField<String>(
                        initialValue: _targetRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'santri', child: Text('Santri')),
                          DropdownMenuItem(value: 'dosen', child: Text('Dosen')),
                          DropdownMenuItem(value: 'pembina', child: Text('Pembina')),
                        ],
                        onChanged: (v) => setState(() => _targetRole = v),
                      )),
                    ],
                  ]),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isPush,
                  onChanged: (v) => setState(() => _isPush = v),
                  title: const Text('Kirim Push Notification', style: TextStyle(
                    fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500)),
                  activeThumbColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ])),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textMid))),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    // ... Logika save tidak berubah ...
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.createPengumuman(
        judul: _judul.text, isi: _isi.text,
        target: _target, targetRole: _targetRole, isPush: _isPush,
      );
      if (mounted) showSuccess(context, 'Pengumuman berhasil dikirim');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showError(context, 'Error: $e');
      }
    }
  }
}


// ═══════════════════════════════════════════════════════════
// kelompok_page.dart
// ═══════════════════════════════════════════════════════════
class KelompokPage extends StatefulWidget {
  const KelompokPage({super.key});
  @override State<KelompokPage> createState() => _KelompokPageState();
}

class _KelompokPageState extends State<KelompokPage> {
  List<Map<String, dynamic>> _kelompok = [];
  Map<String, dynamic>? _activeSemester;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sem = await SupabaseService.getActiveSemester();
      if (sem == null) { 
        if (mounted) setState(() => _loading = false); 
        return; 
      }
      final data = await SupabaseService.getKelompokPembina(sem['id']);
      if (mounted) setState(() { _activeSemester = sem; _kelompok = data; _loading = false; });
    } catch (e) { 
      if (mounted) setState(() => _loading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // RESPONSIVE GRID
    final int crossAxisCount = isMobile ? 1 : (screenWidth < 900 ? 2 : 3);
    final double childAspectRatio = isMobile ? 2.5 : 1.8;

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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kelompok Pembina', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: isMobile ? 22 : 26,
                )),
                const Text('Relasi 1 Pembina : 10 Santri',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              ]),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A5E2E)),
                onPressed: _activeSemester == null ? null : () => _showForm(context),
                icon: const Icon(Icons.group_add_rounded, size: 18),
                label: const Text('Buat Kelompok'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _kelompok.isEmpty
              ? const EmptyState(icon: Icons.group_work_outlined, message: 'Belum ada kelompok pembina')
              : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount, crossAxisSpacing: 16,
                    mainAxisSpacing: 16, childAspectRatio: childAspectRatio,
                  ),
                  itemCount: _kelompok.length,
                  itemBuilder: (_, i) => _KelompokCard(
                    kelompok: _kelompok[i],
                    onManage: () => _showManage(context, _kelompok[i]),
                  ),
                )),
        ]),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _KelompokFormDialog(
      semesterId: _activeSemester!['id'],
      onSaved: () { Navigator.pop(ctx); _load(); },
    ));
  }

  void _showManage(BuildContext context, Map<String, dynamic> kelompok) {
    showDialog(context: context, builder: (ctx) => _ManageKelompokDialog(
      kelompok: kelompok, onSaved: () { _load(); },
    ));
  }
}

class _KelompokCard extends StatelessWidget {
  final Map<String, dynamic> kelompok;
  final VoidCallback onManage;
  const _KelompokCard({required this.kelompok, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final pembina = kelompok['pembina'] as Map? ?? {};
    final pembinaProfile = pembina['profile'] as Map? ?? {};
    final santriList = kelompok['kelompok_santri'] as List? ?? [];
    final count = santriList.length;
    final pct = count / 10.0;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(kelompok['nama_kelompok'] ?? 'Kelompok', style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          StatusBadge(label: '$count/10', color: count >= 10 ? AppColors.primary : Colors.orange),
        ]),
        const SizedBox(height: 4),
        Text('Pembina: ${pembinaProfile['nama_lengkap'] ?? '-'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.accent.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(pct >= 1 ? AppColors.primary : Colors.orange),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Wrap(
            spacing: 4, runSpacing: 4,
            children: santriList.take(5).map<Widget>((ks) {
              final s = ks['santri'] as Map? ?? {};
              final p = s['profile'] as Map? ?? {};
              final nama = p['nama_lengkap'] ?? '-';
              return CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.accent.withOpacity(0.3),
                child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w700)),
              );
            }).toList(),
          )),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Kelola', style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
        ]),
      ]),
    );
  }
}

class _KelompokFormDialog extends StatefulWidget {
  final String semesterId;
  final VoidCallback onSaved;
  const _KelompokFormDialog({required this.semesterId, required this.onSaved});
  @override State<_KelompokFormDialog> createState() => _KelompokFormDialogState();
}

class _KelompokFormDialogState extends State<_KelompokFormDialog> {
  // ... State tidak berubah ...
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  String? _pembinaId;
  List<Map<String, dynamic>> _pembinas = [];
  bool _loading = false, _loadingData = true;

  @override
  void initState() {
    super.initState();
    SupabaseService.getAllPembina().then((data) {
      if (mounted) setState(() { _pembinas = data; _loadingData = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF8A5E2E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.group_add_rounded, color: Colors.white),
                const SizedBox(width: 10),
                const Text('Buat Kelompok', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _loadingData
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : Form(key: _formKey, child: Column(children: [
                    TextFormField(
                      controller: _nama,
                      decoration: const InputDecoration(labelText: 'Nama Kelompok'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _pembinaId,
                      decoration: const InputDecoration(labelText: 'Pilih Pembina'),
                      items: _pembinas.map((p) {
                        final profile = p['profile'] as Map? ?? {};
                        return DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text(profile['nama_lengkap'] ?? p['kode_pembina']),
                        );
                      }).toList(),
                      validator: (v) => v == null ? 'Pilih pembina' : null,
                      onChanged: (v) => setState(() => _pembinaId = v),
                    ),
                  ])),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textMid))),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A5E2E)),
                  onPressed: _loading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _loading = true);
                    try {
                      await SupabaseService.createKelompok(
                        pembinaId: _pembinaId!, semesterId: widget.semesterId,
                        namaKelompok: _nama.text,
                      );
                      if (mounted) showSuccess(context, 'Kelompok berhasil dibuat');
                      widget.onSaved();
                    } catch (e) {
                      if (mounted) {
                        setState(() => _loading = false);
                        showError(context, 'Error: $e');
                      }
                    }
                  },
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Buat'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ManageKelompokDialog extends StatefulWidget {
  final Map<String, dynamic> kelompok;
  final VoidCallback onSaved;
  const _ManageKelompokDialog({required this.kelompok, required this.onSaved});
  @override State<_ManageKelompokDialog> createState() => _ManageKelompokDialogState();
}

class _ManageKelompokDialogState extends State<_ManageKelompokDialog> {
  List<Map<String, dynamic>> _inKelompok = [];
  List<Map<String, dynamic>> _allSantri = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final kps = widget.kelompok['kelompok_santri'] as List? ?? [];
    final allSantri = await SupabaseService.getAllSantri();
    if (mounted) setState(() {
      _inKelompok = kps.cast<Map<String, dynamic>>();
      _allSantri = allSantri;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _notInKelompok {
    final inIds = _inKelompok.map((k) => k['santri']?['id']).toSet();
    return _allSantri.where((s) => !inIds.contains(s['id'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // List Dalam Kelompok
    final listDalamKelompok = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Dalam Kelompok (${_inKelompok.length})', style: const TextStyle(
        fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(
        itemCount: _inKelompok.length,
        itemBuilder: (_, i) {
          final s = _inKelompok[i]['santri'] as Map? ?? {};
          final p = s['profile'] as Map? ?? {};
          return ListTile(
            dense: true,
            leading: const Icon(Icons.person_rounded, color: Color(0xFF8A5E2E), size: 18),
            title: Text(p['nama_lengkap'] ?? '-', style: const TextStyle(fontSize: 13)),
            subtitle: Text(s['nim'] ?? '-', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
              onPressed: () async {
                await SupabaseService.removeSantriFromKelompok(_inKelompok[i]['id']);
                widget.onSaved();
                _load();
              },
            ),
          );
        },
      )),
    ]);

    // List Belum Masuk
    final listBelumMasuk = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Belum Masuk (${_notInKelompok.length})', style: const TextStyle(
        fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(
        itemCount: _notInKelompok.length,
        itemBuilder: (_, i) {
          final s = _notInKelompok[i];
          final p = s['profile'] as Map? ?? {};
          return ListTile(
            dense: true,
            enabled: _inKelompok.length < 10,
            leading: const Icon(Icons.person_outline, color: AppColors.textLight, size: 18),
            title: Text(p['nama_lengkap'] ?? '-', style: const TextStyle(fontSize: 13)),
            subtitle: Text(s['nim'] ?? '-', style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8A5E2E), size: 18),
              onPressed: _inKelompok.length >= 10 ? null : () async {
                await SupabaseService.addSantriToKelompok(
                  widget.kelompok['id'], s['id']);
                widget.onSaved();
                _load();
              },
            ),
          );
        },
      )),
    ]);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600, 
          maxHeight: MediaQuery.of(context).size.height * 0.85 // Hindari tumpuk di layar pendek
        ), 
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF8A5E2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              const Icon(Icons.group_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('${widget.kelompok['nama_kelompok']} (${_inKelompok.length}/10)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white)),
            ]),
          ),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Padding(
                padding: const EdgeInsets.all(20),
                // RESPONSIVE TWO-LIST LAYOUT
                child: isMobile 
                  ? Column(children: [
                      Expanded(child: listDalamKelompok),
                      const Divider(color: AppColors.divider, height: 32),
                      Expanded(child: listBelumMasuk),
                    ])
                  : Row(children: [
                      Expanded(child: listDalamKelompok),
                      const VerticalDivider(color: AppColors.divider, width: 32),
                      Expanded(child: listBelumMasuk),
                    ]),
              )),
        ]),
      ),
    );
  }
}