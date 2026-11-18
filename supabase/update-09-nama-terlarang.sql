-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 09: nama pemohon yang mengandung "Lamri" tidak dapat digunakan
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-07 harus sudah dijalankan)
-- =====================================================================

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
  if v_nama ~* 'lamri' then
    raise exception 'Nama ini tidak dapat digunakan. Gunakan nama pemohon yang sebenarnya.';
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

-- Selesai.
