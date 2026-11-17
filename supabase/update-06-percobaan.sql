-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- UPDATE 06: kolom percobaan Generate
--   1 = lolos akurasi <= 15 m pada percobaan pertama
--   2 = diterima pada percobaan kedua (akurasi berapa pun)
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- =====================================================================

alter table public.rab_arsip
  add column if not exists percobaan smallint check (percobaan in (1, 2));

-- Selesai. Cek Table Editor > rab_arsip: kolom percobaan
