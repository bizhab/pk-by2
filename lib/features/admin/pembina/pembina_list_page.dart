import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class PembinaListPage extends StatefulWidget {
  const PembinaListPage({super.key});
  @override
  State<PembinaListPage> createState() => _PembinaListPageState();
}

class _PembinaListPageState extends State<PembinaListPage> {
  List<Map<String, dynamic>> _pembina = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllPembina();
      setState(() { _pembina = data; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
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
              Text('Manajemen Pembina', style: Theme.of(context).textTheme.headlineMedium),
              Text('${_pembina.length} pembina terdaftar',
                style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
            ]),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A5E2E)),
              onPressed: () => _showForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Pembina'),
            ),
          ]),
          const SizedBox(height: 20),
          Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _pembina.isEmpty
              ? EmptyState(icon: Icons.supervisor_account_outlined,
                  message: 'Belum ada pembina',
                  actionLabel: 'Tambah Pembina', onAction: () => _showForm(context))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 16,
                    mainAxisSpacing: 16, childAspectRatio: 2.5,
                  ),
                  itemCount: _pembina.length,
                  itemBuilder: (_, i) {
                    final pb = _pembina[i];
                    final p = pb['profile'] as Map? ?? {};
                    final nama = p['nama_lengkap'] ?? '-';
                    return AppCard(
                      child: Row(children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF8A5E2E).withOpacity(0.15),
                          child: Text(
                            nama.isNotEmpty ? nama[0].toUpperCase() : 'P',
                            style: const TextStyle(color: Color(0xFF8A5E2E),
                                fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(nama, style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 14)),
                            Text('Kode: ${pb['kode_pembina'] ?? '-'}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                            Text(p['email'] ?? '-',
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              overflow: TextOverflow.ellipsis),
                          ],
                        )),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          color: AppColors.error,
                          onPressed: () async {
                            final ok = await showConfirmDialog(context,
                              title: 'Hapus Pembina', message: 'Hapus $nama?');
                            if (ok) {
                              await SupabaseService.deletePembina(p['id']);
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
    showDialog(context: context, builder: (ctx) => _PembinaFormDialog(
      onSaved: () { Navigator.pop(ctx); _load(); },
    ));
  }
}

class _PembinaFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _PembinaFormDialog({required this.onSaved});
  @override State<_PembinaFormDialog> createState() => _PembinaFormDialogState();
}

class _PembinaFormDialogState extends State<_PembinaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nama  = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _kode  = TextEditingController();
  final _noHp  = TextEditingController();
  String? _gender;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(width: 460, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF8A5E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            const Icon(Icons.supervisor_account_rounded, color: Colors.white),
            const SizedBox(width: 10),
            const Text('Tambah Pembina', style: TextStyle(color: Colors.white,
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
              Expanded(child: _f(_kode, 'Kode Pembina', required: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(_email, 'Email', required: true)),
              const SizedBox(width: 12),
              Expanded(child: _f(_pass, 'Password', required: true, obscure: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(_noHp, 'No. HP')),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (v) => setState(() => _gender = v),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8A5E2E)),
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Tambah Pembina'),
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
      await SupabaseService.createPembina(
        email: _email.text, password: _pass.text,
        namaLengkap: _nama.text, kodePembina: _kode.text,
        noHp: _noHp.text, gender: _gender,
      );
      if (mounted) showSuccess(context, 'Pembina berhasil ditambahkan');
      widget.onSaved();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Error: $e');
    }
  }
}
