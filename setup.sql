-- ============================================================
-- STOK.TOKO — Supabase Database Setup
-- Jalankan file ini di Supabase SQL Editor
-- ============================================================

-- ── 1. TABEL PRODUK (Master) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS produk (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama        TEXT NOT NULL UNIQUE,
  stok_awal   INTEGER NOT NULL DEFAULT 0,
  satuan      TEXT DEFAULT 'pcs',
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── 2. TABEL PENAMBAHAN STOK ──────────────────────────────────
CREATE TABLE IF NOT EXISTS penambahan_stok (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  produk_id   UUID NOT NULL REFERENCES produk(id) ON DELETE CASCADE,
  jumlah      INTEGER NOT NULL CHECK (jumlah > 0),
  catatan     TEXT,
  user_input  TEXT,          -- email user yang input
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── 3. TABEL PENJUALAN HARIAN ─────────────────────────────────
CREATE TABLE IF NOT EXISTS penjualan_harian (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  produk_id   UUID NOT NULL REFERENCES produk(id) ON DELETE CASCADE,
  jumlah      INTEGER NOT NULL CHECK (jumlah > 0),
  catatan     TEXT,
  user_input  TEXT,          -- email user yang input
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── 4. USER ROLES TABLE ───────────────────────────────────────
-- Menyimpan role per user (diisi manual oleh admin setelah user daftar)
CREATE TABLE IF NOT EXISTS user_roles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT NOT NULL,
  role        TEXT NOT NULL CHECK (role IN ('sales', 'warehouse', 'admin')),
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- ── 5. VIEW: RINGKASAN STOK (computed on-the-fly) ────────────
CREATE OR REPLACE VIEW ringkasan_stok AS
SELECT
  p.id,
  p.nama,
  p.satuan,
  p.stok_awal,
  COALESCE(SUM(ps.jumlah), 0)                          AS total_masuk,
  COALESCE(SUM(ph.jumlah), 0)                          AS total_keluar,
  p.stok_awal
    + COALESCE(SUM(ps.jumlah), 0)
    - COALESCE(SUM(ph.jumlah), 0)                      AS sisa_stok
FROM produk p
LEFT JOIN penambahan_stok ps ON ps.produk_id = p.id
LEFT JOIN penjualan_harian ph ON ph.produk_id = p.id
GROUP BY p.id, p.nama, p.satuan, p.stok_awal
ORDER BY p.nama;

-- ── 6. VIEW: DASHBOARD HARI INI ──────────────────────────────
CREATE OR REPLACE VIEW dashboard_hari_ini AS
SELECT
  (SELECT COALESCE(SUM(jumlah), 0) FROM penjualan_harian
   WHERE created_at::date = CURRENT_DATE)              AS terjual_hari_ini,
  (SELECT COALESCE(SUM(jumlah), 0) FROM penambahan_stok
   WHERE created_at::date = CURRENT_DATE)              AS masuk_hari_ini,
  (SELECT COUNT(*) FROM ringkasan_stok WHERE sisa_stok <= 5) AS produk_menipis,
  (SELECT COUNT(*) FROM produk)                        AS total_produk;

-- ── 7. ENABLE REALTIME ────────────────────────────────────────
-- Aktifkan realtime untuk tabel-tabel utama
ALTER PUBLICATION supabase_realtime ADD TABLE penjualan_harian;
ALTER PUBLICATION supabase_realtime ADD TABLE penambahan_stok;
ALTER PUBLICATION supabase_realtime ADD TABLE produk;

-- ── 8. ROW LEVEL SECURITY (RBAC) ─────────────────────────────

-- Aktifkan RLS
ALTER TABLE produk            ENABLE ROW LEVEL SECURITY;
ALTER TABLE penambahan_stok   ENABLE ROW LEVEL SECURITY;
ALTER TABLE penjualan_harian  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles        ENABLE ROW LEVEL SECURITY;

-- Helper function: ambil role user yang sedang login
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM user_roles WHERE user_id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

-- ── PRODUK ──
-- Semua orang bisa SELECT (termasuk publik via anon key)
CREATE POLICY "produk_select_all"
  ON produk FOR SELECT USING (true);

-- Hanya admin & warehouse yang bisa INSERT/UPDATE/DELETE produk
CREATE POLICY "produk_write_admin"
  ON produk FOR ALL
  USING (get_my_role() IN ('admin', 'warehouse'))
  WITH CHECK (get_my_role() IN ('admin', 'warehouse'));

-- ── PENAMBAHAN STOK ──
CREATE POLICY "stok_select_all"
  ON penambahan_stok FOR SELECT USING (true);

CREATE POLICY "stok_insert_warehouse"
  ON penambahan_stok FOR INSERT
  WITH CHECK (get_my_role() IN ('warehouse', 'admin'));

CREATE POLICY "stok_delete_admin"
  ON penambahan_stok FOR DELETE
  USING (get_my_role() = 'admin');

-- ── PENJUALAN HARIAN ──
CREATE POLICY "jual_select_all"
  ON penjualan_harian FOR SELECT USING (true);

CREATE POLICY "jual_insert_sales"
  ON penjualan_harian FOR INSERT
  WITH CHECK (get_my_role() IN ('sales', 'admin'));

CREATE POLICY "jual_delete_admin"
  ON penjualan_harian FOR DELETE
  USING (get_my_role() = 'admin');

-- ── USER ROLES ──
-- Setiap user HARUS bisa baca baris miliknya sendiri
-- (tanpa ini, query role akan return null → "role tidak dikenali")
CREATE POLICY "roles_select_own"
  ON user_roles FOR SELECT
  USING (user_id = auth.uid());

-- Admin bisa INSERT / UPDATE / DELETE semua baris
CREATE POLICY "roles_admin_write"
  ON user_roles FOR ALL
  USING (get_my_role() = 'admin')
  WITH CHECK (get_my_role() = 'admin');

-- ── 9. SAMPLE DATA (opsional, hapus jika tidak perlu) ────────
INSERT INTO produk (nama, stok_awal, satuan) VALUES
  ('Aqua 600ml',    100, 'botol'),
  ('Indomie Goreng',  50, 'bungkus'),
  ('Teh Botol Sosro', 80, 'botol'),
  ('Roti Tawar',      30, 'bungkus'),
  ('Susu Ultra 1L',   40, 'kotak')
ON CONFLICT (nama) DO NOTHING;

-- ============================================================
-- SELESAI! Lanjut ke PANDUAN.md untuk langkah selanjutnya.
-- ============================================================
