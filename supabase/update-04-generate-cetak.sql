-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- UPDATE 04: alur Generate (lokasi GPS) dan Izin Cetak (nama + kode verifikasi)
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-01 s.d. update-03 harus sudah dijalankan)
-- =====================================================================

-- 1. Kolom baru ----------------------------------------------------------
alter table public.rab_arsip
  add column if not exists token           uuid unique,
  add column if not exists lat             numeric(9,6) check (lat between -90 and 90),
  add column if not exists lng             numeric(9,6) check (lng between -180 and 180),
  add column if not exists akurasi         numeric(10,1) check (akurasi >= 0 and akurasi < 100000000),
  add column if not exists dicetak         boolean not null default false,
  add column if not exists waktu_cetak     timestamptz,
  add column if not exists nama_pemohon    text check (char_length(nama_pemohon) between 3 and 100),
  add column if not exists kode_verifikasi text unique;

create index if not exists rab_arsip_dicetak_idx on public.rab_arsip (dicetak);

-- 2. Aksi 'generate' diizinkan --------------------------------------------
alter table public.rab_arsip drop constraint if exists rab_arsip_aksi_check;
alter table public.rab_arsip add constraint rab_arsip_aksi_check
  check (aksi in ('generate','cetak','salin','pdf'));

-- 3. Umum hanya boleh menambah baris GENERATE (wajib token + lokasi) ------
drop policy if exists "umum tambah arsip" on public.rab_arsip;
create policy "umum tambah arsip" on public.rab_arsip
  for insert to anon, authenticated
  with check (
    status = 'baru' and catatan is null
    and aksi = 'generate'
    and token is not null and lat is not null and lng is not null and akurasi is not null
    and dicetak = false and waktu_cetak is null
    and nama_pemohon is null and kode_verifikasi is null
  );

-- 4. Fungsi Izin Cetak: tandai Cetak = Ya, simpan nama, buat kode verifikasi
create or replace function public.rab_tandai_cetak(p_token uuid, p_nama text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id   bigint;
  v_kode text;
  v_nama text := btrim(coalesce(p_nama, ''));
begin
  if char_length(v_nama) < 3 or char_length(v_nama) > 100 then
    raise exception 'Nama pemohon minimal 3 karakter';
  end if;

  select id, kode_verifikasi into v_id, v_kode
  from public.rab_arsip
  where token = p_token and created_at > now() - interval '1 day'
  for update;

  if v_id is null then
    raise exception 'Data generate tidak ditemukan atau sudah kedaluwarsa, silakan Generate ulang';
  end if;

  if v_kode is not null then
    return v_kode;                       -- cetak ulang: kode tetap sama
  end if;

  loop
    v_kode := 'RAB-' || to_char(now() at time zone 'Asia/Makassar', 'YYMMDD') || '-'
              || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 5));
    exit when not exists (select 1 from public.rab_arsip where kode_verifikasi = v_kode);
  end loop;

  update public.rab_arsip
     set dicetak = true, waktu_cetak = now(), nama_pemohon = v_nama,
         kode_verifikasi = v_kode, aksi = 'cetak'
   where id = v_id;

  return v_kode;
end;
$$;

revoke all on function public.rab_tandai_cetak(uuid, text) from public;
grant execute on function public.rab_tandai_cetak(uuid, text) to anon, authenticated;

-- Selesai. Cek Table Editor > rab_arsip: token, lat, lng, akurasi, dicetak,
-- waktu_cetak, nama_pemohon, kode_verifikasi
