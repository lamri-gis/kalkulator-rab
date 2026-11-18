-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 08: deteksi perangkat (jenis, sistem operasi, browser, model HP)
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- =====================================================================

alter table public.rab_arsip
  add column if not exists perangkat text check (perangkat in ('HP','Tablet','Laptop')),
  add column if not exists os        text check (char_length(os) <= 40),
  add column if not exists browser   text check (char_length(browser) <= 40),
  add column if not exists model_hp  text check (char_length(model_hp) <= 60);

-- Selesai. Cek Table Editor > rab_arsip: kolom perangkat, os, browser, model_hp
