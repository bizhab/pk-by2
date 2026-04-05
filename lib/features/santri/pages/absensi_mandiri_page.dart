// lib/features/santri/absensi_mandiri_page.dart
// Halaman absensi mandiri santri:
// - Cek geofence (lokasi)
// - Input kode absen (opsional)
// - Pilih status: hadir / izin / sakit / terlambat
// - Upload bukti jika izin/sakit

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/geofence_service.dart';
import '../../../core/services/widgets.dart';

// NOTE: Tambahkan ke pubspec.yaml untuk GPS:
//   geolocator: ^11.0.0
// Dan di AndroidManifest.xml / Info.plist, tambahkan permission lokasi.
// Untuk sementara, absensi tanpa GPS aktif juga bisa (manual lat/lng = null).

class AbsensiMandiriPage extends StatefulWidget {
  final Map<String, dynamic> sesi;     // data sesi absensi yang aktif
  final String santriId;
  final String namaKelas;

  const AbsensiMandiriPage({
    super.key,
    required this.sesi,
    required this.santriId,
    required this.namaKelas,
  });

  @override
  State<AbsensiMandiriPage> createState() => _AbsensiMandiriPageState();
}

class _AbsensiMandiriPageState extends State<AbsensiMandiriPage> {
  final _kodeCtrl = TextEditingController();
  String _status = 'hadir';
  bool _loading = false;
  bool _cekingLokasi = false;
  GeofenceResult? _lokasiResult;
  double? _userLat, _userLng;

  // Status yang butuh bukti
  bool get _butuhBukti => _status == 'izin' || _status == 'sakit';

  @override
  void initState() {
    super.initState();
    _cekLokasi();
  }

  Future<void> _cekLokasi() async {
    setState(() => _cekingLokasi = true);
    // TODO: ganti dengan geolocator.getCurrentPosition() setelah install package
    // Contoh dengan geolocator:
    //   final pos = await Geolocator.getCurrentPosition();
    //   _userLat = pos.latitude; _userLng = pos.longitude;
    //
    // Untuk demo, gunakan koordinat dummy:
    _userLat = -5.1476; // ganti dengan koordinat user sesungguhnya
    _userLng = 119.4327;

    final geofenceId = widget.sesi['geofence_id']?.toString();
    final result = await GeofenceService.cekRadius(
      userLat: _userLat!,
      userLng: _userLng!,
      geofenceId: geofenceId,
    );
    setState(() { _lokasiResult = result; _cekingLokasi = false; });
  }

  @override
  Widget build(BuildContext context) {
    final kelas = widget.sesi['kelas'] as Map? ?? {};
    final matkul = kelas['mata_kuliah']?['nama'] ?? widget.namaKelas;
    final namaKelas = kelas['nama_kelas'] ?? '';
    final geofenceId = widget.sesi['geofence_id'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Absen: $matkul — Kelas $namaKelas'),
        leading: BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Lokasi Status ────────────────────────────
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.location_on_rounded,
                  color: _lokasiResult?.diIzinkan == true
                      ? AppColors.primary : AppColors.error, size: 20),
                const SizedBox(width: 8),
                const Text('Status Lokasi', style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const Spacer(),
                if (!_cekingLokasi)
                  TextButton.icon(
                    onPressed: _cekLokasi,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
              ]),
              const SizedBox(height: 10),
              if (_cekingLokasi)
                const Row(children: [
                  SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  SizedBox(width: 12),
                  Text('Mendeteksi lokasi...', style: TextStyle(color: AppColors.textMid)),
                ])
              else if (_lokasiResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_lokasiResult!.diIzinkan
                        ? AppColors.primary : AppColors.error).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_lokasiResult!.diIzinkan
                          ? AppColors.primary : AppColors.error).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(
                      _lokasiResult!.diIzinkan
                          ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: _lokasiResult!.diIzinkan ? AppColors.primary : AppColors.error,
                      size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_lokasiResult!.pesan, style: TextStyle(
                      fontSize: 13,
                      color: _lokasiResult!.diIzinkan ? AppColors.primary : AppColors.error,
                      fontWeight: FontWeight.w500))),
                  ]),
                ),
                if (_lokasiResult!.jarak > 0) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    _InfoChip(label: 'Jarak Anda', value: _lokasiResult!.jarakDisplay),
                    const SizedBox(width: 10),
                    _InfoChip(label: 'Radius Max',
                      value: '${_lokasiResult!.radius.toInt()} m'),
                  ]),
                ],
              ],

              // Jika tidak ada geofence, tampilkan info
              if (geofenceId == null)
                const Text('Absensi tanpa validasi lokasi.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Kode Absen ───────────────────────────────
          if (widget.sesi['kode_absen'] != null) ...[
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Kode Absen', style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 8),
                const Text('Masukkan kode 6 digit dari dosen/pembina:',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 10),
                TextField(
                  controller: _kodeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '_ _ _ _ _ _',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_open_rounded, color: AppColors.textLight),
                  ),
                  style: const TextStyle(
                    fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Pilih Status ─────────────────────────────
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Status Kehadiran', style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _StatusBtn(label: 'Hadir', icon: Icons.check_circle_rounded,
                  color: AppColors.primary, selected: _status == 'hadir',
                  onTap: () => setState(() => _status = 'hadir')),
                _StatusBtn(label: 'Terlambat', icon: Icons.access_time_rounded,
                  color: Colors.orange, selected: _status == 'terlambat',
                  onTap: () => setState(() => _status = 'terlambat')),
                _StatusBtn(label: 'Izin', icon: Icons.description_rounded,
                  color: const Color(0xFF2E6B8A), selected: _status == 'izin',
                  onTap: () => setState(() => _status = 'izin')),
                _StatusBtn(label: 'Sakit', icon: Icons.local_hospital_rounded,
                  color: Colors.red.shade700, selected: _status == 'sakit',
                  onTap: () => setState(() => _status = 'sakit')),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Upload Bukti (jika izin/sakit) ───────────
          if (_butuhBukti) ...[
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.attach_file_rounded,
                      color: Color(0xFF2E6B8A), size: 18),
                  const SizedBox(width: 8),
                  Text('Wajib: Upload Bukti ${_status == 'izin' ? 'Izin' : 'Sakit'}',
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                ]),
                const SizedBox(height: 10),
                Text(
                  _status == 'sakit'
                      ? 'Upload foto surat keterangan dokter atau keterangan sakit.'
                      : 'Upload foto surat izin atau keterangan dari orang tua/wali.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pilihBukti,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E6B8A),
                    side: const BorderSide(color: Color(0xFF2E6B8A)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: const Text('Pilih File / Foto'),
                ),
                const SizedBox(height: 6),
                const Text('Format: JPG, PNG, PDF. Maks 5MB.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ── Tombol Submit ─────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_loading || _cekingLokasi) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lokasiResult?.diIzinkan != false
                    ? AppColors.primary : AppColors.error,
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _lokasiResult?.diIzinkan == false
                          ? 'Di Luar Radius — Tidak Bisa Absen'
                          : 'Kirim Absensi',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          if (_lokasiResult?.diIzinkan == false)
            const Center(child: Text(
              'Anda harus berada dalam radius pesantren untuk absen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error, fontSize: 12))),
        ]),
      ),
    );
  }

  void _pilihBukti() {
    // TODO: Implementasi dengan file_picker:
    //   final result = await FilePicker.platform.pickFiles(type: FileType.custom,
    //     allowedExtensions: ['jpg','jpeg','png','pdf']);
    //   if (result != null) { ... upload dengan StorageService.uploadBukti(...) }
    showSuccess(context, 'Tambahkan package "file_picker" untuk fitur upload.');
  }

  Future<void> _submit() async {
    // Validasi lokasi
    if (_lokasiResult != null && !_lokasiResult!.diIzinkan) {
      showError(context, 'Anda di luar radius. Tidak bisa absen.');
      return;
    }

    setState(() => _loading = true);
    try {
      await SupabaseService.client.from('absensi_akademik').upsert({
        'sesi_id'    : widget.sesi['id'],
        'santri_id'  : widget.santriId,
        'status'     : _status,
        'waktu_absen': DateTime.now().toIso8601String(),
        'latitude'   : _userLat,
        'longitude'  : _userLng,
      }, onConflict: 'sesi_id,santri_id');

      if (mounted) {
        showSuccess(context, 'Absensi berhasil dikirim!');
        Navigator.pop(context, true); // return true = absen berhasil
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, 'Gagal absen: $e');
    }
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusBtn({
    required this.label, required this.icon,
    required this.color, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: selected ? Colors.white : color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  const _InfoChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
          fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(
          fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
