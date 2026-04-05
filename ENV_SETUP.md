# Environment Variables Setup (**.env** Security)

## Overview
Supabase API credentials tersimpan di file `.env` dan **TIDAK akan di-commit ke GitHub** untuk menjaga keamanan.

## 📋 Setup Instructions

### 1️⃣ **File `.env` Sudah Dibuat**
File `.env` di root project sudah berisi:
```env
SUPABASE_URL=https://yuflaqpfxulynhhosuxb.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2️⃣ **Untuk Developer Lain**
Ketika developer clone project dari GitHub:

```bash
# 1. Clone repository
git clone <repository-url>
cd pk_nanda

# 2. Copy template env
cp .env.example .env

# 3. Edit .env dengan credentials yang benar
# Minta Supabase URL dan Anon Key kepada project lead

# 4. Install dependencies
flutter pub get

# 5. Run aplikasi
flutter run
```

### 3️⃣ **File `.env.example`**
Template `.env.example` berisi placeholder untuk credentials:
```env
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

## 🔐 Security Measures

✅ **`.env` tidak akan di-commit** — ditambahkan ke `.gitignore`  
✅ **Credentials dimuat saat startup** — validasi error jika `.env` tidak ada  
✅ **Template `.env.example` untuk documentation** — aman di-commit  
✅ **`flutter_dotenv` package** — standard solution untuk environment variables  

## 📝 Kode Integration

Di `lib/main.dart`:
```dart
// Load environment variables
await dotenv.load(fileName: '.env');

// Baca credentials
final supabaseUrl = dotenv.env['SUPABASE_URL'];
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

// Validasi
if (supabaseUrl == null || supabaseAnonKey == null) {
  throw Exception('❌ SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan di file .env');
}

// Initialize Supabase
await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
```

## ⚠️ Troubleshooting

**Error: "SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan"**
- Pastikan file `.env` ada di root project
- Pastikan credentials di `.env` benar dan tidak ada typo
- Jalankan `flutter pub get` setelah membuat/edit `.env`

**`.env` file tidak ditemukan saat build**
- File `.env` sudah ditambahkan ke `assets` di `pubspec.yaml`
- Jalankan `flutter clean && flutter pub get` untuk refresh

## 🚀 Next Time

Jika perlu update Supabase credentials:
1. Edit file `.env` (jangan `.env.example`)
2. Simpan file
3. Hot reload atau hot restart app
4. `.env` akan ter-load otomatis

---

**Catatan**: File `.env` sudah dalam `.gitignore`, aman untuk di-push ke GitHub! 🎉
