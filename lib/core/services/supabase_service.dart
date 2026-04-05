import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ─── AUTH ───────────────────────────────────────────────
  static Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email, password: password);
  static Future<void> signOut() => client.auth.signOut();
  static User? get currentUser => client.auth.currentUser;

  static Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    return await client.from('profiles').select().eq('id', uid).single();
  }

  // ─── DASHBOARD ─────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final results = await Future.wait([
      client.from('santri').select('id').count(CountOption.exact),
      client.from('dosen').select('id').count(CountOption.exact),
      client.from('pembina').select('id').count(CountOption.exact),
      client.from('surat_peringatan').select('id').eq('status', 'aktif').count(CountOption.exact),
    ]);
    return {
      'total_santri': results[0].count, 'total_dosen': results[1].count,
      'total_pembina': results[2].count, 'total_sp_aktif': results[3].count,
    };
  }

  static Future<List<Map<String, dynamic>>> getRecentSP({int limit = 5}) async =>
      await client.from('surat_peringatan').select('''
        id, level, alasan, tanggal_sp, status,
        santri:santri_id(profile:profile_id(nama_lengkap)),
        pembina:pembina_id(profile:profile_id(nama_lengkap))
      ''').order('created_at', ascending: false).limit(limit);

  static Future<List<Map<String, dynamic>>> getRecentAbsensiAkademik({int limit = 5}) async =>
      await client.from('sesi_absensi_akademik').select('''
        id, tanggal, jam_buka, jam_tutup,
        kelas:kelas_id(nama_kelas, mata_kuliah:mata_kuliah_id(nama))
      ''').order('created_at', ascending: false).limit(limit);

  // ─── SANTRI ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllSantri() async =>
      await client.from('santri').select('''
        id, nim, angkatan, status,
        profile:profile_id(id, nama_lengkap, email, no_hp, gender, foto_url),
        semester_masuk:semester_masuk_id(nama, tahun_akademik:tahun_akademik_id(nama))
      ''').order('nim');

  static Future<Map<String, dynamic>?> getSantriByProfileId(String profileId) async =>
      await client.from('santri').select('''
        id, nim, angkatan, status,
        profile:profile_id(id, nama_lengkap, email, no_hp, alamat, gender, foto_url)
      ''').eq('profile_id', profileId).maybeSingle();

  static Future<void> createSantri({
    required String email, required String password, required String namaLengkap,
    required String nim, required String? noHp, required String? gender,
    required int? angkatan, required String? semesterMasukId,
  }) async {
    final authRes = await client.auth.admin.createUser(
        AdminUserAttributes(email: email, password: password, emailConfirm: true));
    final uid = authRes.user!.id;
    await client.from('profiles').insert({'id': uid, 'role': 'santri',
      'nama_lengkap': namaLengkap, 'email': email, 'no_hp': noHp, 'gender': gender});
    await client.from('santri').insert({'profile_id': uid, 'nim': nim,
      'angkatan': angkatan, 'semester_masuk_id': semesterMasukId});
  }

  static Future<void> updateSantri(String santriId,
      Map<String, dynamic> profileData, Map<String, dynamic> santriData) async {
    final s = await client.from('santri').select('profile_id').eq('id', santriId).single();
    if (profileData.isNotEmpty) await client.from('profiles').update(profileData).eq('id', s['profile_id']);
    if (santriData.isNotEmpty) await client.from('santri').update(santriData).eq('id', santriId);
  }

  static Future<void> deleteSantri(String profileId) async =>
      await client.auth.admin.deleteUser(profileId);

  static Future<Map<String, dynamic>> getRaporSantri(String santriId) async {
    final results = await Future.wait([
      client.from('v_rekap_absensi_akademik').select().eq('santri_id', santriId),
      client.from('surat_peringatan').select().eq('santri_id', santriId).eq('status', 'aktif'),
      client.from('v_rekap_absensi_ibadah').select().eq('santri_id', santriId),
    ]);
    return {'absensi_akademik': results[0], 'sp_aktif': results[1], 'absensi_ibadah': results[2]};
  }

  static Future<List<Map<String, dynamic>>> getKelasForSantri(String santriId) async =>
      await client.from('kelas_santri').select('''
        id, kelas:kelas_id(
          id, nama_kelas, ruangan, hari, jam_mulai, jam_selesai,
          mata_kuliah:mata_kuliah_id(nama, kode, sks),
          dosen:dosen_id(profile:profile_id(nama_lengkap))
        )
      ''').eq('santri_id', santriId);

  static Future<List<Map<String, dynamic>>> getSesiTerbukaForSantri(String santriId) async {
    final kelasRes = await client.from('kelas_santri').select('kelas_id').eq('santri_id', santriId);
    final ids = kelasRes.map<String>((r) => r['kelas_id'].toString()).toList();
    if (ids.isEmpty) return [];
    return await client.from('sesi_absensi_akademik').select('''
      id, tanggal, jam_buka, kode_absen,
      kelas:kelas_id(nama_kelas, mata_kuliah:mata_kuliah_id(nama))
    ''').isFilter('jam_tutup', null).inFilter('kelas_id', ids);
  }

  static Future<List<Map<String, dynamic>>> getAbsensiAkademiSantri(String santriId) async =>
      await client.from('absensi_akademik').select('''
        id, status, waktu_absen,
        sesi:sesi_id(tanggal, kelas:kelas_id(nama_kelas, mata_kuliah:mata_kuliah_id(nama)))
      ''').eq('santri_id', santriId).order('created_at', ascending: false).limit(30);

  static Future<void> absenAkademik({
    required String sesiId, required String santriId,
    required String status, required double? lat, required double? lng,
  }) async {
    await client.from('absensi_akademik').upsert({
      'sesi_id': sesiId, 'santri_id': santriId, 'status': status,
      'waktu_absen': DateTime.now().toIso8601String(), 'latitude': lat, 'longitude': lng,
    }, onConflict: 'sesi_id,santri_id');
  }

  static Future<List<Map<String, dynamic>>> getTugasForSantri(String santriId) async {
    final kelasRes = await client.from('kelas_santri').select('kelas_id').eq('santri_id', santriId);
    final ids = kelasRes.map<String>((r) => r['kelas_id'].toString()).toList();
    if (ids.isEmpty) return [];
    return await client.from('tugas').select('''
      id, judul, deskripsi, deadline, file_soal_url, created_at,
      kelas:kelas_id(nama_kelas, mata_kuliah:mata_kuliah_id(nama)),
      pengumpulan_tugas(id)
    ''').inFilter('kelas_id', ids).order('deadline');
  }

  static Future<void> kumpulkanTugas({
    required String tugasId, required String santriId,
    required String fileUrl, required String? catatan,
  }) async {
    await client.from('pengumpulan_tugas').upsert({
      'tugas_id': tugasId, 'santri_id': santriId,
      'file_jawaban_url': fileUrl, 'catatan_santri': catatan,
      'waktu_kumpul': DateTime.now().toIso8601String(),
    }, onConflict: 'tugas_id,santri_id');
  }

  // ─── DOSEN ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllDosen() async =>
      await client.from('dosen').select('''
        id, nip, bidang_studi,
        profile:profile_id(id, nama_lengkap, email, no_hp, gender, foto_url)
      ''').order('nip');

  static Future<Map<String, dynamic>?> getDosenByProfileId(String profileId) async =>
      await client.from('dosen').select('id, nip, bidang_studi').eq('profile_id', profileId).maybeSingle();

  static Future<void> createDosen({
    required String email, required String password, required String namaLengkap,
    required String nip, required String? bidangStudi, required String? noHp, required String? gender,
  }) async {
    final authRes = await client.auth.admin.createUser(
        AdminUserAttributes(email: email, password: password, emailConfirm: true));
    final uid = authRes.user!.id;
    await client.from('profiles').insert({'id': uid, 'role': 'dosen',
      'nama_lengkap': namaLengkap, 'email': email, 'no_hp': noHp, 'gender': gender});
    await client.from('dosen').insert({'profile_id': uid, 'nip': nip, 'bidang_studi': bidangStudi});
  }

  static Future<void> deleteDosen(String profileId) async =>
      await client.auth.admin.deleteUser(profileId);

  static Future<List<Map<String, dynamic>>> getKelasByDosen(String dosenId) async =>
      await client.from('kelas').select('''
        id, nama_kelas, ruangan, hari, jam_mulai, jam_selesai,
        mata_kuliah:mata_kuliah_id(id, nama, kode, sks), kelas_santri(id)
      ''').eq('dosen_id', dosenId).order('nama_kelas');

  static Future<List<Map<String, dynamic>>> getSesiByDosen(String dosenId) async {
    final kelasIds = await client.from('kelas').select('id').eq('dosen_id', dosenId);
    final ids = kelasIds.map<String>((k) => k['id'].toString()).toList();
    if (ids.isEmpty) return [];
    return await client.from('sesi_absensi_akademik').select('''
      id, tanggal, jam_buka, jam_tutup, kode_absen,
      kelas:kelas_id(nama_kelas, mata_kuliah:mata_kuliah_id(nama))
    ''').inFilter('kelas_id', ids).order('tanggal', ascending: false);
  }

  static Future<String> bukaSesiAbsensi(String kelasId, String geofenceId) async {
    final kode = ((DateTime.now().millisecondsSinceEpoch % 900000) + 100000).toString();
    final res = await client.from('sesi_absensi_akademik').insert({
      'kelas_id': kelasId, 'tanggal': DateTime.now().toIso8601String().split('T').first,
      'jam_buka': DateTime.now().toIso8601String(), 'kode_absen': kode,
      'geofence_id': geofenceId, 'dibuka_oleh': currentUser?.id,
    }).select('id').single();
    final santriList = await client.from('kelas_santri').select('santri_id').eq('kelas_id', kelasId);
    if (santriList.isNotEmpty) {
      await client.from('absensi_akademik').insert(santriList.map((s) =>
          {'sesi_id': res['id'], 'santri_id': s['santri_id'], 'status': 'alpha'}).toList());
    }
    return res['id'];
  }

  static Future<void> tutupSesiAbsensi(String sesiId) async =>
      await client.from('sesi_absensi_akademik').update(
          {'jam_tutup': DateTime.now().toIso8601String()}).eq('id', sesiId);

  static Future<List<Map<String, dynamic>>> getAbsensiDetailBySesi(String sesiId) async =>
      await client.from('absensi_akademik').select('''
        id, status, waktu_absen, catatan,
        santri:santri_id(id, nim, profile:profile_id(nama_lengkap))
      ''').eq('sesi_id', sesiId).order('status');

  static Future<void> editStatusAbsensi(String id, String status, String? catatan) async =>
      await client.from('absensi_akademik').update({
        'status': status, 'catatan': catatan,
        'diubah_oleh': currentUser?.id, 'diubah_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

  static Future<List<Map<String, dynamic>>> getMateriByKelas(String kelasId) async =>
      await client.from('materi_kuliah').select('''
        id, judul, deskripsi, file_url, tipe_file, created_at,
        diunggah_oleh_profile:diunggah_oleh(nama_lengkap)
      ''').eq('kelas_id', kelasId).order('created_at', ascending: false);

  static Future<void> uploadMateri({required String kelasId, required String judul,
      required String? deskripsi, required String fileUrl, required String? tipeFile}) async =>
      await client.from('materi_kuliah').insert({'kelas_id': kelasId, 'judul': judul,
        'deskripsi': deskripsi, 'file_url': fileUrl, 'tipe_file': tipeFile,
        'diunggah_oleh': currentUser?.id});

  static Future<void> deleteMateri(String id) async =>
      await client.from('materi_kuliah').delete().eq('id', id);

  static Future<List<Map<String, dynamic>>> getTugasByKelas(String kelasId) async =>
      await client.from('tugas').select('''
        id, judul, deskripsi, deadline, file_soal_url, created_at,
        pengumpulan_tugas(id)
      ''').eq('kelas_id', kelasId).order('deadline');

  static Future<void> createTugas({required String kelasId, required String judul,
      required String? deskripsi, required String deadline, required String? fileSoalUrl}) async =>
      await client.from('tugas').insert({'kelas_id': kelasId, 'judul': judul,
        'deskripsi': deskripsi, 'deadline': deadline, 'file_soal_url': fileSoalUrl,
        'dibuat_oleh': currentUser?.id});

  static Future<void> deleteTugas(String id) async =>
      await client.from('tugas').delete().eq('id', id);

  static Future<List<Map<String, dynamic>>> getPengumpulanByTugas(String tugasId) async =>
      await client.from('pengumpulan_tugas').select('''
        id, file_jawaban_url, catatan_santri, waktu_kumpul, nilai, catatan_dosen,
        santri:santri_id(nim, profile:profile_id(nama_lengkap))
      ''').eq('tugas_id', tugasId).order('waktu_kumpul');

  static Future<void> beriNilai(String id, double nilai, String? catatan) async =>
      await client.from('pengumpulan_tugas').update({'nilai': nilai, 'catatan_dosen': catatan}).eq('id', id);

  static Future<List<Map<String, dynamic>>> getRekapAbsensiAkademik(String kelasId) async =>
      await client.from('v_rekap_absensi_akademik').select().eq('kelas_id', kelasId);

  // ─── PEMBINA ────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllPembina() async =>
      await client.from('pembina').select('''
        id, kode_pembina,
        profile:profile_id(id, nama_lengkap, email, no_hp, gender, foto_url)
      ''').order('kode_pembina');

  static Future<Map<String, dynamic>?> getPembinaByProfileId(String profileId) async =>
      await client.from('pembina').select('id, kode_pembina').eq('profile_id', profileId).maybeSingle();

  static Future<void> createPembina({required String email, required String password,
      required String namaLengkap, required String kodePembina,
      required String? noHp, required String? gender}) async {
    final authRes = await client.auth.admin.createUser(
        AdminUserAttributes(email: email, password: password, emailConfirm: true));
    final uid = authRes.user!.id;
    await client.from('profiles').insert({'id': uid, 'role': 'pembina',
      'nama_lengkap': namaLengkap, 'email': email, 'no_hp': noHp, 'gender': gender});
    await client.from('pembina').insert({'profile_id': uid, 'kode_pembina': kodePembina});
  }

  static Future<void> deletePembina(String profileId) async =>
      await client.auth.admin.deleteUser(profileId);

  static Future<Map<String, dynamic>?> getKelompokByPembina(String pembinaId, String semesterId) async =>
      await client.from('kelompok_pembina').select('''
        id, nama_kelompok,
        kelompok_santri(id, santri:santri_id(id, nim, profile:profile_id(id, nama_lengkap, email, no_hp)))
      ''').eq('pembina_id', pembinaId).eq('semester_id', semesterId).maybeSingle();

  static Future<List<Map<String, dynamic>>> getJadwalSholat() async =>
      await client.from('jadwal_sholat').select().eq('is_aktif', true).order('jam_mulai');

  static Future<void> createJadwalSholat({required String namaSholat, required String kategori,
      required String jamMulai, required String jamSelesai}) async =>
      await client.from('jadwal_sholat').insert({'nama_sholat': namaSholat, 'kategori': kategori,
        'jam_mulai': jamMulai, 'jam_selesai': jamSelesai});

  static Future<void> deleteJadwalSholat(String id) async =>
      await client.from('jadwal_sholat').update({'is_aktif': false}).eq('id', id);

  static Future<List<Map<String, dynamic>>> getSesiIbadahByKelompok(String kelompokId,
      {String? tanggal}) async {
    var q = client.from('sesi_absensi_ibadah').select('''
      id, tanggal, jam_buka, jam_tutup,
      jadwal_sholat:jadwal_sholat_id(nama_sholat, kategori, jam_mulai)
    ''').eq('kelompok_pembina_id', kelompokId);
    if (tanggal != null) q = q.eq('tanggal', tanggal);
    return await q.order('tanggal', ascending: false).limit(50);
  }

  static Future<String> bukaSesiIbadah({required String kelompokId, required String jadwalSholatId,
      required String geofenceId}) async {
    final res = await client.from('sesi_absensi_ibadah').insert({
      'kelompok_pembina_id': kelompokId, 'jadwal_sholat_id': jadwalSholatId,
      'tanggal': DateTime.now().toIso8601String().split('T').first,
      'jam_buka': DateTime.now().toIso8601String(),
      'geofence_id': geofenceId, 'dibuka_oleh': currentUser?.id,
    }).select('id').single();
    final santri = await client.from('kelompok_santri').select('santri_id').eq('kelompok_pembina_id', kelompokId);
    if (santri.isNotEmpty) {
      await client.from('absensi_ibadah').insert(santri.map((s) =>
          {'sesi_id': res['id'], 'santri_id': s['santri_id'], 'status': 'alpha'}).toList());
    }
    return res['id'];
  }

  static Future<void> tutupSesiIbadah(String sesiId) async =>
      await client.from('sesi_absensi_ibadah').update({'jam_tutup': DateTime.now().toIso8601String()}).eq('id', sesiId);

  static Future<List<Map<String, dynamic>>> getAbsensiIbadahBySesi(String sesiId) async =>
      await client.from('absensi_ibadah').select('''
        id, status, waktu_absen,
        santri:santri_id(id, nim, profile:profile_id(nama_lengkap))
      ''').eq('sesi_id', sesiId);

  static Future<void> updateStatusAbsensiIbadah(String absensiId, String status) async =>
      await client.from('absensi_ibadah').update({'status': status}).eq('id', absensiId);

  static Future<List<Map<String, dynamic>>> getSPByKelompok(String kelompokId) async {
    final ids = (await client.from('kelompok_santri').select('santri_id').eq('kelompok_pembina_id', kelompokId))
        .map<String>((s) => s['santri_id'].toString()).toList();
    if (ids.isEmpty) return [];
    return await client.from('surat_peringatan').select('''
      id, level, alasan, hukuman, tanggal_sp, status,
      santri:santri_id(nim, profile:profile_id(nama_lengkap))
    ''').inFilter('santri_id', ids).order('tanggal_sp', ascending: false);
  }

  static Future<void> buatSP({required String santriId, required String pembinaId,
      required String semesterId, required String level, required String alasan,
      required String? hukuman, String? referensiAbsensiId}) async =>
      await client.from('surat_peringatan').insert({'santri_id': santriId, 'pembina_id': pembinaId,
        'semester_id': semesterId, 'level': level, 'alasan': alasan, 'hukuman': hukuman,
        'referensi_absensi_ibadah': referensiAbsensiId,
        'tanggal_sp': DateTime.now().toIso8601String().split('T').first});

  static Future<void> updateStatusSP(String id, String status) async =>
      await client.from('surat_peringatan').update({'status': status}).eq('id', id);

  static Future<void> sendBroadcastPembina({required String kelompokId,
      required String judul, required String isi}) async =>
      await client.from('pengumuman').insert({'judul': judul, 'isi': isi,
        'target': 'kelompok_pembina', 'target_kelompok_id': kelompokId,
        'dibuat_oleh': currentUser?.id, 'is_push': true});

  // ─── KELOMPOK ───────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getKelompokPembina(String semesterId) async =>
      await client.from('kelompok_pembina').select('''
        id, nama_kelompok,
        pembina:pembina_id(id, kode_pembina, profile:profile_id(nama_lengkap)),
        kelompok_santri(id, santri:santri_id(id, nim, profile:profile_id(nama_lengkap)))
      ''').eq('semester_id', semesterId);

  static Future<void> createKelompok({required String pembinaId,
      required String semesterId, required String namaKelompok}) async =>
      await client.from('kelompok_pembina').insert({'pembina_id': pembinaId,
        'semester_id': semesterId, 'nama_kelompok': namaKelompok});

  static Future<void> addSantriToKelompok(String kelompokId, String santriId) async =>
      await client.from('kelompok_santri').insert({'kelompok_pembina_id': kelompokId, 'santri_id': santriId});

  static Future<void> removeSantriFromKelompok(String id) async =>
      await client.from('kelompok_santri').delete().eq('id', id);

  // ─── KELAS ──────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllKelas(String semesterId) async =>
      await client.from('kelas').select('''
        id, nama_kelas, ruangan, hari, jam_mulai, jam_selesai,
        mata_kuliah:mata_kuliah_id(id, nama, kode, sks),
        dosen:dosen_id(id, nip, profile:profile_id(nama_lengkap)), kelas_santri(id)
      ''').eq('semester_id', semesterId).order('nama_kelas');

  static Future<List<Map<String, dynamic>>> getAllMataKuliah() async =>
      await client.from('mata_kuliah').select().order('nama');

  static Future<void> createMataKuliah({required String kode, required String nama, required int sks}) async =>
      await client.from('mata_kuliah').insert({'kode': kode, 'nama': nama, 'sks': sks});

  static Future<void> createKelas({required String mataKuliahId, required String semesterId,
      required String dosenId, required String namaKelas, required String ruangan,
      required String hari, required String jamMulai, required String jamSelesai}) async =>
      await client.from('kelas').insert({'mata_kuliah_id': mataKuliahId, 'semester_id': semesterId,
        'dosen_id': dosenId, 'nama_kelas': namaKelas, 'ruangan': ruangan,
        'hari': hari, 'jam_mulai': jamMulai, 'jam_selesai': jamSelesai});

  static Future<void> addSantriToKelas(String kelasId, String santriId) async =>
      await client.from('kelas_santri').insert({'kelas_id': kelasId, 'santri_id': santriId});

  static Future<List<Map<String, dynamic>>> getSantriInKelas(String kelasId) async =>
      await client.from('kelas_santri').select('''
        id, santri:santri_id(id, nim, profile:profile_id(nama_lengkap))
      ''').eq('kelas_id', kelasId);

  // ─── SEMESTER ───────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllSemester() async =>
      await client.from('semester').select('''
        id, nama, tanggal_mulai, tanggal_selesai, is_aktif,
        tahun_akademik:tahun_akademik_id(id, nama, is_aktif)
      ''').order('tanggal_mulai', ascending: false);

  static Future<Map<String, dynamic>?> getActiveSemester() async =>
      await client.from('semester').select('''
        id, nama, tanggal_mulai, tanggal_selesai, tahun_akademik:tahun_akademik_id(nama)
      ''').eq('is_aktif', true).maybeSingle();

  static Future<void> createTahunAkademik(String nama) async =>
      await client.from('tahun_akademik').upsert({'nama': nama}, onConflict: 'nama');

  static Future<void> createSemester({required String tahunAkademikId, required String nama,
      required String tanggalMulai, required String tanggalSelesai}) async =>
      await client.from('semester').insert({'tahun_akademik_id': tahunAkademikId, 'nama': nama,
        'tanggal_mulai': tanggalMulai, 'tanggal_selesai': tanggalSelesai});

  static Future<void> setActiveSemester(String semesterId) async {
    await client.from('semester').update({'is_aktif': false});
    await client.from('semester').update({'is_aktif': true}).eq('id', semesterId);
    final sem = await client.from('semester').select('tahun_akademik_id').eq('id', semesterId).single();
    await client.from('tahun_akademik').update({'is_aktif': false});
    await client.from('tahun_akademik').update({'is_aktif': true}).eq('id', sem['tahun_akademik_id']);
  }

  // ─── GEOFENCE ───────────────────────────────────────────
  static Future<Map<String, dynamic>?> getActiveGeofence() async =>
      await client.from('geofence_setting').select().eq('is_aktif', true).maybeSingle();

  static Future<void> updateGeofence({required String id, required double lat,
      required double lng, required int radius}) async =>
      await client.from('geofence_setting').update({'latitude': lat, 'longitude': lng,
        'radius_meter': radius, 'updated_by': currentUser?.id,
        'updated_at': DateTime.now().toIso8601String()}).eq('id', id);

  static Future<void> createGeofence({required String nama, required double lat,
      required double lng, required int radius}) async =>
      await client.from('geofence_setting').insert({'nama': nama, 'latitude': lat,
        'longitude': lng, 'radius_meter': radius, 'updated_by': currentUser?.id});

  // ─── PENGUMUMAN ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllPengumuman() async =>
      await client.from('pengumuman').select('''
        id, judul, isi, target, target_role, is_push, created_at,
        dibuat_oleh_profile:dibuat_oleh(nama_lengkap)
      ''').order('created_at', ascending: false);

  static Future<void> createPengumuman({required String judul, required String isi,
      required String target, String? targetRole, bool isPush = true}) async =>
      await client.from('pengumuman').insert({'judul': judul, 'isi': isi, 'target': target,
        'target_role': targetRole, 'is_push': isPush, 'dibuat_oleh': currentUser?.id});

  static Future<void> deletePengumuman(String id) async =>
      await client.from('pengumuman').delete().eq('id', id);

  // ─── BUKTI UPLOAD ────────────────────────────────────────
  static Future<void> submitBuktiIzin({required String santriId, required String jenis,
      required String referensiId, required String fileUrl, required String? keterangan}) async =>
      await client.from('bukti_upload').insert({'santri_id': santriId, 'jenis': jenis,
        'referensi_id': referensiId, 'file_url': fileUrl, 'keterangan': keterangan});

  static Future<void> verifikasiBukti(String id, String status) async =>
      await client.from('bukti_upload').update({'status_verifikasi': status,
        'diverifikasi_oleh': currentUser?.id,
        'diverifikasi_at': DateTime.now().toIso8601String()}).eq('id', id);
}
