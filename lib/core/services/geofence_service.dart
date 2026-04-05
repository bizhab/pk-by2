// lib/core/services/geofence_service.dart
// Validasi apakah user berada dalam radius geofence sebelum absen
// Gunakan package: geolocator (tambahkan ke pubspec.yaml)

import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeofenceService {
  static SupabaseClient get _c => Supabase.instance.client;

  /// Hitung jarak antara dua titik koordinat (meter)
  /// Menggunakan formula Haversine
  static double hitungJarak({
    required double lat1, required double lng1,
    required double lat2, required double lng2,
  }) {
    const R = 6371000.0; // radius bumi dalam meter
    final phi1  = lat1 * pi / 180;
    final phi2  = lat2 * pi / 180;
    final dPhi  = (lat2 - lat1) * pi / 180;
    final dLam  = (lng2 - lng1) * pi / 180;

    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLam / 2) * sin(dLam / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Cek apakah koordinat user berada dalam radius geofence aktif
  /// Returns: GeofenceResult
  static Future<GeofenceResult> cekRadius({
    required double userLat,
    required double userLng,
    String? geofenceId,
  }) async {
    try {
      Map<String, dynamic>? geofence;

      if (geofenceId != null) {
        geofence = await _c.from('geofence_setting')
            .select('id, nama, latitude, longitude, radius_meter')
            .eq('id', geofenceId)
            .single();
      } else {
        geofence = await _c.from('geofence_setting')
            .select('id, nama, latitude, longitude, radius_meter')
            .eq('is_aktif', true)
            .maybeSingle();
      }

      if (geofence == null) {
        // Jika tidak ada geofence, izinkan absen (mode bebas)
        return GeofenceResult(
          diIzinkan: true,
          jarak: 0,
          radius: 0,
          pesan: 'Tidak ada geofence aktif — absen diizinkan.',
        );
      }

      final jarak = hitungJarak(
        lat1: userLat, lng1: userLng,
        lat2: geofence['latitude'] as double,
        lng2: geofence['longitude'] as double,
      );
      final radius = (geofence['radius_meter'] as int).toDouble();
      final diIzinkan = jarak <= radius;

      return GeofenceResult(
        diIzinkan: diIzinkan,
        jarak: jarak,
        radius: radius,
        namaLokasi: geofence['nama'],
        pesan: diIzinkan
            ? 'Anda berada dalam radius ${radius.toInt()}m. Absen diizinkan.'
            : 'Anda berada ${jarak.toStringAsFixed(0)}m dari lokasi. '
              'Batas radius: ${radius.toInt()}m.',
      );
    } catch (e) {
      return GeofenceResult(
        diIzinkan: false,
        jarak: -1,
        radius: -1,
        pesan: 'Gagal memvalidasi lokasi: $e',
      );
    }
  }
}

class GeofenceResult {
  final bool   diIzinkan;
  final double jarak;
  final double radius;
  final String? namaLokasi;
  final String pesan;

  const GeofenceResult({
    required this.diIzinkan,
    required this.jarak,
    required this.radius,
    required this.pesan,
    this.namaLokasi,
  });

  String get jarakDisplay => jarak < 0
      ? '-'
      : jarak < 1000
          ? '${jarak.toStringAsFixed(0)} m'
          : '${(jarak / 1000).toStringAsFixed(2)} km';
}

// ── Widget: Geofence Status Indicator ─────────────────────
// Gunakan di halaman absensi santri untuk menampilkan status lokasi
//
// Contoh penggunaan:
//
//   GeofenceStatusWidget(
//     userLat: _currentLat,
//     userLng: _currentLng,
//     onValid: () => setState(() => _bisaAbsen = true),
//   )
