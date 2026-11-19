-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 10: Jenis Bangunan/Pekerjaan dan rincian ukuran
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-01 sampai update-09 harus sudah dijalankan)
-- =====================================================================

alter table public.rab_arsip
  add column if not exists jenis_bangunan text,
  add column if not exists ukuran text;

alter table public.rab_arsip drop constraint if exists rab_arsip_jenis_bangunan_len;
alter table public.rab_arsip add constraint rab_arsip_jenis_bangunan_len
  check (jenis_bangunan is null or char_length(jenis_bangunan) <= 60);

alter table public.rab_arsip drop constraint if exists rab_arsip_ukuran_len;
alter table public.rab_arsip add constraint rab_arsip_ukuran_len
  check (ukuran is null or char_length(ukuran) <= 300);

-- Selesai. Kolom baru: jenis_bangunan, ukuran (rincian ukuran seperti di hasil cetak)
