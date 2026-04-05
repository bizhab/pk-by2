// lib/core/services/pdf_service.dart
// Generate PDF laporan absensi ibadah & akademik
//
// Tambahkan ke pubspec.yaml:
//   pdf: ^3.10.7
//   printing: ^5.12.0
//
// Kemudian uncomment import di bawah dan hapus bagian STUB.

// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfService {
  static SupabaseClient get _c => Supabase.instance.client;

  // ── Laporan Absensi Ibadah ─────────────────────────────
  static Future<void> cetakLaporanIbadah({
    required BuildContext context,
    required String kelompokId,
    required DateTime dari,
    required DateTime sampai,
    required String kategori,           // 'semua' | 'wajib' | 'sunnah'
    required String namaPembina,
    required String namaKelompok,
  }) async {
    // 1. Ambil data dari Supabase
    var query = _c.from('sesi_absensi_ibadah').select('''
      id, tanggal,
      jadwal_sholat:jadwal_sholat_id(nama_sholat, kategori),
      absensi_ibadah(
        status,
        santri:santri_id(nim, profile:profile_id(nama_lengkap))
      )
    ''')
    .eq('kelompok_pembina_id', kelompokId)
    .gte('tanggal', dari.toIso8601String().split('T').first)
    .lte('tanggal', sampai.toIso8601String().split('T').first)
    .order('tanggal');

    final sesiList = await query;

    // Filter kategori
    final filtered = kategori == 'semua'
        ? sesiList
        : sesiList.where((s) =>
            s['jadwal_sholat']?['kategori'] == kategori).toList();

    // 2. Bangun rekap per santri
    final Map<String, Map<String, dynamic>> rekap = {};
    for (final sesi in filtered) {
      final absensiList = sesi['absensi_ibadah'] as List? ?? [];
      final namaSholat  = sesi['jadwal_sholat']?['nama_sholat'] ?? '-';
      for (final ab in absensiList) {
        final s       = ab['santri'] as Map? ?? {};
        final p       = s['profile'] as Map? ?? {};
        final nama    = p['nama_lengkap'] ?? '-';
        final nim     = s['nim'] ?? '-';
        final status  = ab['status'] ?? 'alpha';
        rekap[nim] ??= {
          'nama': nama, 'nim': nim, 'hadir': 0, 'alpha': 0, 'izin': 0,
        };
        rekap[nim]![status] = (rekap[nim]![status] as int) + 1;
      }
    }

    // 3. STUB: Tampilkan preview data dulu
    // Ganti dengan kode PDF aktual setelah install package 'pdf' & 'printing'
    if (!context.mounted) return;
    _showPreviewDialog(context, rekap, namaPembina, namaKelompok, dari, sampai);

    // ── Kode PDF aktual (uncomment setelah install package) ──
    // final pdf = pw.Document();
    // pdf.addPage(pw.MultiPage(
    //   pageFormat: PdfPageFormat.a4,
    //   header: (pw.Context ctx) => pw.Column(
    //     crossAxisAlignment: pw.CrossAxisAlignment.start,
    //     children: [
    //       pw.Text('LAPORAN ABSENSI IBADAH', style: pw.TextStyle(
    //         fontSize: 18, fontWeight: pw.FontWeight.bold)),
    //       pw.Text('Kelompok: $namaKelompok | Pembina: $namaPembina'),
    //       pw.Text('Periode: ${dari.day}/${dari.month}/${dari.year} s/d '
    //               '${sampai.day}/${sampai.month}/${sampai.year}'),
    //       pw.Divider(),
    //     ],
    //   ),
    //   build: (pw.Context ctx) => [
    //     pw.Table.fromTextArray(
    //       headers: ['No', 'NIM', 'Nama', 'Hadir', 'Alpha', 'Izin', '%'],
    //       data: rekap.values.toList().asMap().entries.map((e) {
    //         final r = e.value;
    //         final total = (r['hadir'] as int) + (r['alpha'] as int) + (r['izin'] as int);
    //         final pct = total > 0 ? ((r['hadir'] as int) / total * 100).toStringAsFixed(1) : '0';
    //         return [e.key + 1, r['nim'], r['nama'], r['hadir'], r['alpha'], r['izin'], '$pct%'];
    //       }).toList(),
    //     ),
    //   ],
    // ));
    // await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ── Laporan Rekap Akademik ─────────────────────────────
  static Future<void> cetakRekapAkademik({
    required BuildContext context,
    required String kelasId,
    required String namaKelas,
    required String namaMatkul,
    required String namaDosen,
  }) async {
    final data = await _c.from('v_rekap_absensi_akademik')
        .select()
        .eq('kelas_id', kelasId);

    if (!context.mounted) return;

    // STUB
    _showPreviewRekap(context, data, namaKelas, namaMatkul, namaDosen);

    // ── Kode PDF aktual (uncomment setelah install package) ──
    // final pdf = pw.Document();
    // pdf.addPage(pw.Page(
    //   pageFormat: PdfPageFormat.a4.landscape,
    //   build: (ctx) => pw.Column(children: [
    //     pw.Header(text: 'Rekap Kehadiran — $namaMatkul Kelas $namaKelas'),
    //     pw.Table.fromTextArray(
    //       headers: ['NIM','Nama','Hadir','Izin','Sakit','Terlambat','Alpha','%'],
    //       data: data.map((r) => [
    //         r['nim'] ?? '-',
    //         r['nama_santri'] ?? '-',
    //         r['hadir'] ?? 0,
    //         r['izin'] ?? 0,
    //         r['sakit'] ?? 0,
    //         r['terlambat'] ?? 0,
    //         r['alpha'] ?? 0,
    //         '${r['persentase_hadir'] ?? 0}%',
    //       ]).toList(),
    //     ),
    //   ]),
    // ));
    // await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ── STUB Preview Dialog ────────────────────────────────
  static void _showPreviewDialog(
    BuildContext ctx,
    Map<String, Map<String, dynamic>> rekap,
    String namaPembina, String namaKelompok,
    DateTime dari, DateTime sampai,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Preview Data Laporan',
          style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 500, height: 300,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kelompok: $namaKelompok | Pembina: $namaPembina'),
            Text('Periode: ${dari.day}/${dari.month}/${dari.year} — '
                '${sampai.day}/${sampai.month}/${sampai.year}'),
            const SizedBox(height: 12),
            Expanded(child: ListView.separated(
              itemCount: rekap.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = rekap.values.toList()[i];
                final total = (r['hadir'] as int) + (r['alpha'] as int) + (r['izin'] as int);
                final pct = total > 0 ? (r['hadir'] as int) / total * 100 : 0.0;
                return ListTile(
                  dense: true,
                  title: Text(r['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('NIM: ${r['nim']}'),
                  trailing: Text(
                    '✅${r['hadir']} ❌${r['alpha']} 📝${r['izin']} | ${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12)),
                );
              },
            )),
            const SizedBox(height: 12),
            const Text(
              '💡 Tambahkan package "pdf" & "printing" di pubspec.yaml\n'
              '   untuk mengaktifkan ekspor PDF sesungguhnya.',
              style: TextStyle(fontSize: 11, color: Colors.orange)),
          ]),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup')),
        ],
      ),
    );
  }

  static void _showPreviewRekap(
    BuildContext ctx,
    List<Map<String, dynamic>> data,
    String namaKelas, String namaMatkul, String namaDosen,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rekap — $namaMatkul Kelas $namaKelas',
          style: const TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 560, height: 320,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dosen: $namaDosen'),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(columns: const [
                DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Hadir')),
                DataColumn(label: Text('Izin')),
                DataColumn(label: Text('Sakit')),
                DataColumn(label: Text('Alpha')),
                DataColumn(label: Text('%')),
              ], rows: data.map((r) => DataRow(cells: [
                DataCell(Text(r['nama_santri'] ?? '-')),
                DataCell(Text('${r['hadir'] ?? 0}')),
                DataCell(Text('${r['izin'] ?? 0}')),
                DataCell(Text('${r['sakit'] ?? 0}')),
                DataCell(Text('${r['alpha'] ?? 0}')),
                DataCell(Text('${r['persentase_hadir'] ?? 0}%')),
              ])).toList()),
            )),
            const SizedBox(height: 12),
            const Text(
              '💡 Aktifkan PDF dengan package "pdf" & "printing".',
              style: TextStyle(fontSize: 11, color: Colors.orange)),
          ]),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
