-- =====================================================================
-- Kalkulator RAB Desa (ACC-RAB) by Lamri, S.P.
-- UPDATE 14: Generate RAB Final dari Rincian RAB (tanpa GPS ulang)
-- Angka final dihitung ulang di database dengan rumus Mode Material,
-- lalu baris arsip yang sama diperbarui. Hanya sebelum dicetak.
-- Jalankan SEKALI di Supabase: SQL Editor > New query > tempel > Run
-- (update-13 harus sudah dijalankan)
-- =====================================================================

create or replace function public.rab_finalkan(
  p_token    uuid,
  p_material bigint,
  p_sewa     bigint,
  p_p_tukang numeric,
  p_panjang  numeric default null,
  p_lebar    numeric default null,
  p_tinggi   numeric default null,
  p_volume   numeric default null,
  p_satuan   text default null,
  p_ukuran   text default null,
  p_rincian  jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id     bigint;
  v_kode   text;
  v_mode   text;
  v_ps     bigint;
  v_total  bigint;
  v_tukang bigint;
  v_tpk    bigint;
  v_sisa   bigint;
  v_mat    bigint;
  v_pajak  bigint;
begin
  if p_material is null or p_sewa is null or p_material < 0 or p_sewa < 0
     or p_material > 100000000000 or p_sewa > 100000000000 then
    raise exception 'Nilai rincian tidak valid';
  end if;
  if p_material + p_sewa <= 0 then
    raise exception 'Rincian RAB masih kosong';
  end if;
  if p_p_tukang is null or p_p_tukang < 0 or p_p_tukang > 0.30 then
    raise exception 'Upah tenaga kerja maksimal 30 persen';
  end if;
  if p_rincian is not null and (jsonb_typeof(p_rincian) <> 'object' or octet_length(p_rincian::text) > 60000) then
    raise exception 'Rincian RAB tidak valid atau terlalu besar';
  end if;
  if p_ukuran is not null and char_length(p_ukuran) > 300 then
    raise exception 'Teks ukuran terlalu panjang';
  end if;

  select id, kode_verifikasi, mode into v_id, v_kode, v_mode
  from public.rab_arsip
  where token = p_token and created_at > now() - interval '1 day'
  for update;

  if v_id is null then
    raise exception 'Data generate tidak ditemukan atau sudah kedaluwarsa, silakan Generate ulang';
  end if;
  if v_mode <> 'material' then
    raise exception 'Rincian RAB hanya untuk Mode Material';
  end if;
  if v_kode is not null then
    raise exception 'RAB ini sudah dicetak. Generate ulang untuk membuat RAB baru.';
  end if;

  -- rumus Mode Material (sama dengan kalkulator): TPK 3%, pajak bahan 12,5%, pajak sewa 13%
  v_ps     := round(p_sewa * 0.13);
  v_total  := ceil((p_material * 1.125 + p_sewa + v_ps) / (1 - p_p_tukang - 0.03) - 0.0000001);
  v_tukang := floor(v_total * p_p_tukang + 0.0000001);
  v_tpk    := floor(v_total * 0.03 + 0.0000001);
  v_sisa   := v_total - v_tukang - v_tpk - p_sewa - v_ps;
  v_mat    := floor(v_sisa / 1.125 + 0.0000001);
  if v_mat >= p_material then v_mat := p_material; end if;
  v_pajak  := v_sisa - v_mat;

  update public.rab_arsip
     set nilai_input = p_material, material = v_mat, pajak = v_pajak, sewa = p_sewa, pajak_sewa = v_ps,
         tukang = v_tukang, tpk = v_tpk, total = v_total, p_tukang = p_p_tukang,
         panjang = coalesce(p_panjang, panjang), lebar = coalesce(p_lebar, lebar), tinggi = coalesce(p_tinggi, tinggi),
         volume = coalesce(p_volume, volume), satuan = coalesce(p_satuan, satuan), ukuran = coalesce(p_ukuran, ukuran),
         rincian = coalesce(p_rincian, rincian)
   where id = v_id;

  return jsonb_build_object('total', v_total, 'tukang', v_tukang, 'tpk', v_tpk, 'material', v_mat,
                            'pajak', v_pajak, 'sewa', p_sewa, 'pajak_sewa', v_ps);
end;
$$;

revoke all on function public.rab_finalkan(uuid, bigint, bigint, numeric, numeric, numeric, numeric, numeric, text, text, jsonb) from public;
grant execute on function public.rab_finalkan(uuid, bigint, bigint, numeric, numeric, numeric, numeric, numeric, text, text, jsonb) to anon, authenticated;

-- Selesai.
