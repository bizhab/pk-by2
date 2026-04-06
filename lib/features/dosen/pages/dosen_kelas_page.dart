import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/widgets.dart';

class DosenKelasPage extends StatefulWidget {
  final String dosenId;
  final String semesterId;

  const DosenKelasPage({
    super.key,
    required this.dosenId,
    required this.semesterId,
  });

  @override
  State<DosenKelasPage> createState() => _DosenKelasPageState();
}

class _DosenKelasPageState extends State<DosenKelasPage> {
  List<Map<String, dynamic>> _kelas = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (widget.semesterId.isEmpty) { setState(() => _loading = false); return; }
    final data = await SupabaseService.getAllKelas(widget.semesterId);
    setState(() {
      _kelas = data.where((k) => k['dosen']?['id'] == widget.dosenId).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Kelas Saya', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: isMobile ? 22 : 26
          )),
          Text('${_kelas.length} kelas diampu semester ini',
            style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E6B8A)))
              : _kelas.isEmpty
                  ? const EmptyState(icon: Icons.class_outlined,
                      message: 'Belum ditugaskan ke kelas apapun')
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 1 : (screenWidth < 900 ? 2 : 3), // RESPONSIVE GRID
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16, 
                        childAspectRatio: isMobile ? 2.0 : 1.5,
                      ),
                      itemCount: _kelas.length,
                      itemBuilder: (_, i) => _KelasCard(kelas: _kelas[i])),
          ),
        ]),
      ),
    );
  }
}

class _KelasCard extends StatelessWidget {
  final Map<String, dynamic> kelas;
  const _KelasCard({required this.kelas});

  @override
  Widget build(BuildContext context) {
    final mk          = kelas['mata_kuliah'] as Map? ?? {};
    final santriCount = (kelas['kelas_santri'] as List?)?.length ?? 0;
    const color       = Color(0xFF2E6B8A);

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          StatusBadge(label: 'Kelas ${kelas['nama_kelas']}', color: color),
          StatusBadge(label: kelas['hari'] ?? '-', color: AppColors.secondary),
        ]),
        const SizedBox(height: 10),
        Text(mk['nama'] ?? '-', style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
          maxLines: 2, overflow: TextOverflow.ellipsis),
        Text('${mk['kode'] ?? ''} • ${mk['sks'] ?? 0} SKS',
          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
        const Spacer(),
        const Divider(color: AppColors.divider, height: 14),
        Row(children: [
          const Icon(Icons.room_rounded, size: 13, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(kelas['ruangan'] ?? '-',
            style: const TextStyle(fontSize: 11, color: AppColors.textMid)),
          const Spacer(),
          const Icon(Icons.group_rounded, size: 13, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text('$santriCount santri', style: const TextStyle(
            fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
