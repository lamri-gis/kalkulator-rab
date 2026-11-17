-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- UPDATE 02: ukuran (panjang, lebar, tinggi), bahan dan sifat konstruksi
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-01 harus sudah dijalankan sebelumnya)
-- =====================================================================

alter table public.rab_arsip
  add column if not exists panjang          numeric(14,3) check (panjang > 0 and panjang < 1000000000),
  add column if not exists lebar            numeric(14,3) check (lebar > 0 and lebar < 1000000000),
  add column if not exists tinggi           numeric(14,3) check (tinggi > 0 and tinggi < 1000000000),
  add column if not exists bahan_utama      text check (char_length(bahan_utama) <= 60),
  add column if not exists sifat_konstruksi text check (sifat_konstruksi in ('Permanen','Semi Permanen','Sementara/Darurat'));

-- Satuan hasil hitung otomatis: m, m², atau m³ (panjang, lebar, tinggi disimpan dalam meter)

-- Selesai. Cek di Table Editor > rab_arsip: kolom panjang, lebar, tinggi, bahan_utama, sifat_konstruksi
