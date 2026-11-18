-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 07: rating bintang (1-5) dan saran saat izin cetak
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-01 s.d. update-06 harus sudah dijalankan)
-- =====================================================================

alter table public.rab_arsip
  add column if not exists rating smallint check (rating between 1 and 5),
  add column if not exists saran  text check (char_length(saran) <= 300);

-- Fungsi lama (2 parameter) dihapus agar tidak bentrok dengan versi baru
drop function if exists public.rab_tandai_cetak(uuid, text);

create or replace function public.rab_tandai_cetak(
  p_token  uuid,
  p_nama   text,
  p_rating smallint default null,
  p_saran  text default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id     bigint;
  v_kode   text;
  v_rating smallint;
  v_nama   text := btrim(coalesce(p_nama, ''));
  v_saran  text := nullif(left(btrim(coalesce(p_saran, '')), 300), '');
begin
  if char_length(v_nama) < 3 or char_length(v_nama) > 100 then
    raise exception 'Nama pemohon minimal 3 karakter';
  end if;
  if p_rating is not null and (p_rating < 1 or p_rating > 5) then
    raise exception 'Rating harus 1 sampai 5';
  end if;

  select id, kode_verifikasi, rating into v_id, v_kode, v_rating
  from public.rab_arsip
  where token = p_token and created_at > now() - interval '1 day'
  for update;

  if v_id is null then
    raise exception 'Data generate tidak ditemukan atau sudah kedaluwarsa, silakan Generate ulang';
  end if;

  -- rating & saran hanya diisi sekali per baris
  if p_rating is not null and v_rating is null then
    update public.rab_arsip set rating = p_rating, saran = v_saran where id = v_id;
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

revoke all on function public.rab_tandai_cetak(uuid, text, smallint, text) from public;
grant execute on function public.rab_tandai_cetak(uuid, text, smallint, text) to anon, authenticated;

-- Selesai. Cek Table Editor > rab_arsip: kolom rating dan saran
