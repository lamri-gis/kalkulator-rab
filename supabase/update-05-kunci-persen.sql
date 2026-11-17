-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- UPDATE 05: kunci persentase TPK 3%, Pajak Bahan 12,5%, Pajak Sewa 13%
-- (upah tenaga kerja tetap maksimal 30% dari update-03)
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- =====================================================================

alter table public.rab_arsip drop constraint if exists rab_arsip_p_tpk_tetap;
alter table public.rab_arsip add constraint rab_arsip_p_tpk_tetap
  check (p_tpk is null or p_tpk = 0.03) not valid;

alter table public.rab_arsip drop constraint if exists rab_arsip_p_pajak_tetap;
alter table public.rab_arsip add constraint rab_arsip_p_pajak_tetap
  check (p_pajak is null or p_pajak = 0.125) not valid;

alter table public.rab_arsip drop constraint if exists rab_arsip_p_pajak_sewa_tetap;
alter table public.rab_arsip add constraint rab_arsip_p_pajak_sewa_tetap
  check (p_pajak_sewa is null or p_pajak_sewa = 0.13) not valid;

-- "not valid": data lama tidak diperiksa ulang, aturan berlaku untuk data baru.
-- Jika tarif resmi berubah, ganti angka di sini DAN di index.html secara bersamaan.
-- Selesai.
