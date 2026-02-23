# 📦 PANDUAN DEPLOY — stok.toko
> Waktu setup: ±20 menit · Biaya: GRATIS (Supabase free tier)

---

## 🗂 Struktur File

```
stok-toko/
├── index.html   ← Halaman publik (tampilan live tanpa login)
├── app.html     ← Dashboard staff (login, input, RBAC)
└── setup.sql    ← Script database (jalankan di Supabase sekali saja)
```

---

## LANGKAH 1 — Buat Akun & Project Supabase

1. Buka **https://supabase.com** → klik **Start your project**
2. Daftar dengan GitHub atau email
3. Klik **New Project**
   - Isi nama project: `stok-toko`
   - Buat password database (simpan baik-baik!)
   - Pilih region: **Southeast Asia (Singapore)**
4. Tunggu ±2 menit hingga project siap

---

## LANGKAH 2 — Jalankan Script Database

1. Di dashboard Supabase, klik **SQL Editor** (ikon di sidebar kiri)
2. Klik **New Query**
3. **Copy seluruh isi file `setup.sql`** → paste ke editor
4. Klik **Run** (atau tekan `Ctrl+Enter`)
5. Pastikan muncul pesan `Success. No rows returned`

> ✅ Ini akan membuat semua tabel, view, RLS, dan sample data secara otomatis.

---

## LANGKAH 3 — Ambil Konfigurasi Supabase

1. Di sidebar Supabase → **Project Settings** → **API**
2. Salin dua nilai ini:

| Nilai | Lokasi |
|-------|--------|
| **Project URL** | `https://xxxx.supabase.co` |
| **anon (public) key** | Token panjang di bagian "Project API Keys" |

---

## LANGKAH 4 — Tempel Config ke File HTML

Buka `index.html` dan `app.html`, cari bagian ini di **masing-masing file**:

```javascript
const SUPABASE_URL  = 'https://XXXX.supabase.co';   // ← ganti ini
const SUPABASE_ANON = 'eyJhbGci...';                // ← ganti ini
```

Ganti dengan nilai dari Langkah 3:

```javascript
const SUPABASE_URL  = 'https://abcdefgh.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOi...';
```

---

## LANGKAH 5 — Buat Akun Staff (User)

### Cara A: Via Supabase Dashboard (disarankan untuk awal)

1. Supabase → **Authentication** → **Users** → **Add User**
2. Buat user sesuai role:

| Email | Password | Role |
|-------|----------|------|
| `admin@toko.com` | bebas | admin |
| `sales-a@toko.com` | bebas | sales |
| `sales-b@toko.com` | bebas | sales |
| `gudang@toko.com` | bebas | warehouse |

### Cara B: Daftarkan manual lewat browser
Buka `app.html` di browser, login dengan email yang sudah dibuat.

---

## LANGKAH 6 — Assign Role ke User

Setelah user dibuat, kamu perlu **mengisi tabel `user_roles`** secara manual.

1. Supabase → **Table Editor** → tabel `user_roles`
2. Klik **Insert Row** untuk setiap user:

| user_id | email | role |
|---------|-------|------|
| *(copy dari tabel auth.users)* | `admin@toko.com` | `admin` |
| *(copy dari tabel auth.users)* | `sales-a@toko.com` | `sales` |
| *(copy dari tabel auth.users)* | `gudang@toko.com` | `warehouse` |

> 💡 **Tips:** Cara cepat ambil user_id: di Supabase → Authentication → Users → klik user → salin UUID-nya.

### Atau via SQL (lebih cepat):

```sql
-- Jalankan di SQL Editor setelah user dibuat
INSERT INTO user_roles (user_id, email, role)
SELECT id, email, 'admin'
FROM auth.users WHERE email = 'admin@toko.com';

INSERT INTO user_roles (user_id, email, role)
SELECT id, email, 'sales'
FROM auth.users WHERE email = 'sales-a@toko.com';

INSERT INTO user_roles (user_id, email, role)
SELECT id, email, 'warehouse'
FROM auth.users WHERE email = 'gudang@toko.com';
```

---

## LANGKAH 7 — Deploy Website (Pilih salah satu)

### Opsi A: Netlify Drop (PALING MUDAH — drag & drop, gratis)

1. Buka **https://app.netlify.com/drop**
2. Drag & drop folder berisi `index.html` dan `app.html`
3. Selesai! Kamu dapat URL seperti `https://nama-random.netlify.app`

### Opsi B: GitHub Pages (gratis, lebih profesional)

1. Upload ketiga file ke repository GitHub
2. Settings → Pages → Source: `main` branch
3. URL: `https://username.github.io/nama-repo`

### Opsi C: Buka lokal (untuk testing)

Cukup buka `index.html` dan `app.html` langsung di browser.
> ⚠️ Pastikan pakai browser modern (Chrome/Firefox/Edge)

---

## 🧪 Testing Sistem

Setelah deploy, test urutan berikut:

1. **Buka `index.html`** → pastikan widget dashboard tampil (mungkin 0 semua dulu)
2. **Buka `app.html`** → login sebagai `admin@toko.com`
   - Pastikan muncul section "Manajemen Produk"
   - Tambah beberapa produk (jika belum pakai sample data)
3. **Login sebagai `sales-a@toko.com`**
   - Pastikan hanya muncul tombol "+ Input Penjualan"
   - Input penjualan → cek apakah `index.html` terupdate otomatis
4. **Login sebagai `gudang@toko.com`**
   - Pastikan hanya muncul tombol "+ Input Stok"
5. **Buka dua tab browser** (satu `index.html`, satu `app.html`) → input data di satu tab, lihat update realtime di tab lain

---

## 🚀 Pengembangan Selanjutnya

Sistem ini dirancang agar mudah dikembangkan. Berikut fitur yang bisa ditambahkan:

### Jangka Pendek
- [ ] **Export laporan** ke PDF/Excel (gunakan library `jsPDF` atau `SheetJS`)
- [ ] **Notifikasi stok menipis** via email (Supabase Edge Functions + Resend)
- [ ] **Filter tanggal** di tabel riwayat
- [ ] **Grafik penjualan** mingguan/bulanan (Chart.js)

### Jangka Menengah
- [ ] **Multi-cabang** (tambah kolom `cabang_id` di setiap tabel)
- [ ] **Barcode scanner** input (gunakan library `QuaggaJS`)
- [ ] **Mobile app** wrapper dengan Capacitor/Cordova
- [ ] **Audit log** otomatis setiap perubahan data

### Jangka Panjang
- [ ] **Integrasi POS** (kasir digital)
- [ ] **Laporan keuangan** sederhana
- [ ] **Prediksi stok** dengan analisis tren

---

## ❓ Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Halaman blank / error konsol | Periksa SUPABASE_URL dan SUPABASE_ANON di kedua file HTML |
| Login gagal terus | Pastikan user sudah dibuat di Supabase Auth |
| Tidak ada tombol input setelah login | Pastikan `user_roles` sudah diisi untuk user tersebut |
| Data tidak update realtime | Pastikan `setup.sql` sudah dijalankan (ALTER PUBLICATION...) |
| Error "violates row-level security" | Policy RLS belum terpasang — jalankan ulang `setup.sql` |

---

## 📞 Struktur Kode (untuk developer)

```
index.html
  ├── Supabase JS SDK (CDN)
  ├── loadAll()          ← fetch semua data sekali
  ├── subscribeRealtime() ← listen INSERT via WebSocket
  ├── renderJual/Stok/Summary/Widgets()
  └── tickClock()        ← jam live

app.html
  ├── checkSession()     ← cek login saat halaman dibuka
  ├── initApp()          ← setup UI berdasarkan role
  ├── RBAC:
  │   ├── sales     → bisa input penjualan
  │   ├── warehouse → bisa input stok
  │   └── admin     → semua akses + hapus + produk manager
  ├── saveJual/Stok()    ← INSERT ke database
  └── subscribeRealtime() ← sinkronisasi antar user

setup.sql
  ├── CREATE TABLE produk, penambahan_stok, penjualan_harian, user_roles
  ├── CREATE VIEW ringkasan_stok, dashboard_hari_ini
  ├── ALTER PUBLICATION (enable realtime)
  ├── ENABLE ROW LEVEL SECURITY
  ├── CREATE POLICY (per tabel per role)
  └── INSERT sample data
```

---

*stok.toko v1.0 · Dibuat dengan Supabase + Vanilla JS*
