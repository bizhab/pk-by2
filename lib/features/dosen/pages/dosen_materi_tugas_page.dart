import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/supabase_service_extended.dart';
import '../../../core/services/widgets.dart';

// ════════════════════════════════════════════════════════════
//  MATERI PERKULIAHAN
// ════════════════════════════════════════════════════════════
class DosenMateriPage extends StatefulWidget {
  final String dosenId;
  final String semesterId;
  const DosenMateriPage({super.key, required this.dosenId, required this.semesterId});
  @override State<DosenMateriPage> createState() => _DosenMateriPageState();
}

class _DosenMateriPageState extends State<DosenMateriPage> {
  List<Map<String, dynamic>> _kelas = [], _materi = [];
  String? _selectedKelasId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    SupabaseService.client
        .from('kelas')
        .select('id, nama_kelas, mata_kuliah:mata_kuliah_id(nama)')
        .eq('dosen_id', widget.dosenId)
        .then((d) => mounted ? setState(() => _kelas = d) : null);
  }

  Future<void> _loadMateri(String id) async {
    setState(() => _loading = true);
    final d = await DosenService.getMateriByKelas(id);
    setState(() { _materi = d; _loading = false; });
  }

  IconData _iconForType(String tipe) {
    if (tipe.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (tipe.contains('ppt')) return Icons.slideshow_rounded;
    if (tipe.contains('doc')) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

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
              Text('Materi Perkuliahan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: isMobile ? 22 : 26
              )),
              if (_selectedKelasId != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6B8A)),
                  onPressed: () => _uploadDialog(context),
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Upload Materi')),
            ],
          ),
          const SizedBox(height: 14),
          _KelasFilterBar(
            kelas: _kelas,
            selectedId: _selectedKelasId,
            onSelect: (id) { setState(() => _selectedKelasId = id); _loadMateri(id); }),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedKelasId == null
              ? const EmptyState(icon: Icons.upload_file_outlined,
                  message: 'Pilih kelas untuk melihat materi')
              : _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E6B8A)))
                  : _materi.isEmpty
                      ? EmptyState(icon: Icons.folder_open_outlined, message: 'Belum ada materi',
                          actionLabel: 'Upload', onAction: () => _uploadDialog(context))
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : (screenWidth < 900 ? 2 : 3), // RESPONSIVE GRID
                            crossAxisSpacing: 16, mainAxisSpacing: 16, 
                            childAspectRatio: isMobile ? 3.0 : 2.2),
                          itemCount: _materi.length,
                          itemBuilder: (_, i) {
                            final m = _materi[i];
                            return AppCard(
                              child: Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E6B8A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                  child: Icon(_iconForType(m['tipe_file'] ?? ''),
                                    color: const Color(0xFF2E6B8A), size: 22)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(m['judul'] ?? '-', style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13,
                                      color: AppColors.textDark),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                    Text(m['created_at']?.toString().substring(0, 10) ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                                  ])),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, size: 18),
                                  color: AppColors.error,
                                  onPressed: () async {
                                    await DosenService.deleteMateri(m['id']);
                                    _loadMateri(_selectedKelasId!);
                                  }),
                              ]),
                            );
                          }),
          ),
        ]),
      ),
    );
  }

  void _uploadDialog(BuildContext ctx) {
    final titCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Upload Materi', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titCtrl,
            decoration: const InputDecoration(labelText: 'Judul Materi')),
          const SizedBox(height: 12),
          TextField(controller: urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL File',
              hintText: 'https://...',
              helperText: 'Gunakan StorageService.uploadMateri() untuk upload langsung')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlg),
            child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6B8A)),
            onPressed: () async {
              if (titCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
              await DosenService.uploadMateri(
                kelasId: _selectedKelasId!, judul: titCtrl.text,
                deskripsi: null, fileUrl: urlCtrl.text, tipeFile: 'file');
              if (ctx.mounted) Navigator.pop(dlg);
              _loadMateri(_selectedKelasId!);
            },
            child: const Text('Upload')),
        ]));
  }
}


// ════════════════════════════════════════════════════════════
//  TUGAS
// ════════════════════════════════════════════════════════════
class DosenTugasPage extends StatefulWidget {
  final String dosenId;
  final String semesterId;
  const DosenTugasPage({super.key, required this.dosenId, required this.semesterId});
  @override State<DosenTugasPage> createState() => _DosenTugasPageState();
}

class _DosenTugasPageState extends State<DosenTugasPage> {
  List<Map<String, dynamic>> _kelas = [], _tugas = [];
  String? _selectedKelasId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    SupabaseService.client
        .from('kelas')
        .select('id, nama_kelas, mata_kuliah:mata_kuliah_id(nama)')
        .eq('dosen_id', widget.dosenId)
        .then((d) => mounted ? setState(() => _kelas = d) : null);
  }

  Future<void> _loadTugas(String id) async {
    setState(() => _loading = true);
    final d = await DosenService.getTugasByKelas(id);
    setState(() { _tugas = d; _loading = false; });
  }

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
              Text('Manajemen Tugas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: isMobile ? 22 : 26
              )),
              if (_selectedKelasId != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6B8A)),
                  onPressed: () => _buatDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Buat Tugas')),
            ],
          ),
          const SizedBox(height: 14),
          _KelasFilterBar(
            kelas: _kelas,
            selectedId: _selectedKelasId,
            onSelect: (id) { setState(() => _selectedKelasId = id); _loadTugas(id); }),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedKelasId == null
              ? const EmptyState(icon: Icons.assignment_outlined,
                  message: 'Pilih kelas terlebih dahulu')
              : _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E6B8A)))
                  : _tugas.isEmpty
                      ? EmptyState(icon: Icons.assignment_late_outlined, message: 'Belum ada tugas',
                          actionLabel: 'Buat Tugas', onAction: () => _buatDialog(context))
                      : ListView.separated(
                          itemCount: _tugas.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _TugasCard(
                            tugas: _tugas[i],
                            onDelete: () async {
                              final ok = await showConfirmDialog(context,
                                title: 'Hapus Tugas',
                                message: 'Hapus "${_tugas[i]['judul']}"?');
                              if (ok) {
                                await DosenService.deleteTugas(_tugas[i]['id']);
                                _loadTugas(_selectedKelasId!);
                              }
                            },
                            onLihat: () => _showPengumpulan(context, _tugas[i]))),
          ),
        ]),
      ),
    );
  }

  void _buatDialog(BuildContext ctx) {
    final judulCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    DateTime? deadline;

    showDialog(
      context: ctx,
      builder: (dlg) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Buat Tugas', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: judulCtrl,
              decoration: const InputDecoration(labelText: 'Judul Tugas')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi', alignLabelWithHint: true)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(), lastDate: DateTime(2030));
                if (d != null) setS(() => deadline = d);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded,
                    color: AppColors.textLight, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    deadline == null ? 'Pilih Deadline'
                      : deadline!.toString().substring(0, 10),
                    style: TextStyle(
                      color: deadline == null
                        ? AppColors.textLight : AppColors.textDark)),
                ]))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlg),
              child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6B8A)),
              onPressed: () async {
                if (judulCtrl.text.isEmpty || deadline == null) return;
                await DosenService.createTugas(
                  kelasId: _selectedKelasId!,
                  judul: judulCtrl.text,
                  deskripsi: descCtrl.text,
                  fileSoalUrl: null,
                  deadline: DateTime(
                    deadline!.year, deadline!.month, deadline!.day, 23, 59));
                if (ctx.mounted) Navigator.pop(dlg);
                _loadTugas(_selectedKelasId!);
              },
              child: const Text('Buat Tugas')),
          ])));
  }

  void _showPengumpulan(BuildContext ctx, Map<String, dynamic> tugas) {
    showDialog(
      context: ctx,
      builder: (_) => _PengumpulanDialog(
        tugasId: tugas['id'], judulTugas: tugas['judul']));
  }
}

class _TugasCard extends StatelessWidget {
  final Map<String, dynamic> tugas;
  final VoidCallback onDelete;
  final VoidCallback onLihat;
  const _TugasCard({required this.tugas, required this.onDelete, required this.onLihat});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dl    = DateTime.tryParse(tugas['deadline'] ?? '');
    final over  = dl != null && DateTime.now().isAfter(dl);
    final count = (tugas['pengumpulan_tugas'] as List?)?.length ?? 0;
    const color = Color(0xFF2E6B8A);

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (over ? AppColors.error : color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.assignment_rounded,
              color: over ? AppColors.error : color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tugas['judul'] ?? '-', style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('Deadline: ${tugas['deadline']?.toString().substring(0, 16) ?? '-'}',
              style: TextStyle(
                fontSize: 11,
                color: over ? AppColors.error : AppColors.textLight)),
          ])),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          StatusBadge(label: '$count terkumpul', color: color),
          const Spacer(),
          TextButton.icon(
            onPressed: onLihat,
            icon: Icon(Icons.visibility_rounded, size: 16, color: color),
            label: Text('Lihat', style: TextStyle(color: color, fontSize: 12)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8))),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_rounded, size: 16, color: AppColors.error),
            label: const Text('Hapus', style: TextStyle(color: AppColors.error, fontSize: 12)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8))),
        ]),
      ]),
    );
  }
}

class _PengumpulanDialog extends StatefulWidget {
  final String tugasId, judulTugas;
  const _PengumpulanDialog({required this.tugasId, required this.judulTugas});
  @override State<_PengumpulanDialog> createState() => _PengumpulanDialogState();
}

class _PengumpulanDialogState extends State<_PengumpulanDialog> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final d = await DosenService.getPengumpulanByTugas(widget.tugasId);
    setState(() { _list = d; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600), // CONSTRAINT UNTUK HP
        child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF2E6B8A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(children: [
            const Icon(Icons.assignment_turned_in_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text('Pengumpulan: ${widget.judulTugas}',
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 14),
              overflow: TextOverflow.ellipsis)),
            IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white)),
          ]),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E6B8A)))
            : _list.isEmpty
                ? const EmptyState(icon: Icons.inbox_outlined,
                    message: 'Belum ada yang mengumpulkan')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final p  = _list[i];
                      final s  = p['santri'] as Map? ?? {};
                      final pr = s['profile'] as Map? ?? {};
                      final nilaiCtrl = TextEditingController(
                        text: p['nilai']?.toString() ?? '');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          AvatarBadge(
                            name: pr['nama_lengkap'] ?? '-',
                            subtitle: s['nim'] ?? '-',
                            color: const Color(0xFF2E6B8A)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Text(p['waktu_kumpul']?.toString().substring(0, 16) ?? '-',
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                            const Spacer(),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: nilaiCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Nilai',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                keyboardType: TextInputType.number,
                                onSubmitted: (v) async {
                                  final n = double.tryParse(v);
                                  if (n != null) {
                                    await DosenService.beriNilaiTugas(p['id'], n, null);
                                    _load();
                                  }
                                })),
                          ]),
                        ]),
                      );
                    })),
      ])),
    );
  }
}


// ── Shared Widget: Filter Kelas Bar ───────────────────────
class _KelasFilterBar extends StatelessWidget {
  final List<Map<String, dynamic>> kelas;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _KelasFilterBar({
    required this.kelas,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kelas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final k  = kelas[i];
          final mk = k['mata_kuliah'] as Map? ?? {};
          final sel= selectedId == k['id'];
          return GestureDetector(
            onTap: () => onSelect(k['id']),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF2E6B8A) : AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? const Color(0xFF2E6B8A) : AppColors.divider)),
              child: Text(
                '${mk['nama']} — Kelas ${k['nama_kelas']}',
                style: TextStyle(
                  color: sel ? Colors.white : AppColors.textMid,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500))));
        }),
    );
  }
}
