-- Chặn clock HLC sai (ADR-012, STATE "nợ kỹ thuật"):
-- 1. Clock sai định dạng ('<13 chữ số ms>:<4 chữ số>:<node>') bị từ chối: chuỗi rác như 'zzz' sẽ thắng mọi clock số khi so collate "C".
-- 2. Clock ở tương lai quá now() + 1 ngày (máy đặt sai năm) bị kẹp về giờ server, giữ counter + node.
--    Không kẹp thì bản sửa từ máy sai giờ luôn thắng LWW cho tới năm đó. Kết quả trả `clamped` để app báo lệch giờ.
-- Làm bằng lớp bọc: hàm cũ đổi tên, sync_push_core vẫn gọi app.apply_mutation (plpgsql tra tên lúc chạy).

alter function app.apply_mutation(uuid, text, jsonb) rename to apply_mutation_unchecked;

create function app.apply_mutation(p_uid uuid, p_device text, m jsonb) returns jsonb
language plpgsql set search_path = '' as $$
declare
  v_clock jsonb := m->'field_clock';
  v_max bigint := (extract(epoch from now() + interval '1 day') * 1000)::bigint;
  v_now text := lpad((extract(epoch from now()) * 1000)::bigint::text, 13, '0');
  v_out jsonb := '{}';
  v_clamped text[] := '{}';
  f text; v text;
  v_res jsonb;
begin
  if v_clock is not null and jsonb_typeof(v_clock) = 'object' then
    for f, v in select e.key, e.value #>> '{}' from jsonb_each(v_clock) e loop
      if v is null or v !~ '^[0-9]{13}:[0-9]{4}:[A-Za-z0-9._-]{1,64}$' then
        return app.result(m->>'table', jsonb_build_object('id', m->'id'), 'invalid', null, 'malformed_clock');
      end if;
      if left(v, 13)::bigint > v_max then
        v := v_now || substr(v, 14);
        v_clamped := v_clamped || f;
      end if;
      v_out := v_out || jsonb_build_object(f, v);
    end loop;
    m := jsonb_set(m, '{field_clock}', v_out);
  end if;

  v_res := app.apply_mutation_unchecked(p_uid, p_device, m);
  if array_length(v_clamped, 1) > 0 then
    v_res := v_res || jsonb_build_object('clamped', to_jsonb(v_clamped));
  end if;
  return v_res;
end $$;

revoke all on function app.apply_mutation(uuid, text, jsonb) from public;
revoke all on function app.apply_mutation_unchecked(uuid, text, jsonb) from public;
