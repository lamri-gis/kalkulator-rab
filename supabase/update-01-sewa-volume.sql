-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- UPDATE 01: kolom sewa peralatan, volume, dan satuan
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- =====================================================================

alter table public.rab_arsip
  add column if not exists volume       numeric(14,2) check (volume >= 0 and volume < 1000000000000),
  add column if not exists satuan       text check (char_length(satuan) <= 20),
  add column if not exists sewa         bigint check (sewa >= 0),
  add column if not exists pajak_sewa   bigint check (pajak_sewa >= 0),
  add column if not exists p_pajak_sewa numeric(6,4) check (p_pajak_sewa between 0 and 1);

-- nilai_input boleh 0 (misalnya kegiatan yang hanya berisi sewa peralatan)
alter table public.rab_arsip drop constraint if exists rab_arsip_nilai_input_check;
alter table public.rab_arsip add constraint rab_arsip_nilai_input_check
  check (nilai_input between 0 and 100000000000);

-- Selesai. Cek di Table Editor > rab_arsip: kolom volume, satuan, sewa, pajak_sewa, p_pajak_sewa
