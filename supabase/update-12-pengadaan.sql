-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 12: Data Pengadaan (Mode Pagu tanpa TPK)
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-11 harus sudah dijalankan)
-- =====================================================================

alter table public.rab_arsip
  add column if not exists jenis_belanja   text,
  add column if not exists kelompok_barang text,
  add column if not exists nama_barang     text,
  add column if not exists jumlah          numeric(14,3),
  add column if not exists satuan_barang   text,
  add column if not exists sifat_barang    text;

alter table public.rab_arsip drop constraint if exists rab_arsip_jenis_belanja_cek;
alter table public.rab_arsip add constraint rab_arsip_jenis_belanja_cek
  check (jenis_belanja is null or jenis_belanja in ('Belanja Barang/Jasa','Belanja Modal'));

alter table public.rab_arsip drop constraint if exists rab_arsip_kelompok_barang_len;
alter table public.rab_arsip add constraint rab_arsip_kelompok_barang_len
  check (kelompok_barang is null or char_length(kelompok_barang) <= 80);

alter table public.rab_arsip drop constraint if exists rab_arsip_nama_barang_len;
alter table public.rab_arsip add constraint rab_arsip_nama_barang_len
  check (nama_barang is null or char_length(nama_barang) <= 150);

alter table public.rab_arsip drop constraint if exists rab_arsip_jumlah_cek;
alter table public.rab_arsip add constraint rab_arsip_jumlah_cek
  check (jumlah is null or (jumlah > 0 and jumlah < 1000000000));

alter table public.rab_arsip drop constraint if exists rab_arsip_satuan_barang_len;
alter table public.rab_arsip add constraint rab_arsip_satuan_barang_len
  check (satuan_barang is null or char_length(satuan_barang) <= 20);

alter table public.rab_arsip drop constraint if exists rab_arsip_sifat_barang_cek;
alter table public.rab_arsip add constraint rab_arsip_sifat_barang_cek
  check (sifat_barang is null or sifat_barang in ('Habis Pakai','Aset Tetap'));

-- Selesai. Kolom baru: jenis_belanja, kelompok_barang, nama_barang, jumlah, satuan_barang, sifat_barang
