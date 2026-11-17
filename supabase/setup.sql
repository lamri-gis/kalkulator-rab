-- =====================================================================
-- Kalkulator RAB Desa by Lamri, S.P.
-- Kaur Perencanaan Desa Susuk Dalam, Kec. Sandaran, Kab. Kutai Timur
--
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- WAJIB: ganti EMAIL_ADMIN_KAMU@gmail.com di bagian 3 dengan email admin
-- =====================================================================

-- 1. TABEL ARSIP RAB ---------------------------------------------------
create table if not exists public.rab_arsip (
  id             bigint generated always as identity primary key,
  created_at     timestamptz not null default now(),
  aksi           text not null check (aksi in ('cetak','salin')),
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
  status         text not null default 'baru' check (status in ('baru','real','abaikan')),
  catatan        text check (char_length(catatan) <= 300)
);

create index if not exists rab_arsip_created_idx on public.rab_arsip (created_at desc);
create index if not exists rab_arsip_status_idx  on public.rab_arsip (status);

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

-- GANTI email di bawah ini dengan email akun admin di Supabase Auth
insert into public.rab_admin (email)
values ('EMAIL_ADMIN_KAMU@gmail.com')
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

-- Umum: hanya boleh MENAMBAH, status wajib 'baru', tanpa catatan
drop policy if exists "umum tambah arsip" on public.rab_arsip;
create policy "umum tambah arsip" on public.rab_arsip
  for insert to anon, authenticated
  with check (status = 'baru' and catatan is null);

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

-- 5. HAK AKSES TABEL ---------------------------------------------------
revoke all on public.rab_arsip, public.rab_kunjungan, public.rab_admin from anon, authenticated;
grant insert on public.rab_arsip, public.rab_kunjungan to anon, authenticated;
grant select, update, delete on public.rab_arsip to authenticated;
grant select on public.rab_kunjungan to authenticated;
grant execute on function public.is_rab_admin() to anon, authenticated;

-- Selesai. Cek di Table Editor: rab_arsip, rab_kunjungan, rab_admin
