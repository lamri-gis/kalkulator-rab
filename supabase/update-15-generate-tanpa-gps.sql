-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 15: Generate RAB baru di tab baru tanpa GPS
-- Lokasi disalin di server dari RAB sebelumnya (berlaku 1 hari sejak
-- lokasi GPS pertama diambil). Arsip baru = baris baru.
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-14 harus sudah dijalankan)
-- =====================================================================

alter table public.rab_arsip
  add column if not exists induk_token  uuid,
  add column if not exists waktu_lokasi timestamptz;

create or replace function public.rab_generate_turunan(p_parent uuid, p_data jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_p     public.rab_arsip%rowtype;
  v_d     public.rab_arsip%rowtype;
  v_waktu timestamptz;
  v_token uuid := gen_random_uuid();
begin
  if p_data is null or jsonb_typeof(p_data) <> 'object' or octet_length(p_data::text) > 20000 then
    raise exception 'Data RAB tidak valid';
  end if;

  select * into v_p from public.rab_arsip where token = p_parent;
  if v_p.id is null then
    raise exception 'RAB sebelumnya tidak ditemukan, silakan Generate biasa';
  end if;
  v_waktu := coalesce(v_p.waktu_lokasi, v_p.created_at);
  if v_waktu < now() - interval '1 day' or v_p.lat is null then
    raise exception 'Lokasi dari RAB sebelumnya sudah kedaluwarsa, silakan Generate biasa dengan lokasi';
  end if;

  v_d := jsonb_populate_record(null::public.rab_arsip, p_data);
  if v_d.mode is distinct from 'material' then
    raise exception 'RAB baru tanpa lokasi hanya untuk Mode Material';
  end if;

  insert into public.rab_arsip (
    aksi, mode, nama_kegiatan, panjang, lebar, tinggi, volume, satuan, bahan_utama, jenis_bangunan, ukuran,
    sifat_konstruksi, jenis_dana, rt, tahun, nilai_input, tukang, tpk, pajak, material, sewa, pajak_sewa, total,
    p_tukang, p_tpk, p_pajak, p_pajak_sewa,
    token, lat, lng, akurasi, percobaan, perangkat, os, browser, model_hp, induk_token, waktu_lokasi
  ) values (
    'generate', 'material', v_d.nama_kegiatan, v_d.panjang, v_d.lebar, v_d.tinggi, v_d.volume, v_d.satuan, v_d.bahan_utama, v_d.jenis_bangunan, v_d.ukuran,
    v_d.sifat_konstruksi, v_d.jenis_dana, v_d.rt, v_d.tahun, v_d.nilai_input, v_d.tukang, v_d.tpk, v_d.pajak, v_d.material, v_d.sewa, v_d.pajak_sewa, v_d.total,
    v_d.p_tukang, v_d.p_tpk, v_d.p_pajak, v_d.p_pajak_sewa,
    v_token, v_p.lat, v_p.lng, v_p.akurasi, v_p.percobaan, v_p.perangkat, v_p.os, v_p.browser, v_p.model_hp, p_parent, v_waktu
  );
  return v_token;
end;
$$;

revoke all on function public.rab_generate_turunan(uuid, jsonb) from public;
grant execute on function public.rab_generate_turunan(uuid, jsonb) to anon, authenticated;

-- Selesai.
