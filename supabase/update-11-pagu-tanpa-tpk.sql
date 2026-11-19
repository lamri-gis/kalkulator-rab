-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 11: Mode Pagu boleh tanpa TPK (0%); Mode Material tetap TPK 3%
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-10 harus sudah dijalankan)
-- =====================================================================

alter table public.rab_arsip drop constraint if exists rab_arsip_p_tpk_tetap;
alter table public.rab_arsip add constraint rab_arsip_p_tpk_tetap
  check (p_tpk is null or p_tpk = 0.03 or (mode = 'pagu' and p_tpk = 0));

-- Selesai.
