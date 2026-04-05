import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class SantriListPage extends StatefulWidget {
  const SantriListPage({super.key});
  @override
  State<SantriListPage> createState() => _SantriListPageState();
}

class _SantriListPageState extends State<SantriListPage> {
  List<Map<String, dynamic>> _santri = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllSantri();
      setState(() { _santri = data; _filtered = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Gagal memuat data: $e');
    }
  }

  void _filter(String q) {
    final kw = q.toLowerCase();
    setState(() {
      _filtered = _santri.where((s) {
        final profile = s['profile'] as Map? ?? {};
        return profile['nama_lengkap'].toString().toLowerCase().contains(kw)
            || s['nim'].toString().toLowerCase().contains(kw);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Manajemen Santri', style: Theme.of(context).textTheme.headlineMedium),
                  Text('${_santri.length} santri terdaftar',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                ]),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Santri'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search
            TextField(
              controller: _search,
              onChanged: _filter,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NIM...',
                prefixIcon: Icon(Icons.search, color: AppColors.textLight),
              ),
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.school_outlined,
                          message: 'Belum ada santri',
                          actionLabel: 'Tambah Santri',
                          onAction: () => _showFormDialog(context),
                        )
                      : AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(children: [
                            _TableHeader(),
                            const Divider(height: 1, color: AppColors.divider),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                                itemBuilder: (ctx, i) => _SantriRow(
                                  santri: _filtered[i],
                                  onEdit: () => _showFormDialog(context, santri: _filtered[i]),
                                  onDelete: () => _deleteSantri(_filtered[i]),
                                ),
                              ),
                            ),
                          ]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSantri(Map<String, dynamic> santri) async {
    final profile = santri['profile'] as Map? ?? {};
    final ok = await showConfirmDialog(context,
      title: 'Hapus Santri',
      message: 'Hapus ${profile['nama_lengkap']}? Data tidak dapat dikembalikan.',
    );
    if (!ok) return;
    try {
      await SupabaseService.deleteSantri(profile['id']);
      showSuccess(context, 'Santri berhasil dihapus');
      _load();
    } catch (e) {
      showError(context, 'Gagal menghapus: $e');
    }
  }

  void _showFormDialog(BuildContext context, {Map<String, dynamic>? santri}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SantriFormDialog(
        santri: santri,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontWeight: FontWeight.w700, fontSize: 12,
      color: AppColors.textLight, letterSpacing: 0.5,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: const [
        Expanded(flex: 3, child: Text('NAMA SANTRI', style: style)),
        Expanded(flex: 2, child: Text('NIM', style: style)),
        Expanded(flex: 2, child: Text('ANGKATAN', style: style)),
        Expanded(flex: 2, child: Text('STATUS', style: style)),
        Expanded(flex: 2, child: Text('GENDER', style: style)),
        SizedBox(width: 80, child: Text('AKSI', style: style, textAlign: TextAlign.center)),
      ]),
    );
  }
}

class _SantriRow extends StatelessWidget {
  final Map<String, dynamic> santri;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SantriRow({required this.santri, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final profile = santri['profile'] as Map? ?? {};
    final nama = profile['nama_lengkap'] ?? '-';
    final nim = santri['nim'] ?? '-';
    final angkatan = santri['angkatan']?.toString() ?? '-';
    final status = santri['status'] ?? 'aktif';
    final gender = profile['gender'] ?? '-';

    Color statusColor;
    switch (status) {
      case 'aktif': statusColor = AppColors.primary; break;
      case 'cuti': statusColor = Colors.orange; break;
      case 'lulus': statusColor = Colors.blue; break;
      default: statusColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: AvatarBadge(
          name: nama, subtitle: profile['email'] ?? '', color: AppColors.primary,
        )),
        Expanded(flex: 2, child: Text(nim, style: const TextStyle(
          fontFamily: 'monospace', fontSize: 13, color: AppColors.textDark,
        ))),
        Expanded(flex: 2, child: Text(angkatan, style: const TextStyle(
          fontSize: 13, color: AppColors.textMid,
        ))),
        Expanded(flex: 2, child: StatusBadge(label: status.toUpperCase(), color: statusColor)),
        Expanded(flex: 2, child: Text(gender == 'L' ? '♂ Laki-laki' : gender == 'P' ? '♀ Perempuan' : '-',
          style: const TextStyle(fontSize: 13, color: AppColors.textMid))),
        SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppColors.secondary, tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete, icon: const Icon(Icons.delete_rounded, size: 18),
            color: AppColors.error, tooltip: 'Hapus',
          ),
        ])),
      ]),
    );
  }
}

// ── Form Dialog ───────────────────────────────────────────
class _SantriFormDialog extends StatefulWidget {
  final Map<String, dynamic>? santri;
  final VoidCallback onSaved;

  const _SantriFormDialog({this.santri, required this.onSaved});

  @override
  State<_SantriFormDialog> createState() => _SantriFormDialogState();
}

class _SantriFormDialogState extends State<_SantriFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nama    = TextEditingController();
  final _email   = TextEditingController();
  final _password = TextEditingController();
  final _nim     = TextEditingController();
  final _noHp    = TextEditingController();
  final _angkatan = TextEditingController();
  String? _gender;
  bool _loading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.santri != null;
    if (_isEdit) {
      final s = widget.santri!;
      final p = s['profile'] as Map? ?? {};
      _nama.text = p['nama_lengkap'] ?? '';
      _email.text = p['email'] ?? '';
      _nim.text = s['nim'] ?? '';
      _noHp.text = p['no_hp'] ?? '';
      _angkatan.text = s['angkatan']?.toString() ?? '';
      _gender = p['gender'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 500,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Title bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              const Icon(Icons.school_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(_isEdit ? 'Edit Santri' : 'Tambah Santri Baru',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ]),
          ),

          // Form
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(children: [
                Row(children: [
                  Expanded(child: _field(_nama, 'Nama Lengkap', Icons.person_rounded, required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_nim, 'NIM', Icons.badge_rounded, required: true,
                      enabled: !_isEdit)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_email, 'Email', Icons.email_rounded,
                      required: !_isEdit, enabled: !_isEdit)),
                  const SizedBox(height: 12, width: 12),
                  if (!_isEdit) Expanded(child: _field(_password, 'Password', Icons.lock_rounded,
                      required: true, obscure: true)),
                  if (_isEdit) Expanded(child: _field(_angkatan, 'Angkatan', Icons.calendar_today_rounded)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_noHp, 'No. HP', Icons.phone_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.wc_rounded, color: AppColors.textLight),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                      DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  )),
                ]),
              ]),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: AppColors.textMid)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Santri'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = false, bool obscure = false, bool enabled = true}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      enabled: enabled,
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textLight, size: 18),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        final santriId = widget.santri!['id'];
        await SupabaseService.updateSantri(santriId,
          {'nama_lengkap': _nama.text, 'no_hp': _noHp.text, 'gender': _gender},
          {'angkatan': int.tryParse(_angkatan.text)},
        );
        if (mounted) showSuccess(context, 'Data santri diperbarui');
      } else {
        await SupabaseService.createSantri(
          email: _email.text, password: _password.text,
          namaLengkap: _nama.text, nim: _nim.text,
          noHp: _noHp.text, gender: _gender,
          angkatan: int.tryParse(_angkatan.text),
          semesterMasukId: null,
        );
        if (mounted) showSuccess(context, 'Santri berhasil ditambahkan');
      }
      widget.onSaved();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Error: $e');
    }
  }
}
