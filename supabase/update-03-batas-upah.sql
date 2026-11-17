-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- UPDATE 03: batas upah tenaga kerja maksimal 30% dari total
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- =====================================================================

alter table public.rab_arsip drop constraint if exists rab_arsip_p_tukang_maks;
alter table public.rab_arsip add constraint rab_arsip_p_tukang_maks
  check (p_tukang is null or p_tukang <= 0.30) not valid;

-- "not valid": data lama tidak diperiksa ulang, aturan berlaku untuk data baru.
-- Selesai.
