import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class KelasListPage extends StatefulWidget {
  const KelasListPage({super.key});
  @override
  State<KelasListPage> createState() => _KelasListPageState();
}

class _KelasListPageState extends State<KelasListPage> {
  List<Map<String, dynamic>> _kelas = [];
  Map<String, dynamic>? _activeSemester;
  bool _loading = true;
  String? _filterHari;

  static const _hariList = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sem = await SupabaseService.getActiveSemester();
      if (sem == null) { setState(() => _loading = false); return; }
      final data = await SupabaseService.getAllKelas(sem['id']);
      setState(() { _activeSemester = sem; _kelas = data; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered => _filterHari == null
      ? _kelas
      : _kelas.where((k) => k['hari'] == _filterHari).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Manajemen Kelas', style: Theme.of(context).textTheme.headlineMedium),
              Text(_activeSemester != null
                ? 'Semester ${_activeSemester!['nama']} • ${_activeSemester!['tahun_akademik']?['nama']}'
                : 'Tidak ada semester aktif',
                style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
            ]),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5E2E8A)),
              onPressed: _activeSemester == null ? null : () => _showForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Kelas'),
            ),
          ]),
          const SizedBox(height: 20),

          // Filter hari
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _HariChip(label: 'Semua', selected: _filterHari == null,
                onTap: () => setState(() => _filterHari = null)),
              ..._hariList.map((h) => _HariChip(label: h,
                selected: _filterHari == h,
                onTap: () => setState(() => _filterHari = h))),
            ]),
          ),
          const SizedBox(height: 16),

          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _filtered.isEmpty
              ? const EmptyState(icon: Icons.class_outlined, message: 'Belum ada kelas')
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 16,
                    mainAxisSpacing: 16, childAspectRatio: 1.6,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _KelasCard(
                    kelas: _filtered[i],
                    onManageSantri: () => _showManageSantri(context, _filtered[i]),
                  ),
                )),
        ]),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _KelasFormDialog(
      semesterId: _activeSemester!['id'],
      onSaved: () { Navigator.pop(ctx); _load(); },
    ));
  }

  void _showManageSantri(BuildContext context, Map<String, dynamic> kelas) {
    showDialog(context: context, builder: (ctx) => _ManageSantriKelasDialog(kelas: kelas));
  }
}

class _HariChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _HariChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppColors.textMid,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        )),
      ),
    );
  }
}

class _KelasCard extends StatelessWidget {
  final Map<String, dynamic> kelas;
  final VoidCallback onManageSantri;
  const _KelasCard({required this.kelas, required this.onManageSantri});

  static const _hariColor = {
    'Senin': Color(0xFF346739), 'Selasa': Color(0xFF2E6B8A),
    'Rabu': Color(0xFF8A5E2E), 'Kamis': Color(0xFF5E2E8A),
    'Jumat': Color(0xFF8A2E6B), 'Sabtu': Color(0xFF2E8A5E),
  };

  @override
  Widget build(BuildContext context) {
    final mk = kelas['mata_kuliah'] as Map? ?? {};
    final dosen = kelas['dosen'] as Map? ?? {};
    final dosenProfile = dosen['profile'] as Map? ?? {};
    final hari = kelas['hari'] ?? '';
    final color = _hariColor[hari] ?? AppColors.primary;
    final santriCount = (kelas['kelas_santri'] as List?)?.length ?? 0;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatusBadge(label: 'Kelas ${kelas['nama_kelas']}', color: color),
          StatusBadge(label: hari, color: color),
        ]),
        const SizedBox(height: 10),
        Text(mk['nama'] ?? '-', style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark),
          maxLines: 2, overflow: TextOverflow.ellipsis),
        Text('${mk['kode'] ?? ''} • ${mk['sks'] ?? 0} SKS',
          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        const Spacer(),
        const Divider(color: AppColors.divider, height: 16),
        Row(children: [
          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text('${kelas['jam_mulai']?.toString().substring(0,5)} — ${kelas['jam_selesai']?.toString().substring(0,5)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
          const SizedBox(width: 12),
          const Icon(Icons.room_rounded, size: 14, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(kelas['ruangan'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text(dosenProfile['nama_lengkap'] ?? '-',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              overflow: TextOverflow.ellipsis),
          ]),
          GestureDetector(
            onTap: onManageSantri,
            child: Row(children: [
              const Icon(Icons.group_rounded, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('$santriCount santri', style: const TextStyle(
                fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _KelasFormDialog extends StatefulWidget {
  final String semesterId;
  final VoidCallback onSaved;
  const _KelasFormDialog({required this.semesterId, required this.onSaved});
  @override State<_KelasFormDialog> createState() => _KelasFormDialogState();
}

class _KelasFormDialogState extends State<_KelasFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ruangan = TextEditingController();
  String? _mkId, _dosenId, _namaKelas, _hari;
  TimeOfDay _jamMulai = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay _jamSelesai = const TimeOfDay(hour: 10, minute: 0);
  List<Map<String, dynamic>> _matkuls = [];
  List<Map<String, dynamic>> _dosens = [];
  bool _loading = false;
  bool _loadingData = true;

  static const _kelasOpts = ['A','B','C','D','E'];
  static const _hariOpts = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final results = await Future.wait([
      SupabaseService.getAllMataKuliah(),
      SupabaseService.getAllDosen(),
    ]);
    setState(() {
      _matkuls = results[0] as List<Map<String, dynamic>>;
      _dosens  = results[1] as List<Map<String, dynamic>>;
      _loadingData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(width: 520, child: _loadingData
        ? const Padding(padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        : Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF5E2E8A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              const Icon(Icons.class_rounded, color: Colors.white),
              const SizedBox(width: 10),
              const Text('Buat Kelas Baru', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(key: _formKey, child: Column(children: [
              // Mata Kuliah
              DropdownButtonFormField<String>(
                initialValue: _mkId,
                decoration: const InputDecoration(labelText: 'Mata Kuliah'),
                items: _matkuls.map((m) => DropdownMenuItem(
                  value: m['id'].toString(),
                  child: Text('${m['kode']} — ${m['nama']}'),
                )).toList(),
                validator: (v) => v == null ? 'Pilih mata kuliah' : null,
                onChanged: (v) => setState(() => _mkId = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                // Kelas
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: _namaKelas,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: _kelasOpts.map((k) => DropdownMenuItem(value: k, child: Text('Kelas $k'))).toList(),
                  validator: (v) => v == null ? 'Pilih kelas' : null,
                  onChanged: (v) => setState(() => _namaKelas = v),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _ruangan,
                  decoration: const InputDecoration(labelText: 'Ruangan'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                )),
              ]),
              const SizedBox(height: 12),
              // Dosen
              DropdownButtonFormField<String>(
                initialValue: _dosenId,
                decoration: const InputDecoration(labelText: 'Dosen Pengampu'),
                items: _dosens.map((d) {
                  final p = d['profile'] as Map? ?? {};
                  return DropdownMenuItem(
                    value: d['id'].toString(),
                    child: Text(p['nama_lengkap'] ?? d['nip']),
                  );
                }).toList(),
                validator: (v) => v == null ? 'Pilih dosen' : null,
                onChanged: (v) => setState(() => _dosenId = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                // Hari
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: _hari,
                  decoration: const InputDecoration(labelText: 'Hari'),
                  items: _hariOpts.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                  validator: (v) => v == null ? 'Pilih hari' : null,
                  onChanged: (v) => setState(() => _hari = v),
                )),
                const SizedBox(width: 12),
                // Jam Mulai
                Expanded(child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _jamMulai);
                    if (t != null) setState(() => _jamMulai = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textLight),
                      const SizedBox(width: 8),
                      Text('${_jamMulai.format(context)} — ${_jamSelesai.format(context)}',
                        style: const TextStyle(color: AppColors.textDark)),
                    ]),
                  ),
                )),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5E2E8A)),
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buat Kelas'),
              ),
            ]),
          ),
        ])),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
      await SupabaseService.createKelas(
        mataKuliahId: _mkId!, semesterId: widget.semesterId,
        dosenId: _dosenId!, namaKelas: _namaKelas!,
        ruangan: _ruangan.text, hari: _hari!,
        jamMulai: fmt(_jamMulai), jamSelesai: fmt(_jamSelesai),
      );
      if (mounted) showSuccess(context, 'Kelas berhasil dibuat');
      widget.onSaved();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Error: $e');
    }
  }
}

class _ManageSantriKelasDialog extends StatefulWidget {
  final Map<String, dynamic> kelas;
  const _ManageSantriKelasDialog({required this.kelas});
  @override State<_ManageSantriKelasDialog> createState() => _ManageSantriKelasDialogState();
}

class _ManageSantriKelasDialogState extends State<_ManageSantriKelasDialog> {
  List<Map<String, dynamic>> _inKelas = [];
  List<Map<String, dynamic>> _allSantri = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      SupabaseService.getSantriInKelas(widget.kelas['id']),
      SupabaseService.getAllSantri(),
    ]);
    setState(() { _inKelas = results[0]; _allSantri = results[1]; _loading = false; });
  }

  List<Map<String, dynamic>> get _notInKelas {
    final inIds = _inKelas.map((k) => k['santri']?['id']).toSet();
    return _allSantri.where((s) => !inIds.contains(s['id'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mk = widget.kelas['mata_kuliah'] as Map? ?? {};
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(width: 560, height: 580, child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.group_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text('Santri — ${mk['nama']} Kelas ${widget.kelas['nama_kelas']}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white)),
          ]),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                // Santri dalam kelas
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dalam Kelas (${_inKelas.length})', style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Expanded(child: ListView.builder(
                    itemCount: _inKelas.length,
                    itemBuilder: (_, i) {
                      final s = _inKelas[i]['santri'] as Map? ?? {};
                      final p = s['profile'] as Map? ?? {};
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                        title: Text(p['nama_lengkap'] ?? '-', style: const TextStyle(fontSize: 13)),
                        subtitle: Text(s['nim'] ?? '-', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
                          onPressed: () async {
                            await SupabaseService.client.from('kelas_santri')
                                .delete().eq('id', _inKelas[i]['id']);
                            _load();
                          },
                        ),
                      );
                    },
                  )),
                ])),
                const VerticalDivider(color: AppColors.divider, width: 32),
                // Santri belum masuk kelas
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Belum Masuk (${_notInKelas.length})', style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Expanded(child: ListView.builder(
                    itemCount: _notInKelas.length,
                    itemBuilder: (_, i) {
                      final s = _notInKelas[i];
                      final p = s['profile'] as Map? ?? {};
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline, color: AppColors.textLight, size: 18),
                        title: Text(p['nama_lengkap'] ?? '-', style: const TextStyle(fontSize: 13)),
                        subtitle: Text(s['nim'] ?? '-', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                          onPressed: () async {
                            await SupabaseService.addSantriToKelas(widget.kelas['id'], s['id']);
                            _load();
                          },
                        ),
                      );
                    },
                  )),
                ])),
              ]),
            )),
      ])),
    );
  }
}
