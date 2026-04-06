import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'core/widgets/responsive_widgets.dart';
import 'features/admin/dashboard/admin_dashboard_page.dart';
import 'features/dosen/pages/dosen_dashboard_page.dart';
import 'features/pembina/pages/pembina_dashboard_page.dart';
import 'features/santri/pages/santri_dashboard_page.dart';

// ══ API Supabase dimuat dari .env (lihat .env.example) ══

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Pre-load Google Fonts untuk menghindari UI lag saat debugging
  await GoogleFonts.pendingFonts(['Plus Jakarta Sans', 'Playfair Display']);
  
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('❌ SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan di file .env');
  }
  
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const SimamahApp());
}

class SimamahApp extends StatelessWidget {
  const SimamahApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMAMAH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _AuthGate(),
      routes: {
        '/login'   : (_) => const _LoginPage(),
        '/admin'   : (_) => const AdminDashboardPage(),
        '/dosen'   : (_) => const DosenDashboardPage(),
        '/pembina' : (_) => const PembinaDashboardPage(),
        '/santri'  : (_) => const SantriDashboardPage(),
      },
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await _routeByRole();
  }

  Future<void> _routeByRole() async {
    if (!mounted) return;
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) { _goLogin(); return; }

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();

      if (!mounted) return;

      final route = {
        'admin'  : '/admin',
        'dosen'  : '/dosen',
        'pembina': '/pembina',
        'santri' : '/santri',
      }[profile['role'] as String];

      Navigator.pushReplacementNamed(context, route ?? '/login');
    } catch (_) {
      _goLogin();
    }
  }

  void _goLogin() {
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.background,
    body: Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mosque_rounded, size: 64, color: AppColors.primary),
        SizedBox(height: 16),
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 12),
        Text('SIMAMAH', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.primary)),
      ],
    )),
  );
}

// ── Login Page ────────────────────────────────────────────
class _LoginPage extends StatefulWidget {
  const _LoginPage();
  @override State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(), password: _password.text);
      if (res.user == null) throw Exception('Login gagal');
      final profile = await Supabase.instance.client
          .from('profiles').select('role').eq('id', res.user!.id).single();
      final route = {
        'admin': '/admin', 'dosen': '/dosen',
        'pembina': '/pembina', 'santri': '/santri',
      }[profile['role'] as String] ?? '/login';
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      setState(() {
        _loading = false;
        final msg = e.toString().toLowerCase();
        _error = msg.contains('invalid') || msg.contains('credentials')
            ? 'Email atau password salah'
            : 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan responsive helper untuk adaptive layout
    if (context.isMobile) {
      // Mobile layout: Column dengan scroll
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildMobileHeader(),
              _buildForm(context),
            ],
          ),
        ),
      );
    } else {
      // Desktop/Tablet layout: Row dengan 2 panel
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            Expanded(child: _buildLeftPanel()),
            SizedBox(
              width: context.responsive.getSpacing(
                mobile: 320,
                tablet: 380,
                desktop: 460,
              ),
              child: _buildForm(context),
            ),
          ],
        ),
      );
    }
  }

// Panel kiri (hanya muncul di desktop)
Widget _buildLeftPanel() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, Color(0xFF1E4020)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.mosque_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 28),
            const Text('SIMAMAH', style: TextStyle(
              color: Colors.white, fontSize: 44,
              fontWeight: FontWeight.w900, letterSpacing: 3,
            )),
            const SizedBox(height: 8),
            Text('Sistem Informasi Manajemen\nMahasiswa Pesantren',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 17, height: 1.6,
              ),
            ),
            const SizedBox(height: 48),
            ...[
              (Icons.school_rounded,      'Manajemen Santri & Akademik'),
              (Icons.mosque_rounded,      'Absensi Ibadah Terstruktur'),
              (Icons.location_on_rounded, 'Geofencing Absensi'),
              (Icons.analytics_rounded,   'Laporan & Dashboard'),
            ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.$1, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(item.$2, style: TextStyle(
                  color: Colors.white.withOpacity(0.88), fontSize: 14,
                )),
              ]),
            )),
          ],
        ),
      ),
    ),
  );
}

// Header mobile (ganti panel kiri di HP)
Widget _buildMobileHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, Color(0xFF1E4020)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.mosque_rounded,
            color: Colors.white, size: 44),
      ),
      const SizedBox(height: 16),
      const Text('SIMAMAH', style: TextStyle(
        color: Colors.white, fontSize: 28,
        fontWeight: FontWeight.w900, letterSpacing: 2,
      )),
      const SizedBox(height: 4),
      Text('Sistem Informasi Manajemen Mahasiswa Pesantren',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.75), fontSize: 12,
        ),
      ),
    ]),
  );
}

// Form login (dipakai di mobile & desktop)
Widget _buildForm(BuildContext context) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_rounded,
              color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 20),
        Text('Masuk ke SIMAMAH',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text('Masukkan kredensial Anda',
          style: TextStyle(color: AppColors.textLight, fontSize: 13),
        ),
        const SizedBox(height: 28),

        Form(key: _formKey, child: Column(children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Email tidak valid' : null,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined,
                  color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            validator: (v) => (v == null || v.length < 6)
                ? 'Minimal 6 karakter' : null,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined,
                  color: AppColors.textLight),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined
                           : Icons.visibility_outlined,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(
                  color: AppColors.error, fontSize: 13,
                ))),
              ]),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                : const Text('Masuk',
                    style: TextStyle(fontSize: 16)),
            ),
          ),
        ])),

        const SizedBox(height: 24),
        Text('© ${DateTime.now().year} SIMAMAH',
          style: const TextStyle(
              color: AppColors.textLight, fontSize: 11),
        ),
      ]),
    ),
  );
}
}