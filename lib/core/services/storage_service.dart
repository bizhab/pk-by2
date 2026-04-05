// lib/core/services/storage_service.dart
// Upload file ke Supabase Storage (materi, bukti, foto profil, tugas)
// Bucket yang dibutuhkan (buat di Supabase Dashboard → Storage):
//   - materi      (public)
//   - bukti       (private, hanya bisa diakses lewat signed URL)
//   - tugas       (private)
//   - avatar      (public)

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static SupabaseClient get _c => Supabase.instance.client;

  // ── Generate nama file unik ────────────────────────────
  static String _uniqueName(String ext) {
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    final ts   = DateTime.now().millisecondsSinceEpoch;
    return '${ts}_$rand.$ext';
  }

  static String _ext(String path) =>
      path.contains('.') ? path.split('.').last.toLowerCase() : 'bin';

  // ── Upload file materi kuliah (public) ─────────────────
  // Returns: public URL
  static Future<String> uploadMateri({
    required dynamic fileBytes,       // Uint8List (web) atau File path (mobile)
    required String originalName,
    required String dosenId,
    required String kelasId,
  }) async {
    final ext  = _ext(originalName);
    final path = 'dosen/$dosenId/kelas/$kelasId/${_uniqueName(ext)}';

    if (kIsWeb) {
      await _c.storage.from('materi').uploadBinary(
        path, fileBytes,
        fileOptions: FileOptions(contentType: _contentType(ext)),
      );
    } else {
      await _c.storage.from('materi').upload(
        path, File(fileBytes),
        fileOptions: FileOptions(contentType: _contentType(ext)),
      );
    }
    return _c.storage.from('materi').getPublicUrl(path);
  }

  // ── Upload bukti izin/sakit (private → signed URL) ─────
  // Returns: signed URL (berlaku 7 hari)
  static Future<String> uploadBukti({
    required dynamic fileBytes,
    required String originalName,
    required String santriId,
  }) async {
    final ext  = _ext(originalName);
    final path = 'santri/$santriId/bukti/${_uniqueName(ext)}';

    if (kIsWeb) {
      await _c.storage.from('bukti').uploadBinary(
        path, fileBytes,
        fileOptions: FileOptions(contentType: _contentType(ext)),
      );
    } else {
      await _c.storage.from('bukti').upload(
        path, File(fileBytes),
        fileOptions: FileOptions(contentType: _contentType(ext)),
      );
    }
    // Buat signed URL berlaku 7 hari
    return await _c.storage.from('bukti').createSignedUrl(
      path, 60 * 60 * 24 * 7,
    );
  }

  // ── Upload jawaban tugas (private) ─────────────────────
  static Future<String> uploadJawabanTugas({
    required dynamic fileBytes,
    required String originalName,
    required String santriId,
    required String tugasId,
  }) async {
    final ext  = _ext(originalName);
    final path = 'santri/$santriId/tugas/$tugasId/${_uniqueName(ext)}';

    if (kIsWeb) {
      await _c.storage.from('tugas').uploadBinary(
        path, fileBytes,
        fileOptions: FileOptions(contentType: _contentType(ext)),
      );
    } else {
      await _c.storage.from('tugas').upload(
        path, File(fileBytes),
        fileOptions: FileOptions(contentType: _contentType(ext)),
      );
    }
    return await _c.storage.from('tugas').createSignedUrl(
      path, 60 * 60 * 24 * 30, // 30 hari
    );
  }

  // ── Upload foto profil (public) ────────────────────────
  static Future<String> uploadAvatar({
    required dynamic fileBytes,
    required String profileId,
  }) async {
    final path = 'profiles/$profileId/avatar.jpg';

    if (kIsWeb) {
      await _c.storage.from('avatar').uploadBinary(
        path, fileBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
    } else {
      await _c.storage.from('avatar').upload(
        path, File(fileBytes),
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
    }
    return _c.storage.from('avatar').getPublicUrl(path);
  }

  // ── Delete file ────────────────────────────────────────
  static Future<void> deleteFile(String bucket, String path) async {
    await _c.storage.from(bucket).remove([path]);
  }

  // ── Helper: content type ───────────────────────────────
  static String _contentType(String ext) {
    switch (ext) {
      case 'pdf' : return 'application/pdf';
      case 'doc' : return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt' : return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls' : return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg' :
      case 'jpeg': return 'image/jpeg';
      case 'png' : return 'image/png';
      case 'gif' : return 'image/gif';
      case 'mp4' : return 'video/mp4';
      case 'zip' : return 'application/zip';
      default    : return 'application/octet-stream';
    }
  }
}
