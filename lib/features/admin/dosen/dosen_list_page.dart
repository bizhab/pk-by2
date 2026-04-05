// ── dosen_list_page.dart ──────────────────────────────────
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class DosenListPage extends StatefulWidget {
  const DosenListPage({super.key});
  @override
  State<DosenListPage> createState() => _DosenListPageState();
}

class _DosenListPageState extends State<DosenListPage> {
  List<Map<String, dynamic>> _dosen = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllDosen();
      setState(() { _dosen = data; _filtered = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _filter(String q) {
    final kw = q.toLowerCase();
    setState(() {
      _filtered = _dosen.where((d) {
        final p = d['profile'] as Map? ?? {};
        return p['nama_lengkap'].toString().toLowerCase().contains(kw)
            || d['nip'].toString().toLowerCase().contains(kw);
      }).toList();
    });
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
              Text('Manajemen Dosen', style: Theme.of(context).textTheme.headlineMedium),
              Text('${_dosen.length} dosen terdaftar',
                style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
            ]),
            ElevatedButton.icon(
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Dosen'),
            ),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: _search, onChanged: _filter,
            decoration: const InputDecoration(
              hintText: 'Cari nama atau NIP...',
              prefixIcon: Icon(Icons.search, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _filtered.isEmpty
              ? EmptyState(icon: Icons.person_pin_outlined, message: 'Belum ada dosen',
                  actionLabel: 'Tambah Dosen', onAction: () => _showForm(context))
              : AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final d = _filtered[i];
                      final p = d['profile'] as Map? ?? {};
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2E6B8A).withOpacity(0.15),
                          child: Text(
                            (p['nama_lengkap'] ?? 'D').toString().isNotEmpty
                              ? p['nama_lengkap'].toString()[0].toUpperCase() : 'D',
                            style: const TextStyle(color: Color(0xFF2E6B8A), fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(p['nama_lengkap'] ?? '-', style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        subtitle: Text('NIP: ${d['nip'] ?? '-'} • ${d['bidang_studi'] ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.delete_rounded, size: 18),
                            color: AppColors.error,
                            onPressed: () async {
                              final ok = await showConfirmDialog(context,
                                title: 'Hapus Dosen', message: 'Hapus ${p['nama_lengkap']}?');
                              if (ok) {
                                await SupabaseService.deleteDosen(p['id']);
                                _load();
                              }
                            }),
                        ]),
                      );
                    },
                  ),
                )),
        ]),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _DosenFormDialog(
      onSaved: () { Navigator.pop(ctx); _load(); },
    ));
  }
}

class _DosenFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _DosenFormDialog({required this.onSaved});
  @override State<_DosenFormDialog> createState() => _DosenFormDialogState();
}

class _DosenFormDialogState extends State<_DosenFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nip = TextEditingController();
  final _bidang = TextEditingController();
  final _noHp = TextEditingController();
  String? _gender;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF2E6B8A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.person_pin_rounded, color: Colors.white),
            const SizedBox(width: 10),
            const Text('Tambah Dosen', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Form(key: _formKey, child: Column(children: [
            Row(children: [
              Expanded(child: _f(_nama, 'Nama Lengkap', required: true)),
              const SizedBox(width: 12),
              Expanded(child: _f(_nip, 'NIP', required: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(_email, 'Email', required: true)),
              const SizedBox(width: 12),
              Expanded(child: _f(_password, 'Password', required: true, obscure: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(_bidang, 'Bidang Studi')),
              const SizedBox(width: 12),
              Expanded(child: _f(_noHp, 'No. HP')),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'P', child: Text('Perempuan')),
              ],
              onChanged: (v) => setState(() => _gender = v),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6B8A)),
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Tambah Dosen'),
            ),
          ]),
        ),
      ])),
    );
  }

  Widget _f(TextEditingController c, String label, {bool required = false, bool obscure = false}) {
    return TextFormField(
      controller: c, obscureText: obscure,
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null : null,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await SupabaseService.createDosen(
        email: _email.text, password: _password.text,
        namaLengkap: _nama.text, nip: _nip.text,
        bidangStudi: _bidang.text, noHp: _noHp.text, gender: _gender,
      );
      if (mounted) showSuccess(context, 'Dosen berhasil ditambahkan');
      widget.onSaved();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Error: $e');
    }
  }
}
