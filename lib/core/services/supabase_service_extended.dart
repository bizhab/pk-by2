// lib/core/services/supabase_service_extended.dart
// Tambahan method untuk Dosen, Pembina, Santri
// Import file ini bersama supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

extension DosenService on _Svc {
  // ── Sesi Absensi Akademik (Dosen) ───────────────────────
  static Future<List<Map<String, dynamic>>> getSesiByDosen(String dosenId) async {
    return await _c.from('sesi_absensi_akademik').select('''
      id, tanggal, jam_buka, jam_tutup, kode_absen,
      kelas:kelas_id(id, nama_kelas, mata_kuliah:mata_kuliah_id(nama, kode))
    ''')
    .inFilter('kelas_id',
      (await _c.from('kelas').select('id').eq('dosen_id', dosenId)).map((k) => k['id']).toList()
    )
    .order('created_at', ascending: false)
    .limit(50);
  }

  static Future<Map<String, dynamic>> bukaSesiAbsensiAkademik({
    required String kelasId,
    required String geofenceId,
    required String kodeAbsen,
    required int durasiMenit,
  }) async {
    final now = DateTime.now();
    final tutup = now.add(Duration(minutes: durasiMenit));
    final res = await _c.from('sesi_absensi_akademik').insert({
      'kelas_id'    : kelasId,
      'tanggal'     : now.toIso8601String().split('T').first,
      'jam_buka'    : now.toIso8601String(),
      'jam_tutup'   : tutup.toIso8601String(),
      'kode_absen'  : kodeAbsen,
      'geofence_id' : geofenceId,
      'dibuka_oleh' : _c.auth.currentUser?.id,
    }).select().single();
    // Auto-isi semua santri di kelas dengan status alpha
    final santris = await _c.from('kelas_santri').select('santri_id').eq('kelas_id', kelasId);
    if (santris.isNotEmpty) {
      await _c.from('absensi_akademik').upsert(
        santris.map((s) => {
          'sesi_id'  : res['id'],
          'santri_id': s['santri_id'],
          'status'   : 'alpha',
        }).toList(),
        onConflict: 'sesi_id,santri_id',
      );
    }
    return res;
  }

  static Future<void> tutupSesiAbsensiAkademik(String sesiId) async {
    await _c.from('sesi_absensi_akademik').update({
      'jam_tutup': DateTime.now().toIso8601String(),
    }).eq('id', sesiId);
  }

  static Future<List<Map<String, dynamic>>> getAbsensiDetailBySesi(String sesiId) async {
    return await _c.from('absensi_akademik').select('''
      id, status, waktu_absen, catatan, diubah_oleh, diubah_at,
      santri:santri_id(id, nim, profile:profile_id(nama_lengkap, foto_url))
    ''').eq('sesi_id', sesiId).order('santri(profile(nama_lengkap))');
  }

  static Future<void> editStatusAbsensiAkademik(String absensiId, String status, String? catatan) async {
    await _c.from('absensi_akademik').update({
      'status'     : status,
      'catatan'    : catatan,
      'diubah_oleh': _c.auth.currentUser?.id,
      'diubah_at'  : DateTime.now().toIso8601String(),
    }).eq('id', absensiId);
  }

  // ── Materi Kuliah ─────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMateriByKelas(String kelasId) async {
    return await _c.from('materi_kuliah').select('''
      id, judul, deskripsi, file_url, tipe_file, created_at,
      diunggah_oleh:diunggah_oleh(nama_lengkap)
    ''').eq('kelas_id', kelasId).order('created_at', ascending: false);
  }

  static Future<void> uploadMateri({
    required String kelasId, required String judul,
    required String? deskripsi, required String fileUrl, required String? tipeFile,
  }) async {
    await _c.from('materi_kuliah').insert({
      'kelas_id'     : kelasId,
      'judul'        : judul,
      'deskripsi'    : deskripsi,
      'file_url'     : fileUrl,
      'tipe_file'    : tipeFile,
      'diunggah_oleh': _c.auth.currentUser?.id,
    });
  }

  static Future<void> deleteMateri(String id) async {
    await _c.from('materi_kuliah').delete().eq('id', id);
  }

  // ── Tugas ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getTugasByKelas(String kelasId) async {
    return await _c.from('tugas').select('''
      id, judul, deskripsi, file_soal_url, deadline, created_at,
      pengumpulan_tugas(id)
    ''').eq('kelas_id', kelasId).order('deadline');
  }

  static Future<void> createTugas({
    required String kelasId, required String judul,
    required String? deskripsi, required String? fileSoalUrl,
    required DateTime deadline,
  }) async {
    await _c.from('tugas').insert({
      'kelas_id'    : kelasId,
      'judul'       : judul,
      'deskripsi'   : deskripsi,
      'file_soal_url': fileSoalUrl,
      'deadline'    : deadline.toIso8601String(),
      'dibuat_oleh' : _c.auth.currentUser?.id,
    });
  }

  static Future<void> deleteTugas(String id) async {
    await _c.from('tugas').delete().eq('id', id);
  }

  static Future<List<Map<String, dynamic>>> getPengumpulanByTugas(String tugasId) async {
    return await _c.from('pengumpulan_tugas').select('''
      id, file_jawaban_url, catatan_santri, waktu_kumpul, nilai, catatan_dosen,
      santri:santri_id(id, nim, profile:profile_id(nama_lengkap))
    ''').eq('tugas_id', tugasId).order('waktu_kumpul');
  }

  static Future<void> beriNilaiTugas(String pengumpulanId, double nilai, String? catatan) async {
    await _c.from('pengumpulan_tugas').update({
      'nilai'       : nilai,
      'catatan_dosen': catatan,
    }).eq('id', pengumpulanId);
  }

  // ── Rekap Kehadiran (export data) ────────────────────
  static Future<List<Map<String, dynamic>>> getRekapKehadiranKelas(String kelasId) async {
    return await _c.from('v_rekap_absensi_akademik').select().eq('kelas_id', kelasId);
  }
}

extension PembinaService on _Svc {
  // ── Dashboard Pembina ─────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardPembina(String pembinaId, String semesterId) async {
    final kelompok = await _c.from('kelompok_pembina').select('id').eq('pembina_id', pembinaId)
        .eq('semester_id', semesterId).maybeSingle();
    if (kelompok == null) return {'kelompok': null, 'total_santri': 0};

    final kelompokId = kelompok['id'];
    final results = await Future.wait([
      _c.from('kelompok_santri').select('id').eq('kelompok_pembina_id', kelompokId).count(CountOption.exact),
      _c.from('sesi_absensi_ibadah').select('id').eq('kelompok_pembina_id', kelompokId).count(CountOption.exact),
      _c.from('surat_peringatan').select('id').eq('pembina_id', pembinaId).eq('semester_id', semesterId).eq('status', 'aktif').count(CountOption.exact),
    ]);
    return {
      'kelompok_id'    : kelompokId,
      'total_santri'   : results[0].count,
      'total_sesi'     : results[1].count,
      'total_sp_aktif' : results[2].count,
    };
  }

  static Future<List<Map<String, dynamic>>> getSantriKelompok(String kelompokId) async {
    return await _c.from('kelompok_santri').select('''
      id, santri:santri_id(
        id, nim, status,
        profile:profile_id(id, nama_lengkap, foto_url, no_hp)
      )
    ''').eq('kelompok_pembina_id', kelompokId);
  }

  // ── Sesi Absensi Ibadah ───────────────────────────────
  static Future<List<Map<String, dynamic>>> getSesiIbadahByKelompok(String kelompokId) async {
    return await _c.from('sesi_absensi_ibadah').select('''
      id, tanggal, jam_buka, jam_tutup,
      jadwal_sholat:jadwal_sholat_id(id, nama_sholat, kategori, jam_mulai, jam_selesai)
    ''').eq('kelompok_pembina_id', kelompokId)
        .order('tanggal', ascending: false)
        .order('jam_buka', ascending: false)
        .limit(100);
  }

  static Future<Map<String, dynamic>> bukaSesiIbadah({
    required String kelompokId, required String jadwalSholatId,
    required String? geofenceId,
  }) async {
    final now = DateTime.now();
    // Cek apakah sudah ada sesi hari ini untuk sholat ini
    final existing = await _c.from('sesi_absensi_ibadah').select('id')
        .eq('kelompok_pembina_id', kelompokId)
        .eq('jadwal_sholat_id', jadwalSholatId)
        .eq('tanggal', now.toIso8601String().split('T').first)
        .maybeSingle();
    if (existing != null) throw Exception('Sesi untuk sholat ini sudah dibuka hari ini');

    final res = await _c.from('sesi_absensi_ibadah').insert({
      'kelompok_pembina_id': kelompokId,
      'jadwal_sholat_id'   : jadwalSholatId,
      'tanggal'            : now.toIso8601String().split('T').first,
      'jam_buka'           : now.toIso8601String(),
      'geofence_id'        : geofenceId,
      'dibuka_oleh'        : _c.auth.currentUser?.id,
    }).select().single();

    // Auto-isi semua santri dengan alpha
    final santris = await _c.from('kelompok_santri').select('santri_id')
        .eq('kelompok_pembina_id', kelompokId);
    if (santris.isNotEmpty) {
      await _c.from('absensi_ibadah').upsert(
        santris.map((s) => {
          'sesi_id'  : res['id'],
          'santri_id': s['santri_id'],
          'status'   : 'alpha',
        }).toList(),
        onConflict: 'sesi_id,santri_id',
      );
    }
    return res;
  }

  static Future<void> tutupSesiIbadah(String sesiId) async {
    await _c.from('sesi_absensi_ibadah').update({
      'jam_tutup': DateTime.now().toIso8601String(),
    }).eq('id', sesiId);
  }

  static Future<List<Map<String, dynamic>>> getAbsensiIbadahBySesi(String sesiId) async {
    return await _c.from('absensi_ibadah').select('''
      id, status, waktu_absen, catatan,
      santri:santri_id(id, nim, profile:profile_id(nama_lengkap, foto_url))
    ''').eq('sesi_id', sesiId).order('santri(profile(nama_lengkap))');
  }

  static Future<void> editStatusAbsensiIbadah(String absensiId, String status, String? catatan) async {
    await _c.from('absensi_ibadah').update({
      'status' : status,
      'catatan': catatan,
    }).eq('id', absensiId);
  }

  // ── Rekap Ibadah ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRekapIbadahKelompok(String kelompokId) async {
    return await _c.from('v_rekap_absensi_ibadah').select().eq('kelompok_pembina_id', kelompokId);
  }

  static Future<List<Map<String, dynamic>>> getRekapIbadahHarian(String kelompokId, String tanggal) async {
    return await _c.from('sesi_absensi_ibadah').select('''
      id, tanggal, jam_buka, jam_tutup,
      jadwal_sholat:jadwal_sholat_id(nama_sholat, kategori),
      absensi_ibadah(
        id, status, santri:santri_id(id, nim, profile:profile_id(nama_lengkap))
      )
    ''').eq('kelompok_pembina_id', kelompokId).eq('tanggal', tanggal);
  }

  // ── Surat Peringatan ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> getSPByPembina(String pembinaId, String semesterId) async {
    return await _c.from('surat_peringatan').select('''
      id, level, alasan, hukuman, status, tanggal_sp,
      santri:santri_id(id, nim, profile:profile_id(nama_lengkap))
    ''').eq('pembina_id', pembinaId).eq('semester_id', semesterId)
        .order('tanggal_sp', ascending: false);
  }

  static Future<void> buatSP({
    required String santriId, required String pembinaId,
    required String semesterId, required String level,
    required String alasan, required String? hukuman,
    String? referensiAbsensiId,
  }) async {
    await _c.from('surat_peringatan').insert({
      'santri_id'                  : santriId,
      'pembina_id'                 : pembinaId,
      'semester_id'                : semesterId,
      'level'                      : level,
      'alasan'                     : alasan,
      'hukuman'                    : hukuman,
      'referensi_absensi_ibadah'   : referensiAbsensiId,
      'tanggal_sp'                 : DateTime.now().toIso8601String().split('T').first,
    });
  }

  static Future<void> updateStatusSP(String spId, String status) async {
    await _c.from('surat_peringatan').update({'status': status}).eq('id', spId);
  }

  // ── Broadcast ke Santri Binaan ───────────────────────
  static Future<void> broadcastKelompok({
    required String judul, required String isi, required String kelompokId,
  }) async {
    await _c.from('pengumuman').insert({
      'judul'             : judul,
      'isi'               : isi,
      'target'            : 'kelompok_pembina',
      'target_kelompok_id': kelompokId,
      'dibuat_oleh'       : _c.auth.currentUser?.id,
      'is_push'           : true,
    });
  }
}

extension SantriService on _Svc {
  // ── Dashboard Santri ──────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardSantri(String santriId, String semesterId) async {
    final results = await Future.wait([
      _c.from('kelas_santri').select('kelas_id').eq('santri_id', santriId).count(CountOption.exact),
      _c.from('surat_peringatan').select('id').eq('santri_id', santriId).eq('semester_id', semesterId).count(CountOption.exact),
      _c.from('pengumpulan_tugas').select('id').eq('santri_id', santriId).count(CountOption.exact),
    ]);
    return {
      'total_kelas': results[0].count,
      'total_sp'   : results[1].count,
      'total_tugas': results[2].count,
    };
  }

  // ── Kelas Santri ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getKelasSantri(String santriId) async {
    return await _c.from('kelas_santri').select('''
      id, kelas:kelas_id(
        id, nama_kelas, ruangan, hari, jam_mulai, jam_selesai,
        mata_kuliah:mata_kuliah_id(nama, kode, sks),
        dosen:dosen_id(profile:profile_id(nama_lengkap))
      )
    ''').eq('santri_id', santriId);
  }

  // ── Absensi Akademik Mandiri ───────────────────────────
  static Future<List<Map<String, dynamic>>> getSesiAktifUntukSantri(String santriId) async {
    // Ambil kelas yang diikuti santri
    final kelasSantri = await _c.from('kelas_santri').select('kelas_id').eq('santri_id', santriId);
    if (kelasSantri.isEmpty) return [];
    final kelasIds = kelasSantri.map((k) => k['kelas_id']).toList();

    return await _c.from('sesi_absensi_akademik').select('''
      id, tanggal, jam_buka, jam_tutup, kode_absen, geofence_id,
      kelas:kelas_id(id, nama_kelas, mata_kuliah:mata_kuliah_id(nama))
    ''')
    .inFilter('kelas_id', kelasIds)
    .isFilter('jam_tutup', null) // hanya yang masih buka
    .order('jam_buka', ascending: false);
  }

  static Future<void> absenAkademikMandiri({
    required String sesiId, required String santriId,
    required String status, required double? lat, required double? lng,
    required String? kodeAbsen,
  }) async {
    // Validasi kode jika diminta
    if (kodeAbsen != null) {
      final sesi = await _c.from('sesi_absensi_akademik').select('kode_absen').eq('id', sesiId).single();
      if (sesi['kode_absen'] != kodeAbsen) throw Exception('Kode absen salah');
    }
    await _c.from('absensi_akademik').upsert({
      'sesi_id'   : sesiId,
      'santri_id' : santriId,
      'status'    : status,
      'waktu_absen': DateTime.now().toIso8601String(),
      'latitude'  : lat,
      'longitude' : lng,
    }, onConflict: 'sesi_id,santri_id');
  }

  // ── Absensi Ibadah Mandiri ────────────────────────────
  static Future<List<Map<String, dynamic>>> getSesiIbadahAktifUntukSantri(String santriId) async {
    // Ambil kelompok santri
    final kelompok = await _c.from('kelompok_santri').select('kelompok_pembina_id')
        .eq('santri_id', santriId).maybeSingle();
    if (kelompok == null) return [];

    return await _c.from('sesi_absensi_ibadah').select('''
      id, tanggal, jam_buka, jam_tutup, geofence_id,
      jadwal_sholat:jadwal_sholat_id(id, nama_sholat, kategori, jam_mulai, jam_selesai)
    ''')
    .eq('kelompok_pembina_id', kelompok['kelompok_pembina_id'])
    .isFilter('jam_tutup', null)
    .order('jam_buka', ascending: false);
  }

  static Future<void> absenIbadahMandiri({
    required String sesiId, required String santriId,
    required String status, required double? lat, required double? lng,
  }) async {
    await _c.from('absensi_ibadah').upsert({
      'sesi_id'    : sesiId,
      'santri_id'  : santriId,
      'status'     : status,
      'waktu_absen': DateTime.now().toIso8601String(),
      'latitude'   : lat,
      'longitude'  : lng,
    }, onConflict: 'sesi_id,santri_id');
  }

  // ── Rekap Pribadi ─────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRekapAkademikSantri(String santriId) async {
    return await _c.from('v_rekap_absensi_akademik').select().eq('santri_id', santriId);
  }

  static Future<List<Map<String, dynamic>>> getRekapIbadahSantri(String santriId) async {
    return await _c.from('v_rekap_absensi_ibadah').select().eq('santri_id', santriId);
  }

  static Future<List<Map<String, dynamic>>> getSPSantri(String santriId, String semesterId) async {
    return await _c.from('surat_peringatan').select('''
      id, level, alasan, hukuman, status, tanggal_sp,
      pembina:pembina_id(profile:profile_id(nama_lengkap))
    ''').eq('santri_id', santriId).eq('semester_id', semesterId)
        .order('tanggal_sp', ascending: false);
  }

  // ── Tugas Santri ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getTugasSantri(String santriId) async {
    final kelasSantri = await _c.from('kelas_santri').select('kelas_id').eq('santri_id', santriId);
    if (kelasSantri.isEmpty) return [];
    final kelasIds = kelasSantri.map((k) => k['kelas_id']).toList();

    final tugas = await _c.from('tugas').select('''
      id, judul, deskripsi, file_soal_url, deadline, created_at,
      kelas:kelas_id(nama_kelas, mata_kuliah:mata_kuliah_id(nama))
    ''').inFilter('kelas_id', kelasIds).order('deadline');

    // Cek status pengumpulan
    final tugasIds = tugas.map((t) => t['id']).toList();
    final pengumpulan = tugasIds.isEmpty ? [] : await _c.from('pengumpulan_tugas')
        .select('tugas_id, nilai, waktu_kumpul').eq('santri_id', santriId)
        .inFilter('tugas_id', tugasIds);

    final pengumpulanMap = { for (var p in pengumpulan) p['tugas_id']: p };
    return tugas.map((t) => { ...t, 'pengumpulan': pengumpulanMap[t['id']] }).toList();
  }

  static Future<void> kumpulTugas({
    required String tugasId, required String santriId,
    required String fileJawabanUrl, required String? catatan,
  }) async {
    await _c.from('pengumpulan_tugas').upsert({
      'tugas_id'       : tugasId,
      'santri_id'      : santriId,
      'file_jawaban_url': fileJawabanUrl,
      'catatan_santri' : catatan,
      'waktu_kumpul'   : DateTime.now().toIso8601String(),
    }, onConflict: 'tugas_id,santri_id');
  }

  // ── Profil Santri ─────────────────────────────────────
  static Future<Map<String, dynamic>?> getProfilSantri(String santriId) async {
    return await _c.from('santri').select('''
      id, nim, angkatan, status,
      profile:profile_id(id, nama_lengkap, email, no_hp, alamat, gender, foto_url),
      semester_masuk:semester_masuk_id(nama, tahun_akademik:tahun_akademik_id(nama))
    ''').eq('id', santriId).maybeSingle();
  }

  static Future<void> updateProfilSantri(String profileId, Map<String, dynamic> data) async {
    // NIM tidak bisa diubah – hanya update profile fields
    final allowed = ['nama_lengkap', 'no_hp', 'alamat', 'gender'];
    final filtered = Map.fromEntries(data.entries.where((e) => allowed.contains(e.key)));
    if (filtered.isNotEmpty) {
      await _c.from('profiles').update(filtered).eq('id', profileId);
    }
  }

  // ── Pengumuman ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPengumumanUntukSantri(String profileId) async {
    return await _c.from('pengumuman').select('''
      id, judul, isi, target, created_at,
      dibuat_oleh_profile:dibuat_oleh(nama_lengkap)
    ''')
    .or('target.eq.all,target.eq.role,and(target.eq.role,target_role.eq.santri)')
    .order('created_at', ascending: false)
    .limit(30);
  }
}

// Private dummy class for extension grouping
class _Svc { _Svc._(); }
SupabaseClient get _c => Supabase.instance.client;
