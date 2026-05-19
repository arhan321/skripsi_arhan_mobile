# tourhub

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# README Mobile - TourHub Bali Flutter

Dokumentasi ini menjelaskan project **TourHub Bali Mobile** berbasis Flutter.

Aplikasi ini dibuat sebagai aplikasi mobile untuk user agar bisa mencari rekomendasi wisata Bali berdasarkan preferensi, konteks cuaca, lokasi, dan riwayat rekomendasi.

---

## 1. Tujuan Aplikasi

TourHub Bali Mobile digunakan untuk:

- Register user.
- Login user.
- Mengisi preferensi wisata.
- Mendapatkan rekomendasi wisata Bali.
- Melihat detail rekomendasi.
- Melihat riwayat rekomendasi.
- Membuka lokasi destinasi ke Google Maps.
- Menampilkan UI mobile yang mewah, modern, dan nyaman digunakan.

Aplikasi mobile ini hanya untuk **user**.

Halaman admin tetap dikelola melalui website Laravel/Filament, bukan dari Flutter.

---

## 2. Stack Teknologi

| Bagian | Teknologi |
|---|---|
| Mobile | Flutter |
| Bahasa | Dart |
| HTTP Client | Dio |
| Token Storage | Flutter Secure Storage |
| Maps Launcher | url_launcher |
| Backend API | Laravel |
| ML Service | FastAPI |
| Model Rekomendasi | CBF + CARS |
| Dataset | Wisata Bali |

---

## 3. Alur Sistem Mobile

```text
User
  ↓
Flutter Mobile
  ↓
Laravel REST API
  ↓
FastAPI ML Recommendation Service
  ↓
Response Rekomendasi
  ↓
Flutter Menampilkan Hasil
```

Alur rekomendasi:

```text
1. User login
2. User isi preferensi wisata
3. Flutter kirim request ke Laravel API
4. Laravel validasi request
5. Laravel kirim request ke FastAPI ML
6. FastAPI mengembalikan rekomendasi
7. Laravel menyimpan log/history rekomendasi
8. Flutter menampilkan hasil rekomendasi
9. User bisa buka Google Maps dari destinasi
```

---

## 4. Struktur Folder Flutter

Struktur folder yang disarankan:

```text
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── network/
│   │   └── api_client.dart
│   ├── storage/
│   │   └── token_storage.dart
│   ├── utils/
│   │   └── maps_launcher.dart
│   └── routes/
│       └── app_routes.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_api.dart
│   │   └── pages/
│   │       ├── login_page.dart
│   │       └── register_page.dart
│   │
│   └── recommendation/
│       ├── data/
│       │   ├── recommendation_api.dart
│       │   └── recommendation_history_api.dart
│       └── pages/
│           ├── recommendation_page.dart
│           ├── history_page.dart
│           └── history_detail_page.dart
│
└── main.dart
```

---

## 5. Dependency

Pastikan `pubspec.yaml` memiliki dependency berikut:

```yaml
dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
  url_launcher: ^6.3.1
```

Fungsi dependency:

| Package | Fungsi |
|---|---|
| `dio` | Request HTTP ke Laravel API |
| `flutter_secure_storage` | Menyimpan token login |
| `url_launcher` | Membuka Google Maps/browser |
| `cupertino_icons` | Icon bawaan Flutter |

Setelah update dependency:

```bash
flutter pub get
```

Jika masih error:

```bash
flutter clean
flutter pub get
```

---

## 6. Konfigurasi Base URL

File:

```text
lib/core/config/app_config.dart
```

Contoh:

```dart
final class AppConfig {
  AppConfig._();

  static const String baseUrl = 'https://domain-anda.com/api';
}
```

### Jika Laravel Berjalan Local

Untuk Android emulator:

```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

Untuk HP fisik satu jaringan:

```dart
static const String baseUrl = 'http://192.168.1.10:8000/api';
```

Untuk production:

```dart
static const String baseUrl = 'https://tourhub.domain-anda.com/api';
```

---

## 7. Token Storage

File:

```text
lib/core/storage/token_storage.dart
```

Fungsi utama:

- Menyimpan token setelah login.
- Membaca token untuk request API.
- Menghapus token saat logout.

Contoh konsep:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class TokenStorage {
  TokenStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
```

---

## 8. API Client

File:

```text
lib/core/network/api_client.dart
```

Tugas API client:

- Menentukan base URL API.
- Menambahkan header `Accept: application/json`.
- Menambahkan token bearer jika user login.
- Menangani error API agar aplikasi tidak crash.

Contoh header auth:

```http
Authorization: Bearer TOKEN_USER
Accept: application/json
Content-Type: application/json
```

---

## 9. Fitur Auth

### Login

File:

```text
lib/features/auth/pages/login_page.dart
lib/features/auth/data/auth_api.dart
```

Alur login:

```text
1. User isi email dan password
2. Flutter kirim POST /api/login
3. Laravel validasi login
4. Laravel kirim token
5. Flutter simpan token
6. User masuk ke halaman rekomendasi/dashboard
```

### Register

File:

```text
lib/features/auth/pages/register_page.dart
lib/features/auth/data/auth_api.dart
```

Alur register:

```text
1. User isi nama, email, password, konfirmasi password
2. Flutter kirim POST /api/register
3. Laravel membuat user baru
4. Flutter menampilkan pesan sukses
5. User diarahkan ke login atau langsung masuk sesuai flow
```

---

## 10. Fitur Rekomendasi Wisata

File utama:

```text
lib/features/recommendation/pages/recommendation_page.dart
lib/features/recommendation/data/recommendation_api.dart
```

Payload yang dikirim ke API:

```json
{
  "kategori_preferensi": ["Alam", "Budaya"],
  "kabupaten_kota": "Badung",
  "kecamatan": "Kuta",
  "keywords": ["pantai", "sunset"],
  "min_rating": 4,
  "top_n": 10,
  "weather": "cerah",
  "visit_day": "weekend",
  "is_high_season": false,
  "use_bmkg": false,
  "bmkg_adm4": null
}
```

Field penting:

| Field | Keterangan |
|---|---|
| `kategori_preferensi` | Kategori wisata yang dipilih user |
| `kabupaten_kota` | Kabupaten/kota tujuan |
| `kecamatan` | Kecamatan tujuan |
| `keywords` | Minat tambahan user |
| `min_rating` | Rating minimum |
| `top_n` | Jumlah hasil |
| `weather` | Cuaca manual jika BMKG tidak aktif |
| `visit_day` | `weekday` atau `weekend` |
| `is_high_season` | Status musim liburan |
| `use_bmkg` | Menggunakan BMKG atau tidak |
| `bmkg_adm4` | Kode wilayah BMKG jika aktif |

---

## 11. Fitur History Rekomendasi

File utama:

```text
lib/features/recommendation/pages/history_page.dart
lib/features/recommendation/pages/history_detail_page.dart
lib/features/recommendation/data/recommendation_history_api.dart
```

Fungsi history:

- Menampilkan daftar riwayat rekomendasi user.
- Menampilkan detail request rekomendasi.
- Menampilkan hasil response rekomendasi sebelumnya.
- Membantu user melihat ulang destinasi yang pernah direkomendasikan.

Data yang ditampilkan:

- Tanggal rekomendasi.
- Status rekomendasi.
- Cuaca yang digunakan.
- Total kandidat.
- Response time.
- Daftar destinasi.
- Gambar destinasi.
- Rating destinasi.
- Tombol Google Maps.

---

## 12. Fitur Google Maps

Package yang digunakan:

```yaml
url_launcher: ^6.3.1
```

File helper:

```text
lib/core/utils/maps_launcher.dart
```

Contoh fungsi:

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openGoogleMaps(
  BuildContext context,
  String? url,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (url == null || url.trim().isEmpty) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Link Google Maps belum tersedia untuk destinasi ini.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final uri = Uri.tryParse(url.trim());

  if (uri == null || !uri.hasScheme) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Format link Google Maps tidak valid.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  try {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    }
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Gagal membuka Google Maps.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
```

Cara pakai:

```dart
onPressed: () {
  openGoogleMaps(context, item.linkMaps);
}
```

---

## 13. Android Manifest untuk Google Maps

Buka file:

```text
android/app/src/main/AndroidManifest.xml
```

Tambahkan `queries` sebelum tag `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="http" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="geo" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="google.navigation" />
        </intent>
    </queries>

    <application
        android:label="tourhub"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>

</manifest>
```

Setelah update:

```bash
flutter clean
flutter pub get
flutter run
```

---

## 14. Cara Menjalankan Project

Masuk ke folder project:

```bash
cd D:\flutter\tourhub
```

Cek device:

```bash
flutter devices
```

Install dependency:

```bash
flutter pub get
```

Run aplikasi:

```bash
flutter run
```

Run di device tertentu:

```bash
flutter run -d emulator-5554
```

---

## 15. Build APK

Build APK release:

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build APK split ABI:

```bash
flutter build apk --split-per-abi
```

Output:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

## 16. Checklist Testing Mobile

| No | Fitur | Status |
|---|---|---|
| 1 | App berhasil dibuka | Belum/Sudah |
| 2 | Login page tampil | Belum/Sudah |
| 3 | Register page tampil | Belum/Sudah |
| 4 | Register berhasil | Belum/Sudah |
| 5 | Login berhasil | Belum/Sudah |
| 6 | Token tersimpan | Belum/Sudah |
| 7 | Dashboard/rekomendasi tampil | Belum/Sudah |
| 8 | Form rekomendasi bisa diisi | Belum/Sudah |
| 9 | Dropdown kabupaten/kecamatan berjalan | Belum/Sudah |
| 10 | Request rekomendasi berhasil | Belum/Sudah |
| 11 | Hasil rekomendasi tampil | Belum/Sudah |
| 12 | Gambar destinasi tampil | Belum/Sudah |
| 13 | Tombol Google Maps berjalan | Belum/Sudah |
| 14 | History tampil | Belum/Sudah |
| 15 | Detail history tampil | Belum/Sudah |
| 16 | Logout berhasil | Belum/Sudah |
| 17 | Error API tampil rapi | Belum/Sudah |

---

## 17. Troubleshooting Mobile

### 17.1 Error `Target of URI doesn't exist: package:url_launcher/url_launcher.dart`

Penyebab:

Dependency `url_launcher` belum ada di `pubspec.yaml`.

Solusi:

```yaml
url_launcher: ^6.3.1
```

Lalu jalankan:

```bash
flutter pub get
```

Jika masih merah:

```bash
flutter clean
flutter pub get
```

---

### 17.2 API Tidak Tersambung

Cek:

- `AppConfig.baseUrl`
- Laravel API aktif
- Domain benar
- Endpoint benar
- Internet emulator/HP aktif
- CORS backend aman

Untuk emulator Android, jangan gunakan:

```text
http://localhost:8000/api
```

Gunakan:

```text
http://10.0.2.2:8000/api
```

---

### 17.3 Login Berhasil Tapi Setelah Restart Logout Lagi

Cek:

- Token benar-benar disimpan ke `flutter_secure_storage`.
- Auth gate membaca token saat app dibuka.
- API client menambahkan token ke header.
- Token belum expired atau belum dihapus saat logout.

---

### 17.4 Gambar Tidak Muncul

Cek:

- Field `link_gambar` dari API.
- URL gambar masih aktif.
- URL memakai HTTPS.
- Flutter memakai `Image.network`.
- Ada fallback/placeholder ketika gambar gagal load.

Contoh fallback:

```dart
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.image_not_supported);
  },
)
```

---

### 17.5 Google Maps Tidak Terbuka

Cek:

- `url_launcher` sudah dipasang.
- `flutter pub get` sudah dijalankan.
- Link maps tidak kosong.
- Format link valid.
- AndroidManifest sudah menambahkan `queries`.
- Aplikasi sudah di-run ulang setelah `flutter clean`.

---

## 18. Catatan UI/UX

Konsep tampilan mobile TourHub:

- Modern.
- Mewah.
- Clean.
- Cocok untuk aplikasi wisata Bali.
- Tidak terlalu ramai.
- Card destinasi harus jelas.
- Tombol CTA seperti `Cari Rekomendasi`, `Lihat Detail`, dan `Buka Google Maps` harus mudah terlihat.
- Error message harus manusiawi, bukan error mentah dari server.

Halaman penting:

```text
1. Login Page
2. Register Page
3. Recommendation Page
4. Recommendation Result Page
5. History Page
6. History Detail Page
7. Profile/Logout Area
```

---

## 19. Catatan Integrasi dengan Backend

Pastikan backend API menyediakan:

- Endpoint register.
- Endpoint login.
- Endpoint logout.
- Endpoint profile user.
- Endpoint rekomendasi.
- Endpoint history rekomendasi.
- Endpoint detail history.
- Field `link_gambar`.
- Field `link_maps` atau `google_maps_url`.

Agar Flutter lebih mudah, sebaiknya nama field konsisten.

Rekomendasi field destinasi:

```json
{
  "nama": "Pantai Kuta",
  "kategori": "Alam",
  "kabupaten_kota": "Badung",
  "kecamatan": "Kuta",
  "rating": 4.6,
  "deskripsi": "Destinasi wisata pantai di Bali.",
  "link_gambar": "https://example.com/pantai-kuta.jpg",
  "link_maps": "https://www.google.com/maps/search/?api=1&query=Pantai%20Kuta%20Bali",
  "final_score": 0.92
}
```

---

## 20. Kesimpulan

TourHub Bali Mobile adalah aplikasi Flutter untuk user yang terhubung ke backend Laravel dan ML FastAPI.

Fitur utama aplikasi:

- Auth user.
- Rekomendasi wisata Bali.
- History rekomendasi.
- Detail rekomendasi.
- Google Maps launcher.
- UI mobile modern dan nyaman.

Untuk pengetesan API, gunakan file:

```text
sample_pengetesan.md
```

Untuk dokumentasi mobile, gunakan file ini:

```text
README_MOBILE.md
```
