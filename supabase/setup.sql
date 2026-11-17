-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- Kaur Perencanaan Desa Susuk Dalam, Kec. Sandaran, Kab. Kutai Timur
--
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- Email admin sudah diisi di bagian 3: lamri96sp@gmail.com
-- =====================================================================

-- 1. TABEL ARSIP RAB ---------------------------------------------------
create table if not exists public.rab_arsip (
  id             bigint generated always as identity primary key,
  created_at     timestamptz not null default now(),
  aksi           text not null check (aksi in ('generate','cetak','salin','pdf')),
  mode           text not null check (mode in ('material','pagu')),
  nama_kegiatan  text check (char_length(nama_kegiatan) <= 200),
  panjang        numeric(14,3) check (panjang > 0 and panjang < 1000000000),
  lebar          numeric(14,3) check (lebar > 0 and lebar < 1000000000),
  tinggi         numeric(14,3) check (tinggi > 0 and tinggi < 1000000000),
  volume         numeric(14,2) check (volume >= 0 and volume < 1000000000000),
  satuan         text check (char_length(satuan) <= 20),
  bahan_utama    text check (char_length(bahan_utama) <= 60),
  sifat_konstruksi text check (sifat_konstruksi in ('Permanen','Semi Permanen','Sementara/Darurat')),
  jenis_dana     text check (char_length(jenis_dana) <= 60),
  rt             text check (char_length(rt) <= 10),
  tahun          int  check (tahun between 2000 and 2100),
  nilai_input    bigint not null check (nilai_input between 0 and 100000000000),
  tukang         bigint check (tukang >= 0),
  tpk            bigint check (tpk >= 0),
  pajak          bigint check (pajak >= 0),
  material       bigint check (material >= 0),
  sewa           bigint check (sewa >= 0),
  pajak_sewa     bigint check (pajak_sewa >= 0),
  total          bigint check (total >= 0),
  p_tukang       numeric(6,4) check (p_tukang between 0 and 1),
  -- upah tenaga kerja maksimal 30%
  constraint rab_arsip_p_tukang_maks check (p_tukang is null or p_tukang <= 0.30),
  p_tpk          numeric(6,4) check (p_tpk between 0 and 1),
  p_pajak        numeric(6,4) check (p_pajak between 0 and 1),
  p_pajak_sewa   numeric(6,4) check (p_pajak_sewa between 0 and 1),
  token          uuid unique,
  lat            numeric(9,6) check (lat between -90 and 90),
  lng            numeric(9,6) check (lng between -180 and 180),
  akurasi        numeric(10,1) check (akurasi >= 0 and akurasi < 100000000),
  dicetak        boolean not null default false,
  waktu_cetak    timestamptz,
  nama_pemohon   text check (char_length(nama_pemohon) between 3 and 100),
  kode_verifikasi text unique,
  status         text not null default 'baru' check (status in ('baru','real','abaikan')),
  catatan        text check (char_length(catatan) <= 300)
);

create index if not exists rab_arsip_created_idx on public.rab_arsip (created_at desc);
create index if not exists rab_arsip_status_idx  on public.rab_arsip (status);
create index if not exists rab_arsip_dicetak_idx on public.rab_arsip (dicetak);

-- 2. TABEL KUNJUNGAN ---------------------------------------------------
create table if not exists public.rab_kunjungan (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  path        text check (char_length(path) <= 100),
  perangkat   text check (perangkat in ('hp','laptop')),
  sumber      text check (char_length(sumber) <= 120)
);

create index if not exists rab_kunjungan_created_idx on public.rab_kunjungan (created_at desc);

-- 3. DAFTAR ADMIN ------------------------------------------------------
create table if not exists public.rab_admin (
  email text primary key
);

-- Email akun admin di Supabase Auth
insert into public.rab_admin (email)
values ('lamri96sp@gmail.com')
on conflict do nothing;

create or replace function public.is_rab_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.rab_admin
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- 4. KEAMANAN (RLS) ----------------------------------------------------
alter table public.rab_arsip     enable row level security;
alter table public.rab_kunjungan enable row level security;
alter table public.rab_admin     enable row level security;
-- rab_admin sengaja tanpa policy: tidak bisa dibaca siapa pun lewat API

-- Umum: hanya boleh MENAMBAH baris GENERATE (wajib token + lokasi)
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

drop policy if exists "umum tambah kunjungan" on public.rab_kunjungan;
create policy "umum tambah kunjungan" on public.rab_kunjungan
  for insert to anon, authenticated
  with check (true);

-- Admin: baca, ubah status, hapus
drop policy if exists "admin baca arsip" on public.rab_arsip;
create policy "admin baca arsip" on public.rab_arsip
  for select to authenticated using (public.is_rab_admin());

drop policy if exists "admin ubah arsip" on public.rab_arsip;
create policy "admin ubah arsip" on public.rab_arsip
  for update to authenticated
  using (public.is_rab_admin()) with check (public.is_rab_admin());

drop policy if exists "admin hapus arsip" on public.rab_arsip;
create policy "admin hapus arsip" on public.rab_arsip
  for delete to authenticated using (public.is_rab_admin());

drop policy if exists "admin baca kunjungan" on public.rab_kunjungan;
create policy "admin baca kunjungan" on public.rab_kunjungan
  for select to authenticated using (public.is_rab_admin());

-- 4b. Fungsi Izin Cetak: tandai Cetak = Ya, simpan nama, buat kode verifikasi
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

-- 5. HAK AKSES TABEL ---------------------------------------------------
revoke all on public.rab_arsip, public.rab_kunjungan, public.rab_admin from anon, authenticated;
grant insert on public.rab_arsip, public.rab_kunjungan to anon, authenticated;
grant select, update, delete on public.rab_arsip to authenticated;
grant select on public.rab_kunjungan to authenticated;
grant execute on function public.is_rab_admin() to anon, authenticated;

-- Selesai. Cek di Table Editor: rab_arsip, rab_kunjungan, rab_admin
