// lib/features/santri/profil_santri_page.dart
// Halaman edit profil santri (NIM tidak bisa diubah)

import 'package:flutter/material.dart';
import 'package:pk_nanda/core/services/supabase_service.dart';
import 'package:pk_nanda/core/services/widgets.dart';
import 'package:pk_nanda/core/theme/app_theme.dart';

class ProfilSantriPage extends StatefulWidget {
  final String santriId;
  final String profileId;

  const ProfilSantriPage({
    super.key,
    required this.santriId,
    required this.profileId,
  });

  @override
  State<ProfilSantriPage> createState() => _ProfilSantriPageState();
}

class _ProfilSantriPageState extends State<ProfilSantriPage> {
  final _formKey = GlobalKey<FormState>();
  final _nama    = TextEditingController();
  final _noHp    = TextEditingController();
  final _alamat  = TextEditingController();
  String? _gender;
  String? _nim;
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.client.from('santri').select('''
        nim, angkatan, status,
        profile:profile_id(nama_lengkap, email, no_hp, alamat, gender)
      ''').eq('id', widget.santriId).single();

      final profile = data['profile'] as Map? ?? {};
      setState(() {
        _nim    = data['nim'];
        _nama.text   = profile['nama_lengkap'] ?? '';
        _noHp.text   = profile['no_hp'] ?? '';
        _alamat.text = profile['alamat'] ?? '';
        _gender      = profile['gender'];
        _loading     = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.client.from('profiles').update({
        'nama_lengkap': _nama.text,
        'no_hp'       : _noHp.text,
        'alamat'      : _alamat.text,
        'gender'      : _gender,
      }).eq('id', widget.profileId);

      if (mounted) showSuccess(context, 'Profil berhasil diperbarui');
      setState(() => _saving = false);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) showError(context, 'Gagal menyimpan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Edit Profil'),
        leading: const BackButton(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          _nama.text.isNotEmpty ? _nama.text[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 36)),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('NIM: ${_nim ?? '-'}', style: const TextStyle(
                  color: AppColors.textLight, fontSize: 13,
                  fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('NIM tidak dapat diubah',
                  style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(children: [
                    // NIM (disabled)
                    TextFormField(
                      initialValue: _nim ?? '-',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'NIM (tidak bisa diubah)',
                        prefixIcon: Icon(Icons.badge_rounded,
                            color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nama,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_rounded,
                            color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noHp,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP',
                        prefixIcon: Icon(Icons.phone_rounded,
                            color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _alamat,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.home_rounded,
                            color: AppColors.textLight),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc_rounded,
                            color: AppColors.textLight),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text('♂ Laki-laki')),
                        DropdownMenuItem(value: 'P', child: Text('♀ Perempuan')),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Simpan Perubahan',
                                style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
    );
  }
}
